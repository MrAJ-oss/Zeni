import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;

// =========================
// MEMORY
// =========================

let approvedDevices = [];
let logs = [];

// =========================
// ROOT ROUTE
// =========================

app.get("/", (req, res) => {
  res.send("Zeni server running 🚀");
});

// =========================
// LOGIN SYSTEM
// =========================

app.post("/login", (req, res) => {
  try {
    const { password, deviceId } = req.body;

    // 🔐 CHANGE THIS PASSWORD
    const MAIN_PASSWORD = "iamfuturebillionare";

    if (!password) {
      return res.status(400).json({
        success: false,
        message: "Password required"
      });
    }

    if (password !== MAIN_PASSWORD) {
      logs.push({
        type: "FAILED_LOGIN",
        deviceId,
        time: new Date()
      });

      return res.status(401).json({
        success: false,
        message: "Wrong password"
      });
    }

    // ✅ FIRST DEVICE AUTO APPROVED
    if (approvedDevices.length === 0) {
      approvedDevices.push(deviceId);

      logs.push({
        type: "FIRST_DEVICE_APPROVED",
        deviceId,
        time: new Date()
      });

      return res.json({
        success: true,
        approved: true,
        firstDevice: true,
        message: "First device auto approved"
      });
    }

    // ✅ EXISTING DEVICE
    if (approvedDevices.includes(deviceId)) {
      logs.push({
        type: "KNOWN_DEVICE_LOGIN",
        deviceId,
        time: new Date()
      });

      return res.json({
        success: true,
        approved: true,
        message: "Welcome back"
      });
    }

    // ⚠️ NEW DEVICE
    logs.push({
      type: "NEW_DEVICE_REQUEST",
      deviceId,
      time: new Date()
    });

    return res.json({
      success: true,
      approved: false,
      message: "Device approval required"
    });

  } catch (e) {
    console.log(e);

    return res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
});

// =========================
// APPROVE DEVICE
// =========================

app.post("/approve-device", (req, res) => {
  try {
    const { deviceId } = req.body;

    if (!approvedDevices.includes(deviceId)) {
      approvedDevices.push(deviceId);
    }

    logs.push({
      type: "DEVICE_APPROVED",
      deviceId,
      time: new Date()
    });

    return res.json({
      success: true
    });

  } catch (e) {
    return res.status(500).json({
      success: false
    });
  }
});

// =========================
// CHAT ROUTE
// =========================

app.post("/chat", async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({
        reply: "No message provided"
      });
    }

    // 🤖 BASIC AI RESPONSE
    let reply = `You said: ${message}`;

    // 🎭 EMOTIONAL RESPONSES
    const lower = message.toLowerCase();

    if (lower.includes("sad")) {
      reply = "Hey... I am here for you ❤️";
    }

    if (lower.includes("angry")) {
      reply = "Calm down, I got you.";
    }

    if (lower.includes("happy")) {
      reply = "That’s awesome 😄";
    }

    logs.push({
      type: "CHAT",
      message,
      time: new Date()
    });

    return res.json({
      reply
    });

  } catch (e) {
    console.log(e);

    return res.status(500).json({
      reply: "Server error"
    });
  }
});

// =========================
// LOGS ROUTE
// =========================

app.get("/logs", (req, res) => {
  return res.json(logs);
});

// =========================
// DEVICES ROUTE
// =========================

app.get("/devices", (req, res) => {
  return res.json(approvedDevices);
});

// =========================
// START SERVER
// =========================

app.listen(PORT, () => {
  console.log(`Zeni server running on port ${PORT}`);
});