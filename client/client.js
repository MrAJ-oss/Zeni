const SERVER = "https://zeni-1.onrender.com/"; // 🔥 CHANGE THIS

async function checkCommand() {
  try {
    const res = await fetch(`${SERVER}/api/command`);
    const text = await res.text();

    // ❌ If HTML comes, skip
    if (!text.startsWith("{")) {
      console.log("⚠️ Not JSON response");
      return;
    }

    const data = JSON.parse(text);

    if (!data.command) return;

    console.log("🔥 Command received:", data.command);

    // ================= ACTIONS =================

    if (data.command === "shutdown") {
      require("child_process").exec("shutdown /s /t 0");
    }

    if (data.command === "restart") {
      require("child_process").exec("shutdown /r /t 0");
    }

    if (data.command === "chrome") {
      require("child_process").exec("start chrome");
    }

    if (data.command === "notepad") {
      require("child_process").exec("start notepad");
    }

    if (data.command === "explorer") {
      require("child_process").exec("start explorer");
    }

    if (data.command.startsWith("url:")) {
      const url = data.command.replace("url:", "");
      require("child_process").exec(`start ${url}`);
    }

  } catch (err) {
    console.log("❌ Error:", err.message);
  }
}

// 🔁 Run every 2 seconds
setInterval(checkCommand, 2000);

console.log("💻 PC Client Running...");