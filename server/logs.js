let logs = [];

export function addLog(type, deviceId, message) {
  logs.push({
    type,
    deviceId,
    message,
    time: new Date()
  });

  if (logs.length > 50) logs.shift();
}

export function getLogs() {
  return logs;
}

export function clearLogs() {
  logs = [];
}