let devices = [];

export function registerDevice(id, name) {
  const existing = devices.find(d => d.id === id);
  if (existing) return existing;

  const device = {
    id,
    name,
    approved: devices.length === 0
  };

  devices.push(device);
  return device;
}

export function approveDevice(id) {
  const d = devices.find(x => x.id === id);
  if (d) d.approved = true;
  return d;
}

export function isApproved(id) {
  return devices.find(d => d.id === id)?.approved || false;
}

export function getPendingDevices() {
  return devices.filter(d => !d.approved);
}

// 🔥 NEW
export function renameDevice(id, newName) {
  const d = devices.find(x => x.id === id);
  if (d) d.name = newName;
  return d;
}

export function renameByName(oldName, newName) {
  const d = devices.find(x =>
    x.name.toLowerCase().includes(oldName.toLowerCase())
  );
  if (d) d.name = newName;
  return d;
}

export function getDevices() {
  return devices;
}