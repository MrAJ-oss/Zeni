# Zeni

A personal AI companion built to feel like a friend, not an assistant — with real memory, real device control, and a safety architecture built around one rule: nothing pretends to have happened that didn't.

Zeni runs on whatever model you point her at via OpenRouter — she isn't a new model, she's an architecture: persistent memory, personality, and real integration with your actual devices and files, wrapped around models that already exist.

## What she actually does

**Talks like a friend, not a chatbot.** Central personality config (trust, teasing, directness — she pushes back because she's on your side, not despite it), persistent memory that's actually relevance-ranked (TF-IDF, not a keyword dump), full conversation history.

**Real voice.** Whisper transcription in, neural TTS out (ElevenLabs if you configure a voice, OpenRouter's own TTS otherwise) — not the robotic on-device OS voice.

**Sees and reacts.** Camera-triggered reactions (one multimodal call — sees the frame and responds in personality in a single request, not a separate "vision AI" bolted to a separate "personality AI"). Geofencing greets you when you get home. Web search when she needs current information, not by default.

**Controls your PC — safely.** File read/write, clipboard, app launching, even real-time mouse/keyboard control — every risky action gated behind an actual approval queue, not just a flag that does nothing. Four files are permanently off-limits to self-editing: the ones that decide what's allowed to happen.

**Builds herself, safely.** Ask for a feature, she builds it in an isolated sandbox copy, runs it on a separate port so you can actually test it live, and only a single approved action ever promotes a file into the real, running app.

**Calls people by first name.** Fuzzy contact matching, not exact strings — "call Pranav" finds Pranav DYP.

**Knows security.** Sentinel: IP reputation lookups, security event logging (link scanning needs a threat-intel provider you haven't configured yet — see below).

**Remembers what actually happened.** Every tool call, every approval, every rejection — logged. Nothing claims success it didn't earn.

## Architecture

```
client/              Flutter app — voice-first, one main screen, edge-swipe drawer for features
server/               Node/Express — the brain: chat, memory, tools, approvals, all of it
pc-agent/             Runs on your actual computer — the only thing with real device access
voice-auth-service/   Python/FastAPI — real speaker verification, runs locally, no cloud dependency
nova-service/         Python/FastAPI — real sentiment analysis, same deal
.github/workflows/    Keep-alive ping so Render's free tier doesn't cold-start on you
```

Every risky capability follows the same shape: **request → validate → (approve if it's genuinely risky) → execute → log.** The LLM never directly executes anything — it can only ask.

## Setup

See `zeni-setup-guide.md` if you have it, or:

1. `cd server && npm install`, copy `.env.example` to `.env`, add your `OPENROUTER_API_KEY`, `MAIN_PASSWORD`, `JWT_SECRET`
2. `node index.js` to test locally, then deploy (Render, etc.)
3. `cd client`, run `flutter create --org com.yourname .` to generate the native project files (not included — see note below), restore `lib/` and `pubspec.yaml`, `flutter pub get`, build
4. Optional: run `voice-auth-service/` and `nova-service/` locally for real voice ID and emotion reading
5. Optional: run `pc-agent/` on your computer for file/device control

## Honest status — what's real vs. what isn't

This matters more than a feature list. Nothing here claims to work unless it's been tested.

**Tested and confirmed working:** chat/memory/device/tool core, the approval queue (proven end-to-end with a real connected agent over a real websocket), protected-path blocking, the sandbox build-and-promote flow, TF-IDF memory ranking, NOVA sentiment analysis (real classifier, tested against real text), voice auth (real speaker verification, tested enroll→verify with correct accept/reject).

**Built, not independently verified:** the entire Flutter client has never been compiled — no Flutter SDK in the environment this was built in. Structurally correct to the best of available knowledge; run `flutter analyze` before trusting it. A few external calls (geocoding, IP lookup) are correct against stable public APIs but were never live-tested due to sandboxed network restrictions.

**Not built yet:**
- Dedicated always-on wake word (current version listens in the foreground only, while the app is open)
- Phone-side app control (controlling other apps on the phone itself — PC control exists, this doesn't)
- Live cross-device handoff mid-conversation
- Sentinel link scanning (needs a threat-intel API key)
- Camera presence *auto-detection* (the reaction endpoint is real; nothing captures a photo or detects you're in frame automatically yet)

If a feature isn't listed here as tested, treat it as unverified until you've run it yourself.

## License


