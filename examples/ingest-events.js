// Example: Ingest telemetry events to TRIBE Tutor API

const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'http://localhost:8080';

async function ingestEvents(events) {
  try {
    const response = await fetch(`${API_BASE}/api/telemetry/ingest`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ events })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API error: ${response.status} - ${error}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error('Event ingestion failed');
    }

    console.log('✅ Events ingested successfully\n');
    console.log(`Events processed: ${data.events_processed || events.length}`);
    console.log(`User ID: ${data.user_id}`);

    return data;
  } catch (error) {
    console.error('❌ Error ingesting events:', error.message);
    throw error;
  }
}

// Example: Single event
async function ingestSingleEvent() {
  const event = {
    event_type: 'user',
    tool: 'claude_code',
    project_path: '/Users/username/my-project',
    message_text: 'Refactored authentication module',
    data: {
      files_changed: 3,
      lines_added: 145,
      lines_removed: 67
    }
  };

  return ingestEvents([event]);
}

// Example: Batch events
async function ingestBatchEvents() {
  const events = [
    {
      event_type: 'user',
      tool: 'claude_code',
      project_path: '/Users/username/my-project',
      message_text: 'Added user authentication'
    },
    {
      event_type: 'assistant',
      tool: 'claude_code',
      project_path: '/Users/username/my-project',
      message_text: 'Created login component',
      data: {
        component: 'LoginForm.tsx',
        framework: 'React'
      }
    },
    {
      event_type: 'summary',
      tool: 'claude_code',
      project_path: '/Users/username/my-project',
      message_text: 'Completed authentication feature',
      data: {
        feature: 'authentication',
        status: 'completed'
      }
    }
  ];

  return ingestEvents(events);
}

// Run if called directly
if (require.main === module) {
  console.log('🚀 TRIBE Telemetry Event Ingestion Example\n');

  ingestBatchEvents()
    .then(() => console.log('\n✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { ingestEvents, ingestSingleEvent, ingestBatchEvents };
