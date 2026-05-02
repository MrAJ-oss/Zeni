import fetch from "node-fetch";
import { exec } from "child_process";

const SERVER = "https://zeni-1.onrender.com";

async function loop() {
  try {
    const res = await fetch(SERVER + "/pc-command");
    const data = await res.json();

    if (data.command === "open_chrome") {
      exec("start chrome");
    }

    if (data.command === "shutdown") {
      exec("shutdown /s /t 0");
    }
  } catch (e) {}

  setTimeout(loop, 3000);
}

loop();