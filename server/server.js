import express from "express";
import fetch from "node-fetch";
import fs from "fs";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(express.json());

const MEMORY_FILE = "memory.json";

// load memory
function loadMemory() {
  if (!fs.existsSync(MEMORY_FILE)) return [];
  return JSON.parse(fs.readFileSync(MEMORY_FILE, "utf-8"));
}

// save memory
function saveMemory(memory) {
  fs.writeFileSync(MEMORY_FILE, JSON.stringify(memory, null, 2));
}

// 🔑 from .env
const GROQ_API_KEY = process.env.GROQ_API_KEY;

app.post("/api/voice", async (req, res) => {
  const { text } = req.body;

  if (!text) {
    return res.status(400).json({ error: "No text provided" });
  }

  try {
    let memory = loadMemory();

    const context = memory
      .slice(-5)
      .map(m => `${m.role}: ${m.text}`)
      .join("\n");

    const prompt = `
You are Zeni, a smart futuristic assistant like Jarvis.
Speak short, confident, and helpful.

Conversation:
${context}

User: ${text}
Zeni:
`;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: "llama3-8b-8192",
        messages: [
          { role: "system", content: "You are Zeni AI assistant." },
          { role: "user", content: prompt }
        ]
      })
    });

    const data = await response.json();

    if (!data.choices) {
      console.log(data);
      return res.status(500).json({ error: "Invalid AI response" });
    }

    const reply = data.choices[0].message.content;

    // save memory
    memory.push({ role: "User", text });
    memory.push({ role: "Zeni", text: reply });
    saveMemory(memory);

    res.json({ reply });

  } catch (err) {
    console.log(err);
    res.status(500).json({ error: "AI failed" });
  }
});

app.listen(3000, () => {
  console.log("🚀 ZENI CLOUD AI running on port 3000");
});