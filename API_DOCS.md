# API Documentation

Base URL: `http://localhost:8000`

---

## Authentication

Some routes are protected and require an API key set in the request header:

```
x-api-key: your_api_key_here
```

The API key is defined in the backend `.env` file as `API_KEY`.

| Access Level | Routes |
|---|---|
| **Public** (no key needed) | `GET /flags`, `GET /flags/all`, `GET /flags/archived`, `GET /flags/stats`, `PATCH /flags/{name}/toggle`, `GET /config`, `POST /evaluate`, `GET /health`, `WS /ws` |
| **Protected** (key required) | `POST /flags`, `PATCH /flags/{name}/archive`, `DELETE /flags/{name}`, `POST /config`, `PATCH /config/{key}`, `DELETE /config/{key}` |

---

## Data Models

### FeatureFlag

```json
{
  "name": "dark_mode",
  "enabled": true,
  "environment": "production",
  "rule_type": "everyone",
  "rule_value": null,
  "archived": false
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Unique identifier for the flag |
| `enabled` | boolean | Yes | Whether the flag is ON or OFF |
| `environment` | string | Yes | e.g. `"production"` or `"development"` |
| `rule_type` | string | Yes | One of: `"everyone"`, `"beta_only"`, `"percentage"` |
| `rule_value` | list\|int\|null | No | Depends on `rule_type` (see below) |
| `archived` | boolean | No | Defaults to `false`. Archived flags are hidden from `/flags` |

**rule_type and rule_value combinations:**

| rule_type | rule_value type | Example |
|---|---|---|
| `"everyone"` | `null` | `null` |
| `"beta_only"` | list of strings | `["naman", "palak", "user1"]` |
| `"percentage"` | integer (0–100) | `15` |

### ConfigVar

```json
{
  "key": "welcome_message",
  "value": "Welcome to our app!",
  "description": "Shown on the home screen when user opens the app"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `key` | string | Yes | Unique key identifier |
| `value` | string | Yes | The config value (always stored as string) |
| `description` | string | No | Human-readable description, defaults to `""` |

---

## Feature Flags

### GET /flags
Returns all **active** (non-archived) feature flags.

**Auth required:** No

**Response:** `200 OK`
```json
[
  {
    "name": "dark_mode",
    "enabled": true,
    "environment": "production",
    "rule_type": "everyone",
    "rule_value": null,
    "archived": false
  },
  {
    "name": "new_checkout_flow",
    "enabled": true,
    "environment": "production",
    "rule_type": "beta_only",
    "rule_value": ["naman", "palak", "user1"],
    "archived": false
  }
]
```

---

### GET /flags/all
Returns **all** flags — including archived ones. Used by the developer TUI.

**Auth required:** No

**Response:** `200 OK` — same format as `GET /flags` but includes flags where `archived: true`.

---

### GET /flags/archived
Returns only archived flags.

**Auth required:** No

**Response:** `200 OK`
```json
[
  {
    "name": "old_feature",
    "enabled": false,
    "environment": "production",
    "rule_type": "everyone",
    "rule_value": null,
    "archived": true
  }
]
```

---

### GET /flags/stats
Returns a summary count of all flags.

**Auth required:** No

**Response:** `200 OK`
```json
{
  "total": 3,
  "enabled": 2,
  "disabled": 1
}
```

> **Note:** Counts include archived flags.

---

### POST /flags
Creates a new feature flag.

**Auth required:** Yes

**Request Body:**
```json
{
  "name": "ai_recommendations",
  "enabled": false,
  "environment": "production",
  "rule_type": "percentage",
  "rule_value": 15
}
```

**Response:** `200 OK` — returns the created flag object.

**Errors:**
- `409 Conflict` — a flag with this name already exists
- `401 Unauthorized` — missing or invalid API key
- `422 Unprocessable Entity` — missing required fields

**WebSocket broadcast on success:**
```json
{
  "type": "flag_created",
  "flag": { ...flag object... }
}
```

---

### PATCH /flags/{name}/toggle
Toggles a flag's `enabled` status (`true` → `false` or `false` → `true`).

**Auth required:** No

**URL Parameter:** `name` — the flag name (e.g. `dark_mode`)

**Response:** `200 OK` — returns the updated flag object.
```json
{
  "name": "dark_mode",
  "enabled": false,
  "environment": "production",
  "rule_type": "everyone",
  "rule_value": null,
  "archived": false
}
```

**Errors:**
- `404 Not Found` — flag doesn't exist

**WebSocket broadcast on success:**
```json
{
  "type": "flag_updated",
  "flag": { ...updated flag object... }
}
```

---

### PATCH /flags/{name}/archive
Toggles a flag's `archived` status (`false` → `true` or `true` → `false`). Archiving a flag hides it from `GET /flags` (the client-facing route) while keeping it visible in `GET /flags/all` (the TUI route).

**Auth required:** Yes

**URL Parameter:** `name` — the flag name

**Response:** `200 OK` — returns the updated flag object.

**Errors:**
- `404 Not Found` — flag doesn't exist
- `401 Unauthorized` — missing or invalid API key

**WebSocket broadcast on success:**
```json
{
  "type": "flag_archived",
  "flag": { ...updated flag object... }
}
```

---

### DELETE /flags/{name}
Permanently deletes a flag. This cannot be undone.

**Auth required:** Yes

**URL Parameter:** `name` — the flag name

**Response:** `200 OK`
```json
{
  "message": "Flag 'dark_mode' deleted",
  "flag": true
}
```

**Errors:**
- `404 Not Found` — flag doesn't exist
- `401 Unauthorized` — missing or invalid API key

**WebSocket broadcast on success:**
```json
{
  "type": "flag-deleted",
  "flag_name": "dark_mode"
}
```

---

## Config Variables

### GET /config
Returns all remote config key-value pairs.

**Auth required:** No

**Response:** `200 OK`
```json
[
  {
    "key": "welcome_message",
    "value": "Welcome to our app!",
    "description": "Shown on the home screen when user opens the app"
  },
  {
    "key": "max_login_attempts",
    "value": "5",
    "description": "Maximum number of failed login attempts before lockout"
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
  "key": "support_email",
  "value": "support@example.com",
  "description": "Support email shown in the help section"
}
```

**Response:** `200 OK` — returns the created config object.

**Errors:**
- `409 Conflict` — a config with this key already exists
- `401 Unauthorized` — missing or invalid API key
- `422 Unprocessable Entity` — missing required fields

---

### PATCH /config/{key}
Updates the value of an existing config variable.

**Auth required:** Yes

**URL Parameter:** `key` — the config key (e.g. `welcome_message`)

**Request Body:**
```json
{
  "value": "Hey there! Welcome back."
}
```

**Response:** `200 OK` — returns the updated config object.
```json
{
  "key": "welcome_message",
  "value": "Hey there! Welcome back.",
  "description": "Shown on the home screen when user opens the app"
}
```

**Errors:**
- `404 Not Found` — config doesn't exist
- `401 Unauthorized` — missing or invalid API key

---

### DELETE /config/{key}
Permanently deletes a config variable.

**Auth required:** Yes

**URL Parameter:** `key` — the config key

**Response:** `200 OK`
```json
{
  "message": "Config 'support_email' deleted",
  "config": {
    "key": "support_email",
    "value": "support@example.com",
    "description": "Support email shown in the help section"
  }
}
```

**Errors:**
- `404 Not Found` — config doesn't exist
- `401 Unauthorized` — missing or invalid API key

---

## Evaluate

### POST /evaluate
Returns the list of active flags for a specific user, applying all targeting rules.

**Auth required:** No

**Request Body:**
```json
{
  "user_id": "naman"
}
```

**Response:** `200 OK`
```json
{
  "user_id": "naman",
  "active_flags": ["dark_mode", "new_checkout_flow"]
}
```

**How targeting rules are applied:**

| rule_type | Logic |
|---|---|
| `everyone` | Flag is always active for any user (as long as `enabled: true`) |
| `beta_only` | Active only if `user_id` is in the `rule_value` list |
| `percentage` | `user_id` is MD5-hashed → `int(hash, 16) % 100` → active if result `< rule_value` |

> **Consistent hashing:** The same `user_id` will always produce the same outcome for a given percentage threshold. A user in the 15% cohort stays in it on every request.

> **Note:** Archived flags are excluded from evaluation — even if `enabled: true`, an archived flag will never appear in `active_flags`.

---

## Health

### GET /health
Returns server health and storage status.

**Auth required:** No

**Response:** `200 OK`
```json
{
  "status": "OK",
  "flags_loaded": 3,
  "configs_loaded": 3
}
```

---

## WebSocket

### WS /ws
Persistent real-time connection. The server pushes a JSON message to **all** connected clients whenever a flag or config state changes.

**Auth required:** No

**Connection URLs:**
- Local: `ws://localhost:8000/ws`

**Connect (JavaScript example):**
```js
const ws = new WebSocket("ws://localhost:8000/ws");
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log(data.type, data);
};
```

---

### Server → Client Message Types

**Flag created** (`POST /flags` succeeds):
```json
{
  "type": "flag_created",
  "flag": {
    "name": "new_feature",
    "enabled": false,
    "environment": "production",
    "rule_type": "everyone",
    "rule_value": null,
    "archived": false
  }
}
```

**Flag toggled** (`PATCH /flags/{name}/toggle` succeeds):
```json
{
  "type": "flag_updated",
  "flag": {
    "name": "dark_mode",
    "enabled": false,
    "environment": "production",
    "rule_type": "everyone",
    "rule_value": null,
    "archived": false
  }
}
```

**Flag archived/restored** (`PATCH /flags/{name}/archive` succeeds):
```json
{
  "type": "flag_archived",
  "flag": {
    "name": "old_feature",
    "enabled": true,
    "environment": "production",
    "rule_type": "everyone",
    "rule_value": null,
    "archived": true
  }
}
```

**Flag deleted** (`DELETE /flags/{name}` succeeds):
```json
{
  "type": "flag-deleted",
  "flag_name": "old_feature"
}
```

---

## Error Format

All errors return a consistent JSON body:
```json
{
  "detail": "Error message here"
}
```

## HTTP Status Codes

| Code | Meaning |
|---|---|
| `200` | Success |
| `401` | Unauthorized — missing or invalid `x-api-key` header |
| `404` | Not Found — flag or config key doesn't exist |
| `409` | Conflict — flag or config with that name/key already exists |
| `422` | Validation Error — request body is missing required fields or has wrong types |
| `500` | Internal Server Error |
