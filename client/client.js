import fetch from "node-fetch";
import { exec } from "child_process";

const SERVER = "https://zeni-1.onrender.com";
const DEVICE_ID = "pc-001";

async function ping() {
  try {
    await fetch(`${SERVER}/api/ping`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        deviceId: DEVICE_ID,
        name: "Anuj Laptop",
        type: "pc"
      })
    });
  } catch {}
}

async function checkCommand() {
  try {
    const res = await fetch(`${SERVER}/api/command`);
    const data = await res.json();

    if (!data.command) return;

    console.log("Command:", data.command);

    if (data.command === "chrome") {
      exec("start chrome");
    }

    if (data.command === "shutdown") {
      exec("shutdown /s /t 0");
    }

  } catch {}
}

setInterval(ping, 2000);
setInterval(checkCommand, 2000);

console.log("💻 Client running...");