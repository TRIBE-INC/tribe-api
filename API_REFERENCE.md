# TRIBE Tutor API Reference

**Base URL:** `http://localhost:8080`

**Authentication:** API Key (Bearer token)

---

## Authentication

All API endpoints require authentication via API key in the `Authorization` header:

```http
Authorization: Bearer sk_live_your_key_here
```

### API Key Formats

- **Live keys:** `sk_live_...` (64 characters)
- **Test keys:** `sk_test_...` (64 characters)

### Security

- API keys are stored as SHA256 hashes in the database
- User identity is **enforced** from the API key (request body values are ignored)
- Keys can be set to expire and can be revoked via the `is_active` flag

### Creating API Keys

API keys must be created directly in the database:

```sql
-- Insert new API key
INSERT INTO api_keys (key_hash, user_id, name, expires_at) VALUES (
  encode(sha256('sk_live_your_actual_key'::bytea), 'hex'),
  'user_uuid',
  'My API Key',
  NOW() + INTERVAL '90 days'  -- Optional expiration
);

-- Revoke an API key
UPDATE api_keys SET is_active = false WHERE id = 'key_uuid';
```

---

## Endpoints

### Generate AI Insight

Generate AI-powered insights from user telemetry data using Kimi AI.

**Endpoint:** `POST /api/insights/generate`

**Headers:**
```http
Authorization: Bearer sk_live_...
Content-Type: application/json
```

**Request Body:**
```json
{
  "insight_type": "usage_analysis",
  "time_period": "7d",
  "metadata": {
    "focus_area": "productivity"
  }
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `insight_type` | string | Yes | Type of insight to generate (e.g., `usage_analysis`) |
| `time_period` | string | Yes | Time period for analysis (e.g., `7d`, `30d`, `90d`) |
| `metadata` | object | No | Additional metadata for insight generation |
| `metadata.focus_area` | string | No | Specific area to focus analysis on |

**Response:**
```json
{
  "success": true,
  "insight": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "0b49700d-3097-47ca-b0c9-8deeb3d10260",
    "provider": "kimi",
    "title": "Weekly Usage Analysis",
    "description": "AI-powered analysis of your coding patterns",
    "value": "Analyzed 500 events across 7 days",
    "recommendation": "Consider breaking down large tasks into smaller commits for better tracking",
    "event_scores": [
      {
        "event_id": 0,
        "relevance": 8
      },
      {
        "event_id": 15,
        "relevance": 7
      }
    ],
    "created_at": "2025-10-03T21:21:11Z"
  },
  "user_id": "0b49700d-3097-47ca-b0c9-8deeb3d10260"
}
```

**Event Scoring:**
- The AI assigns a relevance score (1-10) to each analyzed event
- Higher scores indicate events that had more impact on the insight
- Scores help identify key moments in your workflow

**Error Responses:**

```json
// Invalid API key
{
  "error": "Unauthorized",
  "message": "Invalid or expired API key"
}
// Status: 401 Unauthorized

// Missing required fields
{
  "error": "Bad Request",
  "message": "Missing required field: insight_type"
}
// Status: 400 Bad Request
```

---

### Ingest Telemetry Events

Ingest telemetry events from your development tools (e.g., Claude Code).

**Endpoint:** `POST /api/telemetry/ingest`

**Headers:**
```http
Authorization: Bearer sk_live_...
Content-Type: application/json
```

**Request Body:**
```json
{
  "events": [
    {
      "event_type": "user",
      "tool": "claude_code",
      "project_path": "/Users/username/my-project",
      "message_text": "Refactored authentication module",
      "data": {
        "files_changed": 3,
        "lines_added": 145,
        "lines_removed": 67
      }
    }
  ]
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `events` | array | Yes | Array of telemetry events to ingest |
| `events[].event_type` | string | Yes | Type of event (`user`, `assistant`, `summary`) |
| `events[].tool` | string | Yes | Tool that generated the event (e.g., `claude_code`) |
| `events[].project_path` | string | Yes | Path to the project |
| `events[].message_text` | string | No | Human-readable event description |
| `events[].data` | object | No | Additional event metadata (arbitrary JSON) |

**Security Note:**
- The `user_id` and `team_id` fields in the request body are **ignored**
- User identity is enforced from the authenticated API key
- This prevents user impersonation attacks

**Response:**
```json
{
  "success": true,
  "events_processed": 1,
  "user_id": "0b49700d-3097-47ca-b0c9-8deeb3d10260"
}
```

**Error Responses:**

```json
// Invalid API key
{
  "error": "Unauthorized",
  "message": "Invalid or expired API key"
}
// Status: 401 Unauthorized

// Empty events array
{
  "error": "Bad Request",
  "message": "No events provided"
}
// Status: 400 Bad Request
```

---

### Health Check

Check API availability.

**Endpoint:** `GET /api/health`

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-03T21:00:00Z"
}
```

---

## Event Types

### User Events
User-initiated actions in the development environment.

**Example:**
```json
{
  "event_type": "user",
  "tool": "claude_code",
  "project_path": "/Users/username/my-project",
  "message_text": "Fix authentication bug in login flow"
}
```

### Assistant Events
AI assistant responses and code generation.

**Example:**
```json
{
  "event_type": "assistant",
  "tool": "claude_code",
  "project_path": "/Users/username/my-project",
  "message_text": "Created LoginForm component with validation",
  "data": {
    "component": "LoginForm.tsx",
    "framework": "React",
    "lines_generated": 87
  }
}
```

### Summary Events
High-level task or session summaries.

**Example:**
```json
{
  "event_type": "summary",
  "tool": "claude_code",
  "project_path": "/Users/username/my-project",
  "message_text": "Completed authentication feature implementation",
  "data": {
    "feature": "authentication",
    "status": "completed",
    "duration_minutes": 45
  }
}
```

---

## Rate Limiting

**Current Status:** No rate limiting implemented

**Recommended:** Implement rate limiting based on API key:
- 100 requests per minute for event ingestion
- 10 requests per minute for insight generation (AI is expensive)

---

## Error Codes

| HTTP Status | Error Type | Description |
|-------------|------------|-------------|
| 200 | Success | Request completed successfully |
| 400 | Bad Request | Missing or invalid parameters |
| 401 | Unauthorized | Invalid or expired API key |
| 403 | Forbidden | API key lacks required permissions |
| 404 | Not Found | Endpoint does not exist |
| 429 | Too Many Requests | Rate limit exceeded (future) |
| 500 | Internal Server Error | Server-side error occurred |

---

## Examples

See the `/examples` directory for complete working examples:

- **generate-insight.js** - Generate AI insights
- **ingest-events.js** - Batch event ingestion
- **insights.js** - Fetch existing insights
- **events.js** - Track custom events

Run examples:
```bash
export TRIBE_API_KEY="sk_live_your_key_here"
export TRIBE_API_BASE="http://localhost:8080"

node examples/generate-insight.js
node examples/ingest-events.js
```

---

## Support

- **Issues:** https://github.com/TRIBE-INC/tribe-api/issues
- **Documentation:** https://tribecode.ai/docs

---

*Last Updated: 2025-10-04*
*API Version: 1.0*
*Kimi AI Integration: Active*
