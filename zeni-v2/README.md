# Zeni 🤖

> A personal AI assistant designed to bring conversation, memory, automation, voice, devices, and intelligent tools into one unified ecosystem.

Zeni is a personal AI assistant project focused on building a single, extensible intelligence that can understand the user, remember relevant context, interact through voice, work with connected devices, and eventually perform real-world tasks through controlled tools and automation.

The goal is simple:

**One assistant. One intelligence. One ecosystem.**

---

## ✨ What is Zeni?

Zeni is more than a conventional chatbot.

It is designed as a modular AI ecosystem where different capabilities work together behind a unified assistant.

Core areas include:

* 🧠 AI reasoning
* 💾 Long-term memory
* 💬 Conversation management
* 🎙️ Voice interaction
* 🔐 Voice authentication
* ❤️ Emotion intelligence
* 💻 PC/device interaction
* ⚙️ Automation
* 🛠️ Coding assistance
* 🔎 Research assistance
* 📋 Project assistance
* 📈 Business and strategy assistance
* 🛡️ Defensive security concepts through Zeni Sentinel
* 🔌 Extensible external integrations

---

## 🏗️ Architecture

Zeni is designed around multiple specialized components rather than putting everything into one server.

```text
                         ┌───────────────────┐
                         │     Zeni App      │
                         │  UI / Voice / UX  │
                         └─────────┬─────────┘
                                   │
                                   ▼
                         ┌───────────────────┐
                         │   Zeni Main API   │
                         │    AI / Memory    │
                         │ Tools / Sessions  │
                         └───────┬─────┬─────┘
                                 │     │
                    ┌────────────┘     └─────────────┐
                    ▼                                ▼
          ┌──────────────────┐             ┌──────────────────┐
          │   NOVA Service   │             │  Voice Auth      │
          │ Emotion / Tone   │             │     Service      │
          └──────────────────┘             └──────────────────┘
                                      
                                      
                         ┌───────────────────┐
                         │    PC Agent       │
                         │ Local PC Control   │
                         └───────────────────┘
```

The exact deployment architecture may evolve as Zeni develops.

The important principle is that each subsystem has a clearly defined responsibility.

---

## 🧠 AI Brain

Zeni uses an AI provider abstraction so the rest of the application does not need to be tightly coupled to a single model provider.

The current architecture uses **OpenRouter** as the model-routing layer.

Conceptually:

```text
Zeni
  ↓
AI Service
  ↓
Model Router
  ↓
OpenRouter
  ↓
Selected AI Model
```

This allows models to be changed without rewriting the rest of Zeni.

---

## 💾 Memory

Memory is a core part of Zeni.

Zeni is designed to distinguish between:

* Current conversation context
* Long-term memories
* User preferences
* Project context
* Relevant historical information
* Other structured context

The system should retrieve only relevant information instead of sending an entire memory database to the AI for every request.

Conceptually:

```text
User Request
     ↓
Memory Retrieval
     ↓
Relevant Context
     ↓
AI Reasoning
     ↓
Response
```

Memory and conversation history are intentionally treated as separate concepts.

---

## 💬 Conversation System

Zeni maintains conversational context so interactions can continue naturally.

The conversation system is responsible for:

* Sessions
* Messages
* Conversation history
* Context management
* Timestamps
* Message metadata
* Retrieval

Long-term memory is handled separately from raw conversation history.

---

## 🎙️ Voice

Zeni is designed to support voice interaction.

The intended pipeline is:

```text
User Speech
    ↓
Speech-to-Text
    ↓
Zeni AI
    ↓
Text Response
    ↓
Text-to-Speech
    ↓
Voice Output
```

Voice should use the same Zeni intelligence, memory, personality, and context as text interactions.

---

## 🔐 Voice Authentication

Zeni includes a dedicated voice-authentication concept for protected functionality.

The authentication service is intentionally separated from the main AI server.

```text
Voice Input
    ↓
Voice Authentication
    ↓
Identity Verification
    ↓
Authorized Zeni Access
```

Authentication credentials and secrets must never be exposed to the client.

---

## ❤️ NOVA — Emotion Intelligence

**NOVA** is Zeni's emotion-intelligence subsystem.

NOVA is designed to analyze emotional signals from available input such as:

* Text
* Voice
* Tone
* Conversational context

NOVA provides structured emotional context to Zeni's AI system.

```text
User Input
    ↓
NOVA
    ↓
Emotional Context
    ↓
Zeni AI
    ↓
Adaptive Response
```

NOVA is designed as an independent service so its underlying implementation can evolve without rewriting the main Zeni system.

---

## 💻 Zeni PC Agent

The Zeni PC Agent is a local component that acts as a controlled bridge between Zeni and a user's computer.

Instead of giving the cloud server unrestricted access to the machine:

```text
Zeni Server
     ↓
Authenticated Request
     ↓
PC Agent
     ↓
Permission Validation
     ↓
Local Action
     ↓
Result
```

Potential capabilities include:

* PC status
* Device information
* Approved automation
* Application interaction
* Local file operations
* Approved command execution
* Returning local results

Security and permission boundaries are fundamental to this component.

---

## ⚙️ Tool & Automation System

Zeni is designed around structured tools rather than allowing an AI model to directly execute arbitrary actions.

The intended architecture is:

```text
AI
 ↓
Tool Selection
 ↓
Structured Arguments
 ↓
Validation
 ↓
Authorization
 ↓
Tool Execution
 ↓
Structured Result
 ↓
AI
```

Each tool should have:

* A defined name
* Description
* Input schema
* Output schema
* Permission requirements
* Risk level
* Execution environment

This architecture makes Zeni easier to extend while maintaining control over automated actions.

---

## 🛠️ Coding Assistant

Zeni is designed to assist with software development.

Potential capabilities include:

* Code generation
* Debugging
* Error analysis
* Code explanation
* Architecture planning
* Code review
* Project planning
* Development assistance

Zeni should always distinguish between:

**suggesting a code change**

and

**actually modifying/executing something.**

Actions must only be reported as completed when they were actually executed.

---

## 🔎 Research Assistant

Zeni can be extended with information-retrieval capabilities for research workflows.

Possible functionality includes:

* Information gathering
* Source analysis
* Comparisons
* Summarization
* Research planning
* Structured findings

External information retrieval should remain separate from the core AI layer.

---

## 📋 Project Intelligence

Zeni is designed to understand ongoing projects instead of treating everything as isolated conversations.

A project can contain:

* Name
* Description
* Tasks
* Notes
* Status
* Milestones
* Decisions
* Relevant context

This allows Zeni to act as a persistent project assistant.

---

## 📈 Business & Strategy

Zeni is also designed to assist with business and strategy workflows.

Potential areas include:

* Idea analysis
* Business planning
* Marketing strategy
* Project decisions
* Market research
* Organization
* Execution planning

---

## 🛡️ Zeni Sentinel

**Zeni Sentinel** is the defensive security component of the Zeni ecosystem.

Its long-term purpose is to help identify potentially suspicious activity and improve the security of connected Zeni systems.

Potential areas include:

* Suspicious activity detection
* Security monitoring
* Network-related signals
* Device security
* Threat detection

Sentinel is intended for defensive security and protection.

---

## 🔌 Extensibility

Zeni is designed to grow over time.

External services should be integrated through abstractions instead of being deeply embedded into the core application.

For example:

```text
Integration Service
       │
       ├── Provider A
       ├── Provider B
       └── Provider C
```

This makes providers replaceable and keeps the core architecture clean.

---

## 🔐 Security Principles

Security is a fundamental part of Zeni.

The project follows principles such as:

* Never expose API keys to clients
* Keep secrets in environment variables
* Authenticate services
* Authorize devices
* Validate tool calls
* Restrict local PC permissions
* Validate automated actions
* Avoid unrestricted AI-generated commands
* Use secure service communication
* Maintain safe audit logs
* Never store credentials in source code

---

## 🧪 Testing

Zeni should be tested at multiple levels.

### Unit Tests

Core components such as:

* Memory
* Authentication
* Tool validation
* Device permissions
* AI request construction
* Business logic

### Integration Tests

Service communication such as:

* API → Database
* API → AI provider
* API → NOVA
* API → PC Agent
* Authentication flows

### End-to-End Tests

Critical user workflows should be tested from the user's interface through the complete backend pipeline.

---

## 📊 Observability

Zeni should provide structured logging and health monitoring.

Important events include:

* Requests
* Authentication
* AI calls
* Tool calls
* Memory retrieval
* NOVA processing
* Device communication
* PC-agent communication
* Errors
* Service health
* Performance/latency

Sensitive credentials must never be written to logs.

---

## ⚙️ Configuration

Zeni uses environment-based configuration.

Create a local environment file based on the example configuration:

```bash
cp .env.example .env
```

Typical configuration may include:

```env
OPENROUTER_API_KEY=
DATABASE_URL=
NOVA_API_URL=
VOICE_AUTH_URL=
PC_AGENT_URL=
```

Only add variables actually required by the current implementation.

**Never commit real API keys or credentials to GitHub.**

---

## 🚀 Development

Clone the repository:

```bash
git clone <repository-url>
cd zeni
```

Install dependencies according to the specific service.

Then configure the required environment variables.

Run the relevant development services according to the project structure.

The repository should clearly document individual commands for:

* Main server
* NOVA service
* Voice authentication service
* PC Agent
* Client application

---

## 📁 Project Structure

The exact structure may evolve, but the project should maintain clear separation of responsibilities.

```text
zeni/
│
├── client/
│
├── server/
│   ├── api/
│   ├── ai/
│   ├── memory/
│   ├── conversations/
│   ├── tools/
│   ├── devices/
│   ├── authentication/
│   ├── projects/
│   ├── integrations/
│   ├── database/
│   ├── config/
│   └── utils/
│
├── nova/
│
├── voice-auth/
│
├── pc-agent/
│
├── tests/
│
├── docs/
│
├── .env.example
├── .gitignore
└── README.md
```

The actual repository may differ depending on the implementation.

The important requirement is that there should be one authoritative implementation for each subsystem.

---

## 🚧 Development Status

Zeni is an actively developed project.

Some capabilities are implemented, while others are under development or planned.

Feature status should be documented honestly.

| Component            | Status                |
| -------------------- | --------------------- |
| Core AI              | 🟡 In development     |
| Memory               | 🟡 In development     |
| Conversations        | 🟡 In development     |
| Voice                | 🟡 In development     |
| Voice Authentication | 🟡 In development     |
| NOVA                 | 🟡 In development     |
| PC Agent             | 🟡 In development     |
| Automation           | 🟡 In development     |
| Coding Assistant     | 🟡 In development     |
| Research             | 🟡 In development     |
| Project Intelligence | 🟡 In development     |
| Zeni Sentinel        | 🔵 Planned / evolving |

> Status will change as development progresses.

---

## 🗺️ Roadmap

### Phase 1 — Foundation

* [ ] Clean architecture
* [ ] Stable API
* [ ] Authentication
* [ ] Database
* [ ] AI provider abstraction
* [ ] Conversation system
* [ ] Memory system

### Phase 2 — Intelligence

* [ ] NOVA integration
* [ ] Better contextual memory
* [ ] Tool system
* [ ] Project intelligence
* [ ] Research capabilities

### Phase 3 — Voice & Devices

* [ ] Voice pipeline
* [ ] Voice authentication
* [ ] Wake-word system
* [ ] Stop/cancellation system
* [ ] PC Agent
* [ ] Device management

### Phase 4 — Automation

* [ ] Secure automation
* [ ] Tool permissions
* [ ] Cross-device workflows
* [ ] External integrations

### Phase 5 — Sentinel

* [ ] Security monitoring
* [ ] Device security
* [ ] Threat detection
* [ ] Defensive security automation

---

## 🎯 Design Philosophy

Zeni is being built around a few simple principles:

```text
One Intelligence
        +
Modular Architecture
        +
Real Functionality
        +
Strong Security
        +
Persistent Context
        =
Zeni
```

The goal is not to build hundreds of disconnected features.

The goal is to build one coherent AI system that can continuously gain new capabilities without becoming architecturally unstable.

---

## 🤝 Contributing

Zeni is currently under active development.

Before contributing significant changes:

1. Understand the existing architecture.
2. Avoid duplicating existing functionality.
3. Keep modules focused.
4. Do not commit secrets.
5. Add tests for important functionality.
6. Update documentation when architecture changes.
7. Do not add experimental code directly into production modules.

---

## 📜 License

License information will be added when the project's licensing decision is finalized.

---

## 👤 Author

**Anuj Joshi**

Zeni is an independent AI project focused on exploring what a highly integrated personal AI assistant can become.

---

## ⭐ Vision

Zeni is being built toward a future where an AI assistant is not limited to a chat window.

It can understand context.

It can remember.

It can communicate through voice.

It can interact with devices.

It can work with tools.

It can assist with projects.

It can help build software.

It can automate approved workflows.

And most importantly, all of these capabilities can operate as parts of **one unified intelligence**.

**This is Zeni.**

