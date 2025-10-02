const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'https://tribecode.ai/api';

async function trackEvent() {
  try {
    const response = await fetch(`${API_BASE}/analytics/events`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        event_name: 'api_example_event',
        event_data: {
          action: 'test_event',
          timestamp: new Date().toISOString()
        },
        metadata: {
          source: 'tribe-api-example',
          version: '1.0.0'
        }
      })
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    console.log('📡 Event Tracked Successfully\n');
    console.log(`Event ID: ${data.event_id}`);
    console.log(`Status: ${data.success ? 'Success' : 'Failed'}\n`);

    return data;
  } catch (error) {
    console.error('❌ Error tracking event:', error.message);
    throw error;
  }
}

if (require.main === module) {
  trackEvent()
    .then(() => console.log('✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { trackEvent };
