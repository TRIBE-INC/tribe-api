// Example: Fetching analytics insights from TRIBE API

const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'https://tribecode.ai/api';

async function getInsights() {
  try {
    const response = await fetch(`${API_BASE}/analytics/insights`, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    console.log('📊 TRIBE Analytics Insights\n');
    console.log(`Total insights: ${data.insights.length}`);
    console.log(`Unread: ${data.unreadCount}\n`);

    data.insights.forEach((insight, index) => {
      console.log(`${index + 1}. ${insight.title}`);
      console.log(`   Category: ${insight.category} | Priority: ${insight.priority}`);
      console.log(`   ${insight.description}`);
      console.log(`   Created: ${new Date(insight.created_at).toLocaleDateString()}\n`);
    });

    return data;
  } catch (error) {
    console.error('❌ Error fetching insights:', error.message);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  getInsights()
    .then(() => console.log('✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { getInsights };
