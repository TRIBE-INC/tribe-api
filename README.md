# TRIBE API Examples

Official code examples for using the TRIBE API - working examples you can run immediately.

## 📚 Documentation

**Full API Documentation**: https://tribecode.ai/docs/api

- [API Overview](https://tribecode.ai/docs/api) - Getting started and authentication
- [Quickstart Guide](https://tribecode.ai/docs/api/quickstart) - Step-by-step tutorial
- [Complete API Reference](https://tribecode.ai/docs/api/reference) - All endpoints with examples

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://github.com/TRIBE-INC/tribe-api.git
cd tribe-api

# Install dependencies
npm install

# Set your API key
export TRIBE_API_KEY="sk_live_your_key_here"

# Run examples
npm run example:insights
npm run example:events
npm run example:knowledge-base
```

## 📖 Examples

All examples use the production API at `https://tribecode.ai/api`:

### Working Examples (✅ Production Ready)

- **[insights.js](./examples/insights.js)** - Fetch AI-powered analytics insights from your telemetry data
  - Endpoint: `GET /api/analytics/insights`
  - Returns personalized recommendations based on your coding patterns

- **[events.js](./examples/events.js)** - Retrieve development telemetry events
  - Endpoint: `GET /api/analytics/events`
  - Query and filter your development activity events

- **[knowledge-base.js](./examples/knowledge-base.js)** - Search knowledge base articles
  - Endpoint: `GET /api/knowledge-base/articles`
  - Find best practices and documentation

### CLI-Only Examples

- **[batch-events.js](./examples/batch-events.js)** - Track multiple events efficiently (write operations)

## 🔑 Authentication

Get your API key from the dashboard:

1. Go to https://tribecode.ai/tribe/settings/api-keys
2. Click "Generate New Key"
3. Copy and save your key securely

Your API key format: `sk_live_xxxxx` or `sk_test_xxxxx`

## 🛠️ API Endpoints

| Method | Endpoint | Description | Example |
|--------|----------|-------------|---------|
| `GET` | `/api/analytics/insights` | Get AI insights | [insights.js](./examples/insights.js) |
| `GET` | `/api/analytics/events` | Retrieve telemetry events | [events.js](./examples/events.js) |
| `GET` | `/api/knowledge-base/articles` | Search articles | [knowledge-base.js](./examples/knowledge-base.js) |

## 📞 Support

- **Documentation**: https://tribecode.ai/docs/api
- **Issues**: https://github.com/TRIBE-INC/tribe-api/issues
- **Email**: api-support@tribecode.ai

## 📝 License

MIT
