import express from "express";
import fs from "fs";
import cors from "cors";
import fetch from "node-fetch";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const FILE = "./user.json";
const GROQ_KEY = process.env.GROQ_API_KEY;

// ===== STORAGE =====
function getUser() {
  if (!fs.existsSync(FILE)) return null;
  return JSON.parse(fs.readFileSync(FILE));
}

function saveUser(user) {
  fs.writeFileSync(FILE, JSON.stringify(user, null, 2));
}

// ===== MEMORY =====
function getMemory(user) {
  return user.memory.slice(-3).map(m =>
    `User: ${m.user}\nZeni: ${m.zeni}`
  ).join("\n");
}

// ===== AI =====
async function zeniBrain(text, user) {
  try {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama3-70b-8192",
        temperature: 0.7,
        max_tokens: 80,
        messages: [
          {
            role: "system",
            content: "You are Zeni. Be human, emotional, curious. Keep replies short."
          },
          {
            role: "user",
            content: getMemory(user) + "\nUser: " + text
          }
        ]
      })
    });

    const data = await response.json();

    return {
      reply: data.choices?.[0]?.message?.content || "Hmm?"
    };

  } catch {
    return { reply: "Something went wrong." };
  }
}

// ===== ROUTES =====

app.post("/setup", (req, res) => {
  const { name, password } = req.body;

  if (getUser()) return res.json({ status: "exists" });

  const user = {
    name,
    password,
    memory: []
  };

  saveUser(user);
  res.json({ status: "created" });
});

app.post("/voice", async (req, res) => {
  const { text } = req.body;
  const user = getUser();

  const result = await zeniBrain(text, user);

  user.memory.push({ user: text, zeni: result.reply });
  saveUser(user);

  res.json(result);
});

app.listen(3000, () => console.log("🚀 Server running"));