import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import Groq from "groq-sdk";
import fetch from "node-fetch";
import FormData from "form-data";

dotenv.config();

const app = express();
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const VOICE_AUTH_URL = process.env.VOICE_AUTH_URL || "http://localhost:5001";

app.use(cors());
app.use(express.json({ limit: "10mb" }));

const PORT = process.env.PORT || 5000;

// ── Storage ──────────────────────────────────────────
let approvedDevices = [];
let logs = [];
const deviceHistories = {}; // per-device chat history

// ── Root ─────────────────────────────────────────────
app.get("/", (req, res) => {
  res.send("Zeni server running 🚀");
});

// ── Login ─────────────────────────────────────────────
app.post("/login", (req, res) => {
  try {
    const { password, deviceId } = req.body;
    const MAIN_PASSWORD = "iamfuturebillionare";

    if (!password) {
      return res.status(400).json({ success: false, message: "Password required" });
    }

    if (password !== MAIN_PASSWORD) {
      logs.push({ type: "FAILED_LOGIN", deviceId, time: new Date() });
      return res.status(401).json({ success: false, message: "Wrong password" });
    }

    if (approvedDevices.length === 0) {
      approvedDevices.push(deviceId);
      logs.push({ type: "FIRST_DEVICE_APPROVED", deviceId, time: new Date() });
      return res.json({ success: true, approved: true, firstDevice: true, message: "First device auto approved" });
    }

    if (approvedDevices.includes(deviceId)) {
      logs.push({ type: "KNOWN_DEVICE_LOGIN", deviceId, time: new Date() });
      return res.json({ success: true, approved: true, message: "Welcome back" });
    }

    logs.push({ type: "NEW_DEVICE_REQUEST", deviceId, time: new Date() });
    return res.json({ success: true, approved: false, message: "Device approval required" });

  } catch (e) {
    console.error("Login error:", e);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

// ── Approve Device ────────────────────────────────────
app.post("/approve-device", (req, res) => {
  try {
    const { deviceId } = req.body;
    if (!approvedDevices.includes(deviceId)) {
      approvedDevices.push(deviceId);
    }
    logs.push({ type: "DEVICE_APPROVED", deviceId, time: new Date() });
    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ success: false });
  }
});

// ── Chat ──────────────────────────────────────────────
app.post("/chat", async (req, res) => {
  try {
    const { message, deviceId } = req.body;

    if (!message) {
      return res.status(400).json({ reply: "No message provided" });
    }

    // Get or create history for this device
    if (!deviceHistories[deviceId]) {
      deviceHistories[deviceId] = [];
    }
    const history = deviceHistories[deviceId];

    const messages = [
      {
        role: "system",
        content: `You are Zeni, a personal AI assistant built exclusively for your owner Anuj.
You are loyal, emotionally aware, sharp, and speak like a close trusted companion — not a generic chatbot.
You remember the conversation context and refer back to it naturally.
Keep responses concise and conversational — no long essays unless asked.
Never say you are ChatGPT, Claude, or any other AI. You are Zeni and only Zeni.
If the user seems sad, be warm and supportive. If happy, match their energy. If angry, be calm and steady.`
      },
      ...history,
      { role: "user", content: message }
    ];

    const completion = await groq.chat.completions.create({
      model: "llama3-8b-8192",
      messages,
      max_tokens: 300,
      temperature: 0.85,
    });

    const reply = completion.choices[0].message.content.trim();

    // Save to server-side history
    history.push({ role: "user", content: message });
    history.push({ role: "assistant", content: reply });

    // Keep only last 50 messages
    if (history.length > 50) {
      deviceHistories[deviceId] = history.slice(-50);
    }

    logs.push({ type: "CHAT", deviceId, message, reply, time: new Date() });

    return res.json({ reply });

  } catch (e) {
    console.error("Chat error:", e);
    return res.status(500).json({ reply: "I had a problem processing that. Try again." });
  }
});

// ── Get History ───────────────────────────────────────
app.get("/history/:deviceId", (req, res) => {
  const history = deviceHistories[req.params.deviceId] || [];
  return res.json({ history });
});

// ── Clear History ─────────────────────────────────────
app.delete("/history/:deviceId", (req, res) => {
  deviceHistories[req.params.deviceId] = [];
  return res.json({ success: true });
});

// ── Voice Enroll Proxy ────────────────────────────────
app.post("/voice-enroll", async (req, res) => {
  try {
    const { audioBase64, deviceId } = req.body;
    if (!audioBase64) return res.status(400).json({ status: "error", message: "No audio" });

    const audioBuffer = Buffer.from(audioBase64, "base64");
    const form = new FormData();
    form.append("audio", audioBuffer, { filename: "voice.wav", contentType: "audio/wav" });
    form.append("deviceId", deviceId || "default");

    const response = await fetch(`${VOICE_AUTH_URL}/enroll`, {
      method: "POST",
      body: form,
      headers: form.getHeaders(),
    });

    const data = await response.json();
    return res.json(data);

  } catch (e) {
    console.error("Voice enroll error:", e);
    return res.status(500).json({ status: "error", message: "Voice enroll failed" });
  }
});

// ── Voice Verify Proxy ────────────────────────────────
app.post("/voice-verify", async (req, res) => {
  try {
    const { audioBase64, deviceId } = req.body;
    if (!audioBase64) return res.status(400).json({ status: "error", message: "No audio" });

    const audioBuffer = Buffer.from(audioBase64, "base64");
    const form = new FormData();
    form.append("audio", audioBuffer, { filename: "voice.wav", contentType: "audio/wav" });
    form.append("deviceId", deviceId || "default");

    const response = await fetch(`${VOICE_AUTH_URL}/verify`, {
      method: "POST",
      body: form,
      headers: form.getHeaders(),
    });

    const data = await response.json();
    return res.json(data);

  } catch (e) {
    console.error("Voice verify error:", e);
    // If voice auth server down — allow access
    return res.json({ status: "allowed", message: "Voice auth unavailable" });
  }
});

// ── Logs ──────────────────────────────────────────────
app.get("/logs", (req, res) => {
  return res.json(logs);
});

// ── Devices ───────────────────────────────────────────
app.get("/devices", (req, res) => {
  return res.json(approvedDevices);
});

// ── Start ─────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`Zeni server running on port ${PORT}`);
});