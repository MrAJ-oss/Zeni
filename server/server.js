import express from "express";
import fetch from "node-fetch";
import cors from "cors";
import dotenv from "dotenv";
import { getUser, saveUser } from "./userStore.js";
import { getDevices, saveDevices } from "./deviceStore.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const GROQ_API_KEY = process.env.GROQ_API_KEY;

let currentCommand = null;

// ROOT
app.get("/", (req, res) => {
  res.send("Zeni Running 🚀");
});

// FIRST SETUP
app.post("/api/setup", (req, res) => {
  const { name, password, deviceId } = req.body;

  if (getUser()) {
    return res.json({ success: false });
  }

  const user = {
    name,
    password,
    devices: [deviceId]
  };

  saveUser(user);
  res.json({ success: true });
});

// LOGIN
app.post("/api/login", (req, res) => {
  const { password, deviceId } = req.body;

  const user = getUser();
  if (!user) return res.json({ success: false });

  if (password !== user.password) {
    return res.json({ success: false });
  }

  if (!user.devices.includes(deviceId)) {
    user.devices.push(deviceId);
    saveUser(user);
  }

  res.json({ success: true });
});

// DEVICE PING
app.post("/api/ping", (req, res) => {
  const { deviceId, name, type } = req.body;

  let devices = getDevices();
  const now = Date.now();

  let device = devices.find(d => d.id === deviceId);

  if (!device) {
    device = { id: deviceId, name, type, lastSeen: now };
    devices.push(device);
  } else {
    device.lastSeen = now;
  }

  saveDevices(devices);
  res.json({ ok: true });
});

// CHECK ONLINE
function isDeviceOnline(deviceId) {
  const devices = getDevices();
  const device = devices.find(d => d.id === deviceId);

  if (!device) return false;

  return (Date.now() - device.lastSeen) < 5000;
}

// VOICE
app.post("/api/voice", async (req, res) => {
  const { text, deviceId } = req.body;

  const user = getUser();
  if (!user || !user.devices.includes(deviceId)) {
    return res.json({ reply: "Access denied" });
  }

  let targetDevice = user.devices[0];

  if (text.toLowerCase().includes("laptop")) {
    targetDevice = user.devices.find(d => d !== deviceId) || targetDevice;
  }

  if (!isDeviceOnline(targetDevice)) {
    return res.json({ reply: "Device is not reachable right now" });
  }

  if (text.toLowerCase().includes("chrome")) currentCommand = "chrome";
  if (text.toLowerCase().includes("shutdown")) currentCommand = "shutdown";

  try {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: "llama3-8b-8192",
        messages: [{ role: "user", content: text }]
      })
    });

    const data = await response.json();
    const reply = data.choices[0].message.content;

    res.json({ reply });

  } catch {
    res.json({ reply: "AI error" });
  }
});

// COMMAND
app.get("/api/command", (req, res) => {
  const cmd = currentCommand;
  currentCommand = null;
  res.json({ command: cmd });
});

app.listen(PORT, () => {
  console.log("🚀 Zeni running on port", PORT);
});