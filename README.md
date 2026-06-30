#  Self-Hosted Feature Flag & Remote Config Engine

> A production-inspired, real-time feature flag system built from scratch — no third-party services, no black boxes. Just Python, WebSockets, and Flutter working together.

---

## 🎬 Demo Video
[Add demo video link here]



## 📌 What Is This?

This project is a **DIY version of tools like LaunchDarkly and Firebase Remote Config** — built entirely from scratch as part of GDSC IITR Project 02.

It gives developers a **remote control for their app** — you can:
- Turn features **ON/OFF instantly** without releasing a new app version
- **Target specific users** — only beta users or a random 10% sample
- **Change app settings** (like welcome messages) on the fly
- See all changes **reflect in real-time** across every connected client

Professional tools that do the same thing:
| Tool | Monthly Cost |
|---|---|
| LaunchDarkly | $75–$300+ |
| Firebase Remote Config | Free (but Google-locked) |
| Optimizely | $50,000+/year |
| Split.io | $33+/month |

**This project builds the same core engine — for free, self-hosted, fully understood.**

---

## ✨ Features

### Core Features
- **Feature Flags** — Simple ON/OFF switches. Flip `dark_mode_beta` ON and every connected client sees it instantly
- **Remote Config** — Key-value settings like `welcome_message = "Hello!"`. Change without redeploying
- **Real-Time Sync** — WebSocket broadcast pushes every flag change to ALL connected clients instantly — no polling, no refresh
- **Group Rollouts** — Three targeting rule types:
  - `everyone` — All users get the feature
  - `beta_only` — Only specific user IDs get the feature
  - `percentage` — Consistent hash-based rollout (e.g. 10% of users)
- **User Evaluation** — Pass any `user_id` to `/evaluate` and get back exactly which flags are active for that user

### Additional Features (Beyond Basic Requirements)
- **Archive Flags** — Hide a flag from the Flutter app without deleting it. Press `A` in the TUI to archive/unarchive. Archived flags remain visible in the TUI for developer management but disappear from the client app instantly
- **Consistent Percentage Hashing** — Uses `hashlib.md5` to ensure the same user always gets the same result for percentage rollouts. `user123` will always either be in the 10% or not — never changes between API calls
- **API Key Middleware** — Developer routes (create, delete) are protected with an API key. Public routes (toggle, evaluate, read) are open — matching real-world security patterns
- **WebSocket Reconnection** — Both the Textual TUI and Flutter app auto-reconnect every 3 seconds if the server goes down
- **Connection Status Indicator** — Flutter app shows a live green/orange dot showing WebSocket connection state
- **GET /flags/all** — Separate route for the TUI that returns ALL flags including archived ones, protected by API key

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│            Python Backend (FastAPI)          │
│                                             │
│  REST API ──── WebSocket Server ──── JSON   │
│  (CRUD)        (Broadcast)          Storage │
└──────────────────────┬──────────────────────┘
                       │ HTTP + WebSocket
          ┌────────────┴────────────┐
          │                         │
┌─────────▼──────────┐   ┌─────────▼──────────┐
│  Textual TUI        │   │  Flutter App        │
│  (Developer Tool)   │   │  (Demo Client)      │
│                     │   │                     │
│  Create flags       │   │  View flags         │
│  Delete flags       │   │  Toggle flags       │
│  Toggle flags       │   │  Real-time updates  │
│  Archive flags      │   │  Evaluate users     │
│  Real-time updates  │   │  Config editor      │
└─────────────────────┘   └─────────────────────┘
```

**WebSocket explained simply:** Normal API calls are like sending a letter — you send, they reply, connection closes. A WebSocket is like a phone call that stays open. When you flip a flag, the server immediately pushes that change to every connected client.

---

## 🛠️ Tech Stack

| Technology | Used For |
|---|---|
| Python 3.12 | Backend language |
| FastAPI | Web framework + WebSocket support |
| Uvicorn | ASGI server |
| Pydantic | Data validation and schemas |
| Websockets | WebSocket client in Textual TUI |
| Httpx | Async HTTP client in Textual TUI |
| Textual | Terminal UI framework |
| python-dotenv | Environment variable management |
| Flutter + Dart | Demo client mobile/web app |
| web_socket_channel | WebSocket client in Flutter |
| http (Flutter) | REST API calls in Flutter |
| JSON files | Lightweight storage (no database needed) |

---

## 📁 Project Structure

```
Self-Hosted-Feature-Flag-Remote-Config-Engine/
│
├── backend/
│   ├── main.py              # FastAPI app — all routes + WebSocket server
│   ├── models.py            # Pydantic schemas (FeatureFlag, ConfigVar)
│   ├── store.py             # FlagStore — load/save/toggle/delete/evaluate
│   ├── config_store.py      # ConfigStore — load/save/update/delete configs
│   ├── flags.json           # Flag storage (auto-created)
│   ├── config.json          # Config storage (auto-created)
│   ├── requirements.txt     # Python dependencies
│   ├── start.sh             # One-command server start
│   ├── .env                 # API key (never committed)
│   └── .env.example         # Template for environment variables
│
├── frontend/
│   └── app.py               # Textual TUI — developer control panel
│
├── flutter_client/
│   ├── lib/
│   │   └── main.dart        # Flutter app — demo client
│   ├── pubspec.yaml         # Flutter dependencies
│   └── README.md            # Flutter-specific setup instructions
│
├── .gitignore
├── README.md                # This file
└── API_DOCS.md              # Complete API reference
```

---

## 🚀 Setup & Run Instructions

### Prerequisites
- Python 3.12 ([download here](https://python.org/downloads/release/python-3120/))
- Flutter SDK ([install here](https://flutter.dev/docs/get-started/install))
- Git

---

### Part 1 — Backend Setup

**Step 1 — Clone the repo**
```bash
git clone https://github.com/namanawana/Self-Hosted-Feature-Flag-Remote-Config-Engine.git
cd Self-Hosted-Feature-Flag-Remote-Config-Engine
```

**Step 2 — Create virtual environment**
```bash
cd backend
python3.12 -m venv venv
```

**Step 3 — Activate virtual environment**
```bash
# Mac/Linux
source venv/bin/activate

# Windows
venv\Scripts\activate
```

**Step 4 — Install dependencies**
```bash
pip install -r requirements.txt
```

**Step 5 — Set up environment variables**
```bash
cp .env.example .env
```
Open `.env` and set your API key:
```
API_KEY=your_secret_key_here
```

**Step 6 — Start the backend server**
```bash
uvicorn main:app --reload
```
Server runs at: `http://localhost:8000`
API docs available at: `http://localhost:8000/docs`

---

### Part 2 — Textual TUI Setup (Developer Control Panel)

Open a **new terminal** (keep backend running):

```bash
cd frontend
python app.py
```

**TUI Keyboard Shortcuts:**
| Key | Action |
|---|---|
| `Space` | Toggle selected flag ON/OFF |
| `N` | Create new flag |
| `D` | Delete selected flag (with confirmation) |
| `A` | Archive/unarchive flag (hides from Flutter app) |
| `R` | Refresh flag list |
| `Q` | Quit |

---

### Part 3 — Flutter App Setup (Demo Client)

Open another **new terminal**:

```bash
cd flutter_client
flutter pub get
flutter run
```

For browser:
```bash
flutter run -d chrome
```

For mobile emulator:
```bash
flutter run -d android
# or
flutter run -d ios
```

**Important:** Make sure the backend is running on `localhost:8000` before starting the Flutter app. The URL is configured at the top of `lib/main.dart`:
```dart
const String baseUrl = "http://localhost:8000";
const String wsUrl = "ws://localhost:8000/ws";
```

---

### Running Everything Together

You need **3 terminals** open simultaneously:

```
Terminal 1 (Backend):
  cd backend && uvicorn main:app --reload

Terminal 2 (TUI):
  cd frontend && python app.py

Terminal 3 (Flutter):
  cd flutter_client && flutter run -d chrome
```

---

## 🧪 Testing the System

### Test 1 — Real-Time Flag Toggle
1. Open Flutter app in browser
2. Open TUI in terminal
3. Select a flag in TUI, press `Space` to toggle
4. Watch Flutter app update **instantly** — no refresh needed

### Test 2 — Create and Archive
1. Press `N` in TUI → fill in flag details → press Create
2. New flag appears in Flutter app instantly
3. Press `A` on that flag in TUI → flag disappears from Flutter instantly
4. Press `A` again → flag reappears in Flutter

### Test 3 — User Evaluation
1. In Flutter app, tap the 👤 icon (bottom of screen)
2. Enter a user ID (e.g. `naman`) → tap Evaluate
3. See which flags are active for that specific user
4. Try different user IDs — percentage rollout gives consistent results

### Test 4 — API Directly
Visit `http://localhost:8000/docs` to test all routes interactively.

---

## 🌱 Seed Data

The project comes with 3 pre-loaded flags covering all three rule types:

| Flag | Status | Rule | Meaning |
|---|---|---|---|
| `new_checkout_flow` | ON | Beta Only (`naman`, `user1`, `user2`) | Only beta users see new checkout |
| `dark_mode_beta` | OFF | Everyone | Dark mode feature — currently disabled |
| `ai_recommendations` | ON | 10% Rollout | Only 10% of users see AI features |

---

## 📡 API Overview

Base URL: `http://localhost:8000`

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/flags` | No | Get all active (non-archived) flags |
| POST | `/flags` | Yes | Create a new flag |
| PATCH | `/flags/{name}/toggle` | No | Toggle flag ON/OFF |
| DELETE | `/flags/{name}` | Yes | Delete a flag |
| PATCH | `/flags/{name}/archive` | Yes | Archive/unarchive a flag |
| GET | `/flags/all` | Yes | Get ALL flags including archived (TUI only) |
| GET | `/flags/stats` | No | Get total/enabled/disabled counts |
| GET | `/config` | No | Get all config variables |
| POST | `/config` | Yes | Create a config variable |
| PATCH | `/config/{key}` | No | Update a config value |
| DELETE | `/config/{key}` | Yes | Delete a config variable |
| POST | `/evaluate` | No | Get active flags for a specific user |
| GET | `/health` | No | Server health check |
| WS | `/ws` | No | WebSocket — real-time flag updates |

For full request/response details see `API_DOCS.md`.

---

## 💡 Assumptions & Design Decisions

### 1. JSON File Storage (No Database)
We chose JSON file storage over a database intentionally — this keeps the project self-contained with zero external dependencies. Anyone can clone and run without setting up PostgreSQL, MongoDB, or any database server.

### 2. Toggle is a Public Route
In a real production system, only developers would toggle flags. In this project, the Flutter app can also toggle flags — this is intentional for **demo purposes** to make it easy for evaluators to test real-time sync from both sides.

### 3. Archive vs Delete
Deleting a flag is permanent. Archiving hides it from clients but keeps it in storage — useful for temporarily disabling a feature without losing its configuration. This mirrors how real feature flag systems like LaunchDarkly handle flag retirement.

### 4. Consistent Percentage Hashing
Percentage rollouts use `hashlib.md5` to hash the `user_id` — this ensures the same user always gets the same result. Unlike random assignment, a user won't flip between seeing and not seeing a feature on every request.

### 5. Separate Routes for TUI and Flutter
`GET /flags` (public) returns only non-archived flags — used by Flutter.
`GET /flags/all` (protected) returns everything including archived — used by TUI.
This separation ensures the developer always has full visibility while end users only see relevant flags.

### 6. WebSocket Fallback
If WebSocket connection fails, both the TUI and Flutter app auto-retry every 3 seconds. As a last resort fallback, polling `GET /flags` every few seconds would also work — real-time push is better but the system degrades gracefully.

---

## 👥 Team

| Person | Role |
|---|---|
| Naman Awana (Person A) | Python Backend + Textual Terminal UI + WebSocket Server |
| Palakpreet Kaur (Person B) | Flutter Client App  |

---

## 📚 Resources Used

- [FastAPI Official Docs](https://fastapi.tiangolo.com/tutorial/)
- [FastAPI WebSockets Guide](https://fastapi.tiangolo.com/advanced/websockets/)
- [Textual Getting Started](https://textual.textualize.io/guide/app/)
- [Flutter WebSocket Cookbook](https://docs.flutter.dev/cookbook/networking/web-sockets)
- [Pydantic Docs](https://docs.pydantic.dev)