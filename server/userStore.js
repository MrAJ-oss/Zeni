import fs from "fs";

const FILE = "./user.json";

export function getUser() {
  if (!fs.existsSync(FILE)) return null;
  return JSON.parse(fs.readFileSync(FILE));
}

export function saveUser(user) {
  fs.writeFileSync(FILE, JSON.stringify(user, null, 2));
}