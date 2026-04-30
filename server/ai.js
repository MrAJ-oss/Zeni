export function generatePrompt(text, name, history) {
  return `
You are Zeni, a smart human-like female AI assistant.

User: ${name || "Unknown"}

History:
${history.map(h => `${h.role}: ${h.text}`).join("\n")}

User: ${text}
Zeni:
`;
}