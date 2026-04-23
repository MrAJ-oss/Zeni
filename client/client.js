const WebSocket = require("ws");
const { runCommand } = require("./executor");

const DEVICE_ID = "laptop";

const ws = new WebSocket("ws://localhost:3000");

ws.on("open", () => {
  console.log("🟢 Connected");

  ws.send(JSON.stringify({
    type: "register",
    deviceId: DEVICE_ID
  }));
});

ws.on("message", (msg) => {
  const data = JSON.parse(msg);

  if (data.action) {
    runCommand(data.action);
  }
});