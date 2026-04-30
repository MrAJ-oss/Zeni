export function detectCommand(text) {
  const t = text.toLowerCase();

  if (t.includes("show logs")) return "show_logs";
  if (t.includes("delete logs")) return "delete_logs";
  if (t.includes("pending devices")) return "pending_devices";

  return null;
}