# API Documentation

Base URL: `http://localhost:8000`

## GET /flags
Returns all feature flags.

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

## POST /flags
Creates a new feature flag.

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

**Response:** Returns the created flag.

**Errors:**
- `409 Conflict` — flag with this name already exists
---

### PATCH /flags/{name}/toggle
Toggles a flag's enabled status (true → false or false → true).

**URL Parameter:** `name` — the flag name

**Response:** Returns the updated flag.

**Errors:**
- `404 Not Found` — flag with this name doesn't exist

---

### DELETE /flags/{name}
Deletes a flag by name.

**URL Parameter:** `name` — the flag name

**Response:**
```json
{
  "message": "Flag 'dark_mode' deleted",
  "flag": { ...flag object... }
}
```

**Errors:**
- `404 Not Found` — flag with this name doesn't exist

---

### GET /flags/stats
Returns flag counts.

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

---

### PATCH /config/{key}
Updates a config's value.

**URL Parameter:** `key` — the config key

**Request Body:**
```json
{
  "value": "Hey there!"
}
```

**Response:** Returns the updated config.

**Errors:**
- `404 Not Found` — config with this key doesn't exist

---

### DELETE /config/{key}
Deletes a config by key.

**URL Parameter:** `key` — the config key

**Response:**
```json
{
  "message": "Config 'welcome_message' deleted",
  "config": { ...config object... }
}
```

**Errors:**
- `404 Not Found` — config with this key doesn't exist

---