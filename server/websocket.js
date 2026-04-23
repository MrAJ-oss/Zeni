const WebSocket = require("ws");

let sockets = {};

function initWebSocket(server) {
  const wss = new WebSocket.Server({ server });

  wss.on("connection", (ws) => {
    ws.on("message", (msg) => {
      const data = JSON.parse(msg);

      if (data.type === "register") {
        sockets[data.deviceId] = ws;
        console.log("🔌 Connected:", data.deviceId);
      }
    });

    ws.on("close", () => {
      for (let id in sockets) {
        if (sockets[id] === ws) delete sockets[id];
      }
    });
  });

  setInterval(() => {
    for (let id in sockets) {
      try {
        sockets[id].send(JSON.stringify({ type: "ping" }));
      } catch {
        delete sockets[id];
      }
    }
  }, 5000);
}

function sendCommand(target, cmd) {
  for (let id in sockets) {
    if (target === "all" || id.includes(target)) {
      sockets[id].send(JSON.stringify({ action: cmd }));
    }
  }
}

module.exports = { initWebSocket, sendCommand };