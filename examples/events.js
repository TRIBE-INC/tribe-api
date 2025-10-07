// Example: Fetch telemetry events from TRIBE API

const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'https://tribecode.ai/api';

async function fetchEvents(options = {}) {
  const {
    project = 'all',
    eventType = 'all',
    timeRange = 'all',
    limit = 100
  } = options;

  try {
    const params = new URLSearchParams({
      project,
      eventType,
      timeRange,
      limit: limit.toString()
    });

    const response = await fetch(`${API_BASE}/analytics/events?${params}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API error: ${response.status} - ${error}`);
    }

    const data = await response.json();

    console.log('📊 Telemetry Events\n');
    console.log(`Total events: ${data.totalCount || 0}`);
    console.log(`Events retrieved: ${data.events?.length || 0}`);

    if (data.stats) {
      console.log('\nStats:');
      console.log(`  Projects: ${data.stats.projects || 0}`);
      console.log(`  Tools used: ${data.stats.toolsUsed || 0}`);
      console.log(`  Total tokens: ${data.stats.totalTokens || 0}`);
    }

    if (data.events && data.events.length > 0) {
      console.log('\nRecent events:');
      data.events.slice(0, 5).forEach((event, i) => {
        const time = new Date(event.time).toLocaleString();
        console.log(`\n${i + 1}. ${event.event_type || 'Unknown'}`);
        console.log(`   Tool: ${event.tool || 'N/A'}`);
        console.log(`   Project: ${event.project_path || 'N/A'}`);
        console.log(`   Time: ${time}`);
      });

      if (data.events.length > 5) {
        console.log(`\n... and ${data.events.length - 5} more events`);
      }
    }

    return data;
  } catch (error) {
    console.error('❌ Error fetching events:', error.message);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  fetchEvents({
    timeRange: '7d',
    limit: 100
  })
    .then(() => console.log('\n✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { fetchEvents };
