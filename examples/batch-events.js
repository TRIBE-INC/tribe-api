const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'https://tribecode.ai/api';

async function trackBatchEvents() {
  try {
    const events = [
      {
        event_name: 'page_view',
        event_data: { page: '/dashboard', user_agent: 'API-Example' },
        timestamp: new Date().toISOString()
      },
      {
        event_name: 'button_click',
        event_data: { button_id: 'create_project', location: 'header' },
        timestamp: new Date(Date.now() + 1000).toISOString()
      },
      {
        event_name: 'api_call',
        event_data: { endpoint: '/api/projects', method: 'POST', duration_ms: 234 },
        timestamp: new Date(Date.now() + 2000).toISOString()
      }
    ];

    const response = await fetch(`${API_BASE}/analytics/events/batch`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ events })
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    console.log('📊 Batch Events Tracked\n');
    console.log(`Total events sent: ${events.length}`);
    console.log(`Successfully processed: ${data.processed}`);
    console.log(`Failed: ${data.failed}\n`);

    if (data.success) {
      console.log('✅ All events tracked successfully');
    } else {
      console.log('⚠️  Some events failed to track');
    }

    return data;
  } catch (error) {
    console.error('❌ Error tracking batch events:', error.message);
    throw error;
  }
}

if (require.main === module) {
  trackBatchEvents()
    .then(() => console.log('\n✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { trackBatchEvents };
