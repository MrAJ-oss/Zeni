import { WebSocketServer } from "ws";

export const connectedDevices = new Map();

export function initWebSocket(server) {
  const wss = new WebSocketServer({ server });

  wss.on("connection", (ws) => {
    let deviceId = null;

    ws.on("message", (msg) => {
      const data = JSON.parse(msg);

      if (data.type === "register") {
        deviceId = data.deviceId;
        connectedDevices.set(deviceId, ws);
        console.log("Device connected:", deviceId);
      }
    });

    ws.on("close", () => {
      if (deviceId) {
        connectedDevices.delete(deviceId);
        console.log("Device disconnected:", deviceId);
      }
    });
  });
}

// SEND COMMAND
export function sendToDevice(target, payload) {
  if (target === "all") {
    connectedDevices.forEach((ws) => {
      ws.send(JSON.stringify(payload));
    });
  } else {
    const ws = connectedDevices.get(target);
    if (ws) ws.send(JSON.stringify(payload));
  }
}