// Example: Generate AI-powered insight from TRIBE Tutor API

const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'http://localhost:8080';

async function generateInsight(options = {}) {
  const {
    insightType = 'usage_analysis',
    timePeriod = '7d',
    focusArea = 'productivity'
  } = options;

  try {
    const response = await fetch(`${API_BASE}/api/insights/generate`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        insight_type: insightType,
        time_period: timePeriod,
        metadata: {
          focus_area: focusArea
        }
      })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API error: ${response.status} - ${error}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error('Insight generation failed');
    }

    console.log('🤖 AI-Powered Insight Generated\n');
    console.log(`Title: ${data.insight.title}`);
    console.log(`Provider: ${data.insight.provider}`);
    console.log(`Description: ${data.insight.description}\n`);
    console.log(`📊 Analysis:`);
    console.log(`   ${data.insight.value}\n`);
    console.log(`💡 Recommendation:`);
    console.log(`   ${data.insight.recommendation}\n`);

    if (data.insight.event_scores && data.insight.event_scores.length > 0) {
      console.log(`🎯 Event Scores (${data.insight.event_scores.length} events):`);
      data.insight.event_scores.slice(0, 5).forEach(score => {
        console.log(`   Event ${score.event_id}: relevance ${score.relevance}/10`);
      });
      if (data.insight.event_scores.length > 5) {
        console.log(`   ... and ${data.insight.event_scores.length - 5} more`);
      }
    }

    return data;
  } catch (error) {
    console.error('❌ Error generating insight:', error.message);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  generateInsight({
    insightType: 'usage_analysis',
    timePeriod: '7d',
    focusArea: 'code_quality'
  })
    .then(() => console.log('\n✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { generateInsight };
