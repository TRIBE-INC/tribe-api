const { getInsights } = require('../examples/insights');
const { trackEvent } = require('../examples/events');
const { searchKnowledgeBase } = require('../examples/knowledge-base');
const { trackBatchEvents } = require('../examples/batch-events');

const API_KEY = process.env.TRIBE_API_KEY;
const API_BASE = process.env.TRIBE_API_BASE || 'https://tribecode.ai/api';

async function runTests() {
  console.log('🧪 TRIBE API Test Suite\n');
  console.log(`Testing API at: ${API_BASE}`);
  console.log(`API Key: ${API_KEY ? 'Set ✓' : 'Not Set ✗'}\n`);

  if (!API_KEY || API_KEY === 'your_api_key_here') {
    console.error('❌ ERROR: TRIBE_API_KEY environment variable not set');
    console.log('\nTo run tests, set your API key:');
    console.log('export TRIBE_API_KEY="sk_live_your_key_here"\n');
    process.exit(1);
  }

  const results = {
    passed: 0,
    failed: 0,
    tests: []
  };

  async function test(name, fn) {
    process.stdout.write(`Testing ${name}... `);
    try {
      await fn();
      console.log('✅ PASS');
      results.passed++;
      results.tests.push({ name, status: 'PASS' });
    } catch (error) {
      console.log('❌ FAIL');
      console.error(`  Error: ${error.message}\n`);
      results.failed++;
      results.tests.push({ name, status: 'FAIL', error: error.message });
    }
  }

  await test('Get Insights', async () => {
    const data = await getInsights();
    if (!data.insights || !Array.isArray(data.insights)) {
      throw new Error('Invalid response structure');
    }
  });

  await test('Track Event', async () => {
    const data = await trackEvent();
    if (!data.success || !data.event_id) {
      throw new Error('Event tracking failed');
    }
  });

  await test('Search Knowledge Base', async () => {
    const data = await searchKnowledgeBase('oauth');
    if (!data.articles || !Array.isArray(data.articles)) {
      throw new Error('Invalid response structure');
    }
  });

  await test('Track Batch Events', async () => {
    const data = await trackBatchEvents();
    if (!data.success || data.processed === 0) {
      throw new Error('Batch event tracking failed');
    }
  });

  console.log('\n' + '='.repeat(50));
  console.log('Test Results:');
  console.log(`  Passed: ${results.passed}`);
  console.log(`  Failed: ${results.failed}`);
  console.log(`  Total:  ${results.passed + results.failed}`);
  console.log('='.repeat(50) + '\n');

  if (results.failed > 0) {
    console.log('Failed tests:');
    results.tests
      .filter(t => t.status === 'FAIL')
      .forEach(t => console.log(`  - ${t.name}: ${t.error}`));
    console.log();
    process.exit(1);
  }

  console.log('✅ All tests passed!\n');
  process.exit(0);
}

if (require.main === module) {
  runTests().catch(err => {
    console.error('Test suite failed:', err);
    process.exit(1);
  });
}

module.exports = { runTests };
