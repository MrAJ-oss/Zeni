const { exec } = require("child_process");

function runCommand(cmd) {
  console.log("⚡ Executing:", cmd);

  if (cmd === "chrome") exec("start chrome");
  else if (cmd === "notepad") exec("notepad");
  else if (cmd === "shutdown") exec("shutdown /s /t 0");

  else if (cmd.startsWith("url:")) {
    exec(`start ${cmd.replace("url:", "")}`);
  }
}

module.exports = { runCommand };