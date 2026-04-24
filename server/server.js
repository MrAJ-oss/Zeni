import express from "express";
import fetch from "node-fetch";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Zeni Cloud AI Running 🚀");
});

const GROQ_API_KEY = process.env.GROQ_API_KEY;

app.post("/api/voice", async (req, res) => {
  const { text } = req.body;

  try {
    const lower = text.toLowerCase();

    // ===== BASIC COMMANDS =====
    if (lower.includes("time")) {
      return res.json({
        reply: `Current time is ${new Date().toLocaleTimeString()}`
      });
    }

    if (lower.includes("date")) {
      return res.json({
        reply: `Today is ${new Date().toDateString()}`
      });
    }

    // ===== AI PROMPT =====
    const prompt = `
You are Zeni, a smart human-like female AI assistant.

Understand user's emotion from their words.

Rules:
- If user sounds sad → be supportive and caring
- If angry → calm them
- If excited → match energy
- Talk like a real friend (natural, short, human)

User: ${text}
Zeni:
`;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: "llama3-8b-8192",
        messages: [{ role: "user", content: prompt }]
      })
    });

    const data = await response.json();
    const reply = data.choices[0].message.content;

    res.json({ reply });

  } catch (err) {
    console.log(err);
    res.status(500).json({ error: "AI failed" });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Zeni Cloud running on port ${PORT}`);
});