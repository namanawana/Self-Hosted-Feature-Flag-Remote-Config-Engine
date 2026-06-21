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