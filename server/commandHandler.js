function detectCommand(text) {
  text = text.toLowerCase();

  if (text.includes("chrome")) return "chrome";
  if (text.includes("notepad")) return "notepad";
  if (text.includes("shutdown")) return "shutdown";

  if (text.includes("youtube")) return "url:https://youtube.com";

  return null;
}

function extractTarget(text) {
  text = text.toLowerCase();

  if (text.includes("laptop")) return "laptop";
  if (text.includes("pc")) return "pc";

  return "all";
}

module.exports = { detectCommand, extractTarget };