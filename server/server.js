import express from "express";
import fs from "fs";
import cors from "cors";
import fetch from "node-fetch";
import dotenv from "dotenv";
import FormData from "form-data";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const FILE = "./user.json";
const GROQ_KEY = process.env.GROQ_API_KEY;

// ===== DEFAULT USER =====
const DEFAULT_USER = {
  name: "Anuj",
  password: "iamfuturebillionare",
  devices: [
    { id: "mobile_001", name: "My Phone", approved: true }
  ],
  pendingDevices: [],
  logs: [],
  memory: []
};

// ===== STORAGE =====
function getUser() {
  if (!fs.existsSync(FILE)) {
    fs.writeFileSync(FILE, JSON.stringify(DEFAULT_USER, null, 2));
    return DEFAULT_USER;
  }
  return JSON.parse(fs.readFileSync(FILE));
}

function saveUser(user) {
  fs.writeFileSync(FILE, JSON.stringify(user, null, 2));
}

// ===== AI =====
async function zeniBrain(text, user) {
  try {
    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama3-70b-8192",
        messages: [
          { role: "system", content: "You are Zeni. Be human, emotional, curious." },
          { role: "user", content: text }
        ]
      })
    });

    const data = await res.json();
    return data.choices?.[0]?.message?.content || "Hmm?";
  } catch {
    return "Something went wrong.";
  }
}

// ===== LOGIN =====
app.post("/login", (req, res) => {
  const { password, deviceId } = req.body;
  const user = getUser();

  if (password !== user.password) {
    user.logs.push({ type: "wrong_password", deviceId, time: new Date() });
    saveUser(user);
    return res.json({ status: "denied" });
  }

  const approved = user.devices.find(d => d.id === deviceId);

  if (approved) return res.json({ status: "ok" });

  if (!user.pendingDevices.includes(deviceId)) {
    user.pendingDevices.push(deviceId);
    saveUser(user);
  }

  return res.json({ status: "pending" });
});

// ===== VOICE AUTH (PYTHON CALL) =====
async function verifyVoice(audioBuffer) {
  const form = new FormData();
  form.append("audio", audioBuffer, { filename: "voice.wav" });

  try {
    const res = await fetch("http://localhost:5000/verify", {
      method: "POST",
      body: form,
      headers: form.getHeaders()
    });

    const data = await res.json();
    return data.status === "allowed";
  } catch {
    return false;
  }
}

// ===== VOICE ROUTE =====
app.post("/voice", async (req, res) => {
  const { text, deviceId } = req.body;
  const user = getUser();

  const approved = user.devices.find(d => d.id === deviceId);

  if (!approved) {
    user.logs.push({ type: "unauthorized_device", deviceId, time: new Date() });
    saveUser(user);
    return res.json({ reply: "Access denied" });
  }

  // 🔥 DEVICE APPROVAL
  if (text.toLowerCase().includes("approve device")) {
    const id = user.pendingDevices[0];

    if (id) {
      user.devices.push({ id, name: "New Device", approved: true });
      user.pendingDevices = user.pendingDevices.filter(d => d !== id);
      saveUser(user);
      return res.json({ reply: "Device approved" });
    } else {
      return res.json({ reply: "No pending devices" });
    }
  }

  // 🔥 RENAME DEVICE
  if (text.toLowerCase().includes("rename this device")) {
    const device = user.devices.find(d => d.id === deviceId);
    const name = text.split("to")[1]?.trim();

    if (device && name) {
      device.name = name;
      saveUser(user);
      return res.json({ reply: `Now this is ${name}` });
    }
  }

  const reply = await zeniBrain(text, user);

  user.memory.push({ user: text, zeni: reply });
  saveUser(user);

  res.json({ reply });
});

app.listen(3000, () => console.log("🚀 Zeni backend running"));