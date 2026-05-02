import fs from "fs";

const FILE = "./devices.json";

export function getDevices() {
  if (!fs.existsSync(FILE)) return [];
  return JSON.parse(fs.readFileSync(FILE));
}

export function saveDevices(devices) {
  fs.writeFileSync(FILE, JSON.stringify(devices, null, 2));
}