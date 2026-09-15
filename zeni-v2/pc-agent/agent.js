import WebSocket from 'ws';
import os from 'os';
import path from 'path';
import fs from 'fs';
import { execFile, spawn, execFileSync } from 'child_process';
import clipboard from 'clipboardy';
import { mouse, keyboard, screen, Point, Button, Key } from '@nut-tree-fork/nut-js';
import dotenv from 'dotenv';
dotenv.config();

const SERVER_URL = process.env.ZENI_SERVER_WS_URL;
const DEVICE_ID = process.env.ZENI_DEVICE_ID;
const SECRET = process.env.ZENI_AGENT_SECRET;
const PROJECT_ROOT = process.env.ZENI_PROJECT_ROOT ? path.resolve(process.env.ZENI_PROJECT_ROOT) : null;
const SANDBOX_ROOT = process.env.ZENI_SANDBOX_ROOT ? path.resolve(process.env.ZENI_SANDBOX_ROOT) : null;
const SANDBOX_DEFAULT_PORT = 3001;

if (!SERVER_URL || !DEVICE_ID || !SECRET) {
  console.error('Missing ZENI_SERVER_WS_URL, ZENI_DEVICE_ID or ZENI_AGENT_SECRET');
  process.exit(1);
}

function resolveWithinRoot(root, relativePath, label) {
  if (!root) throw new Error(`${label} not configured on this agent`);
  const resolved = path.resolve(root, relativePath || '.');
  if (!resolved.startsWith(root)) throw new Error('path escapes allowed root, rejected');
  return resolved;
}

function resolveInProjectRoot(relativePath) {
  return resolveWithinRoot(PROJECT_ROOT, relativePath, 'ZENI_PROJECT_ROOT');
}

function sandboxDir(sandboxName) {
  if (!SANDBOX_ROOT) throw new Error('ZENI_SANDBOX_ROOT not configured on this agent');
  if (!sandboxName || /[^a-zA-Z0-9_-]/.test(sandboxName)) throw new Error('invalid sandbox name');
  return path.join(SANDBOX_ROOT, sandboxName);
}

function resolveInSandbox(sandboxName, relativePath) {
  return resolveWithinRoot(sandboxDir(sandboxName), relativePath, 'sandbox');
}

function copyRecursive(src, dest) {
  const SKIP = new Set(['node_modules', 'data', '.git']);
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    if (SKIP.has(entry.name)) continue;
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) copyRecursive(srcPath, destPath);
    else fs.copyFileSync(srcPath, destPath);
  }
}

// Tracks at most one running sandbox server at a time in this v1 — running
// several simultaneously would need per-sandbox port allocation this doesn't
// do yet.
let runningSandbox = null;

// Screen/mouse/keyboard control is gated behind an explicit, time-boxed
// session — nothing here fires from a bare tool call. Approval happens once,
// at session start; everything inside the window is real-time with zero
// per-action friction, same as a supervised screen-share.
const MAX_SESSION_MINUTES = 15;
let controlSession = null; // { expiresAt }

function requireActiveSession() {
  if (!controlSession || Date.now() > controlSession.expiresAt) {
    controlSession = null;
    throw new Error('No active control session — start one first (requires approval)');
  }
}

const ALLOWED_COMMANDS = {
  status: async () => ({
    platform: os.platform(),
    hostname: os.hostname(),
    uptime: os.uptime(),
    freeMemMB: Math.round(os.freemem() / 1024 / 1024),
  }),

  open_app: async (args) => {
    return new Promise((resolve, reject) => {
      const appName = args[0];
      if (!appName || /[;&|`$]/.test(appName)) return reject(new Error('invalid app name'));
      const opener = os.platform() === 'win32' ? 'start' : os.platform() === 'darwin' ? 'open' : 'xdg-open';
      execFile(opener, [appName], { shell: os.platform() === 'win32' }, (err) => {
        if (err) reject(err); else resolve({ opened: appName });
      });
    });
  },

  list_dir: async (args) => {
    const target = resolveInProjectRoot(args[0] || '.');
    const entries = fs.readdirSync(target, { withFileTypes: true });
    return { path: target, entries: entries.map(e => ({ name: e.name, isDir: e.isDirectory() })) };
  },

  read_file: async (args) => {
    const target = resolveInProjectRoot(args[0]);
    const content = fs.readFileSync(target, 'utf-8');
    return { path: target, content };
  },

  write_file: async (args) => {
    const target = resolveInProjectRoot(args[0]);
    const content = args[1] ?? '';
    fs.writeFileSync(target, content, 'utf-8');
    return { path: target, bytesWritten: Buffer.byteLength(content) };
  },

  clipboard_read: async () => ({ content: await clipboard.read() }),

  clipboard_write: async (args) => {
    await clipboard.write(args[0] ?? '');
    return { written: true };
  },

  lock_screen: async () => {
    return new Promise((resolve, reject) => {
      let cmd, cmdArgs;
      if (os.platform() === 'win32') { cmd = 'rundll32.exe'; cmdArgs = ['user32.dll,LockWorkStation']; }
      else if (os.platform() === 'darwin') { cmd = 'pmset'; cmdArgs = ['displaysleepnow']; }
      else { cmd = 'xdg-screensaver'; cmdArgs = ['lock']; }
      execFile(cmd, cmdArgs, (err) => { if (err) reject(err); else resolve({ locked: true }); });
    });
  },

  // Sandbox commands operate on an isolated copy under ZENI_SANDBOX_ROOT.
  // Nothing here can touch PROJECT_ROOT except promote_file, which is a
  // deliberate, explicit, single-file copy — never a blanket merge.
  sandbox_create: async (args) => {
    const [sandboxName] = args;
    const dest = sandboxDir(sandboxName);
    if (fs.existsSync(dest)) throw new Error(`sandbox "${sandboxName}" already exists`);
    copyRecursive(PROJECT_ROOT, dest);
    return { sandbox: sandboxName, path: dest };
  },

  sandbox_list_dir: async (args) => {
    const [sandboxName, relativePath] = args;
    const target = resolveInSandbox(sandboxName, relativePath || '.');
    const entries = fs.readdirSync(target, { withFileTypes: true });
    return { path: target, entries: entries.map(e => ({ name: e.name, isDir: e.isDirectory() })) };
  },

  sandbox_read_file: async (args) => {
    const [sandboxName, relativePath] = args;
    const target = resolveInSandbox(sandboxName, relativePath);
    return { path: target, content: fs.readFileSync(target, 'utf-8') };
  },

  sandbox_write_file: async (args) => {
    const [sandboxName, relativePath, content] = args;
    const target = resolveInSandbox(sandboxName, relativePath);
    fs.writeFileSync(target, content ?? '', 'utf-8');
    return { path: target, bytesWritten: Buffer.byteLength(content ?? '') };
  },

  sandbox_run: async (args) => {
    const [sandboxName, portArg] = args;
    const dir = sandboxDir(sandboxName);
    if (!fs.existsSync(dir)) throw new Error(`sandbox "${sandboxName}" does not exist — create it first`);
    if (runningSandbox) throw new Error(`sandbox "${runningSandbox.name}" is already running — stop it first (this agent runs one at a time)`);

    if (!fs.existsSync(path.join(dir, 'node_modules'))) {
      execFileSync('npm', ['install', '--no-audit', '--no-fund'], { cwd: dir, stdio: 'ignore' });
    }

    const port = portArg || SANDBOX_DEFAULT_PORT;
    const child = spawn('node', ['index.js'], {
      cwd: dir,
      env: { ...process.env, PORT: String(port) },
      stdio: 'ignore',
    });
    runningSandbox = { name: sandboxName, port, pid: child.pid, process: child };
    child.on('exit', () => { if (runningSandbox?.pid === child.pid) runningSandbox = null; });

    return { sandbox: sandboxName, url: `http://localhost:${port}`, pid: child.pid };
  },

  sandbox_stop: async () => {
    if (!runningSandbox) return { stopped: false, reason: 'nothing running' };
    runningSandbox.process.kill();
    const name = runningSandbox.name;
    runningSandbox = null;
    return { stopped: true, sandbox: name };
  },

  promote_file: async (args) => {
    const [sandboxName, relativePath] = args;
    const sandboxPath = resolveInSandbox(sandboxName, relativePath);
    const mainPath = resolveInProjectRoot(relativePath);
    const content = fs.readFileSync(sandboxPath, 'utf-8');
    fs.writeFileSync(mainPath, content, 'utf-8');
    return { promoted: relativePath, from: sandboxPath, to: mainPath };
  },

  // Screen/input control — see requireActiveSession above for the safety model.
  start_control_session: async (args) => {
    const requestedMinutes = Math.min(Number(args[0]) || 5, MAX_SESSION_MINUTES);
    controlSession = { expiresAt: Date.now() + requestedMinutes * 60000 };
    return { started: true, expiresInMinutes: requestedMinutes };
  },

  stop_control_session: async () => {
    controlSession = null;
    return { stopped: true };
  },

  screen_capture: async () => {
    const fileName = `zeni-capture-${Date.now()}`;
    const savedPath = await screen.capture(fileName);
    const buffer = fs.readFileSync(savedPath);
    fs.unlinkSync(savedPath);
    return { image: buffer.toString('base64'), format: 'png' };
  },

  mouse_move: async (args) => {
    requireActiveSession();
    const [x, y] = args;
    await mouse.setPosition(new Point(Number(x), Number(y)));
    return { movedTo: { x: Number(x), y: Number(y) } };
  },

  mouse_click: async (args) => {
    requireActiveSession();
    const buttonArg = (args[0] || 'left').toUpperCase();
    const button = Button[buttonArg] ?? Button.LEFT;
    await mouse.click(button);
    return { clicked: buttonArg };
  },

  type_text: async (args) => {
    requireActiveSession();
    const text = args[0] || '';
    await keyboard.type(text);
    return { typed: text.length + ' chars' };
  },

  key_press: async (args) => {
    requireActiveSession();
    const keyName = args[0];
    const key = Key[keyName];
    if (key === undefined) throw new Error(`unknown key "${keyName}"`);
    await keyboard.pressKey(key);
    await keyboard.releaseKey(key);
    return { pressed: keyName };
  },
};

function connect() {
  const ws = new WebSocket(`${SERVER_URL}?deviceId=${DEVICE_ID}&secret=${SECRET}`);

  ws.on('open', () => console.log(`connected as ${DEVICE_ID}`));

  ws.on('message', async (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch { return; }

    const handler = ALLOWED_COMMANDS[msg.command];
    if (!handler) {
      ws.send(JSON.stringify({ requestId: msg.requestId, ok: false, status: 'COMMAND_NOT_WHITELISTED' }));
      return;
    }

    try {
      const result = await handler(msg.args || []);
      ws.send(JSON.stringify({ requestId: msg.requestId, ok: true, result }));
    } catch (err) {
      ws.send(JSON.stringify({ requestId: msg.requestId, ok: false, error: err.message }));
    }
  });

  ws.on('close', () => {
    console.log('disconnected, retrying in 5s');
    setTimeout(connect, 5000);
  });

  ws.on('error', (err) => console.error('socket error', err.message));
}

connect();
