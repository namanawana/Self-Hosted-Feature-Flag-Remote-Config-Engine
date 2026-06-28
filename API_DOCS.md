# API Documentation

Base URL: `http://localhost:8000`
Remote URL: `https://landing-traffic-sixteen.ngrok-free.dev`

## Authentication
Protected routes require an API key in the request header:
`x-api-key: your_api_key_here`

Protected routes: POST, PATCH, DELETE (all flags and config routes)
Public routes: GET /flags, GET /config, GET /health, GET /flags/stats, POST /evaluate, WS /ws

---

## Feature Flags

### GET /flags
Returns all feature flags.
**Auth required:** No

**Response:**
```json
[
  {
    "name": "dark_mode",
    "enabled": true,
    "environment": "development",
    "rule_type": "everyone",
    "rule_value": null
  }
]
```

---

### POST /flags
Creates a new feature flag.
**Auth required:** Yes

**Request Body:**
```json
{
  "name": "dark_mode",
  "enabled": false,
  "environment": "development",
  "rule_type": "everyone",
  "rule_value": null
}
```

**rule_type options:**
- `"everyone"` → rule_value: null
- `"beta_only"` → rule_value: ["user1", "user2"]
- `"percentage"` → rule_value: 10 (number 0-100)

**Response:** Returns the created flag.

**Errors:**
- `409 Conflict` — flag with this name already exists
- `401 Unauthorized` — missing or invalid API key

---

### PATCH /flags/{name}/toggle
Toggles a flag's enabled status (true → false or false → true).
**Auth required:** Yes

**URL Parameter:** `name` — the flag name

**Response:** Returns the updated flag.

**Errors:**
- `404 Not Found` — flag doesn't exist
- `401 Unauthorized` — missing or invalid API key

---

### DELETE /flags/{name}
Deletes a flag by name.
**Auth required:** Yes

**URL Parameter:** `name` — the flag name

**Response:**
```json
{
  "message": "Flag 'dark_mode' deleted",
  "flag": { ...flag object... }
}
```

**Errors:**
- `404 Not Found` — flag doesn't exist
- `401 Unauthorized` — missing or invalid API key

---

### GET /flags/stats
Returns flag counts.
**Auth required:** No

**Response:**
```json
{
  "total": 5,
  "enabled": 3,
  "disabled": 2
}
```

---

## Config Variables

### GET /config
Returns all config key-value pairs.
**Auth required:** No

**Response:**
```json
[
  {
    "key": "welcome_message",
    "value": "Hello!",
    "description": "Shown on home screen"
  }
]
```

---

### POST /config
Creates a new config variable.
**Auth required:** Yes

**Request Body:**
```json
{
  "key": "welcome_message",
  "value": "Hello!",
  "description": "Shown on home screen"
}
```

**Response:** Returns the created config.

**Errors:**
- `409 Conflict` — config with this key already exists
- `401 Unauthorized` — missing or invalid API key

---

### PATCH /config/{key}
Updates a config's value.
**Auth required:** Yes

**URL Parameter:** `key` — the config key

**Request Body:**
```json
{
  "value": "Hey there!"
}
```

**Response:** Returns the updated config.

**Errors:**
- `404 Not Found` — config doesn't exist
- `401 Unauthorized` — missing or invalid API key

---

### DELETE /config/{key}
Deletes a config by key.
**Auth required:** Yes

**URL Parameter:** `key` — the config key

**Response:**
```json
{
  "message": "Config 'welcome_message' deleted",
  "config": { ...config object... }
}
```

**Errors:**
- `404 Not Found` — config doesn't exist
- `401 Unauthorized` — missing or invalid API key

---

## Evaluate

### POST /evaluate
Returns active flags for a specific user based on targeting rules.
**Auth required:** No

**Request Body:**
```json
{
  "user_id": "naman_07"
}
```

**Response:**
```json
{
  "user_id": "naman_07",
  "active_flags": ["dark_mode", "new_checkout_flow"]
}
```

**How rules work:**
- `everyone` → flag always active for all users
- `beta_only` → active only if user_id is in rule_value list
- `percentage` → user_id is hashed consistently, active if hash % 100 < rule_value

---

## Health

### GET /health
Returns server health status.
**Auth required:** No

**Response:**
```json
{
  "status": "ok",
  "flags_loaded": 5,
  "configs_loaded": 3
}
```

---

## WebSocket

### WS /ws
Real-time connection. Server pushes flag updates to all connected clients instantly.
**Auth required:** No

**Connection URLs:**
- Local: `ws://localhost:8000/ws`
- Remote: `ws://landing-traffic-sixteen.ngrok-free.dev/ws`

**Message format (server → client):**

Flag created:
```json
{
  "type": "flag_created",
  "flag": { ...flag object... }
}
```

Flag toggled:
```json
{
  "type": "flag_updated",
  "flag": { ...flag object... }
}
```

Flag deleted:
```json
{
  "type": "flag_deleted",
  "flag_name": "dark_mode"
}
```

---

## Error Format
All errors return consistent JSON:
```json
{
  "detail": "error message here"
}
```

## Status Codes Used
| Code | Meaning |
|---|---|
| 200 | Success |
| 401 | Unauthorized — invalid/missing API key |
| 404 | Not Found — flag or config doesn't exist |
| 409 | Conflict — flag or config already exists |
| 422 | Validation Error — missing required fields |
| 500 | Internal Server Error |