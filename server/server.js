import express from "express";
import fetch from "node-fetch";
import dotenv from "dotenv";

import {
  registerDevice,
  approveDevice,
  isApproved,
  getPendingDevices,
  renameDevice,
  renameByName,
  getDevices
} from "./Device.js";

import { addLog, getLogs, clearLogs } from "./logs.js";

dotenv.config();

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const API_KEY = process.env.GROQ_API_KEY;

// 🔥 PC COMMAND STORAGE
let lastCommand = null;

// ================= ROOT =================
app.get("/", (req, res) => {
  res.send("Zeni Running 🚀");
});

// ================= DEVICE =================
app.post("/api/register", (req, res) => {
  const { id, name } = req.body;
  res.json(registerDevice(id, name));
});

app.post("/api/approve", (req, res) => {
  const { id } = req.body;
  res.json(approveDevice(id));
});

app.get("/api/pending", (req, res) => {
  res.json(getPendingDevices());
});

// ================= LOGS =================
app.get("/api/logs", (req, res) => {
  res.json(getLogs());
});

app.delete("/api/logs", (req, res) => {
  clearLogs();
  res.json({ success: true });
});

// ================= PC CLIENT =================
app.get("/api/command", (req, res) => {
  const cmd = lastCommand;
  lastCommand = null;
  res.json({ command: cmd });
});

// ================= MAIN =================
app.post("/api/voice", async (req, res) => {
  const { text, deviceId } = req.body;
  const lower = text.toLowerCase();

  // 🔐 BLOCK UNAUTHORIZED
  if (!isApproved(deviceId)) {
    addLog("BLOCKED", deviceId, text);
    return res.json({
      reply: "You are not my user. Access denied."
    });
  }

  // ================= DEVICE COMMANDS =================

  if (lower.startsWith("rename this device to")) {
    const newName = text.replace(/rename this device to/i, "").trim();
    renameDevice(deviceId, newName);

    return res.json({
      reply: `This device is now named ${newName}`
    });
  }

  if (lower.startsWith("rename device")) {
    const parts = text.split("to");

    if (parts.length === 2) {
      const oldName = parts[0].replace(/rename device/i, "").trim();
      const newName = parts[1].trim();

      renameByName(oldName, newName);

      return res.json({
        reply: `Renamed ${oldName} to ${newName}`
      });
    }
  }

  if (lower.includes("my devices")) {
    return res.json({
      reply: JSON.stringify(getDevices())
    });
  }

  // ================= PC COMMANDS =================

  if (lower.includes("shutdown pc")) {
    lastCommand = "shutdown";
    return res.json({ reply: "Shutting down your PC" });
  }

  if (lower.includes("restart pc")) {
    lastCommand = "restart";
    return res.json({ reply: "Restarting your PC" });
  }

  if (lower.includes("open chrome on pc")) {
    lastCommand = "chrome";
    return res.json({ reply: "Opening Chrome on your PC" });
  }

  if (lower.includes("open notepad")) {
    lastCommand = "notepad";
    return res.json({ reply: "Opening Notepad" });
  }

  if (lower.includes("open files")) {
    lastCommand = "explorer";
    return res.json({ reply: "Opening File Explorer" });
  }

  if (lower.includes("youtube on pc")) {
    lastCommand = "url:https://youtube.com";
    return res.json({ reply: "Opening YouTube on your PC" });
  }

  // ================= LOG COMMANDS =================

  if (lower.includes("show logs")) {
    return res.json({ reply: JSON.stringify(getLogs()) });
  }

  if (lower.includes("delete logs")) {
    clearLogs();
    return res.json({ reply: "Logs cleared" });
  }

  if (lower.includes("pending devices")) {
    return res.json({
      reply: JSON.stringify(getPendingDevices())
    });
  }

  // ================= FAST AI =================

  try {
    const response = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${API_KEY}`
        },
        body: JSON.stringify({
          model: "llama3-8b-8192",
          messages: [
            {
              role: "user",
              content: `Reply short, smart, friendly: ${text}`
            }
          ],
          max_tokens: 80,
          temperature: 0.7
        })
      }
    );

    const data = await response.json();
    const reply = data.choices[0].message.content;

    res.json({ reply });

  } catch (err) {
    res.json({
      reply: "Server error, try again"
    });
  }
});

// ================= START =================
app.listen(PORT, () => {
  console.log("Zeni running on port " + PORT);
});