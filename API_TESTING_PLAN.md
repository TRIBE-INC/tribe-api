# TRIBE API Testing Plan

**Date**: 2025-10-07
**Purpose**: Test all existing tribe-api examples to verify they work correctly with production endpoints

---

## Examples to Test

Based on the current tribe-api repository, we have **4 working examples**:

1. `examples/insights.js` - Fetch analytics insights
2. `examples/events.js` - Track custom events
3. `examples/batch-events.js` - Track multiple events efficiently
4. `examples/knowledge-base.js` - Search knowledge base articles

---

## Test Environment

### Production Endpoints
All examples use `https://tribecode.ai/api` as the base URL:

- **Analytics Insights**: `https://tribecode.ai/api/analytics/insights`
- **Analytics Events**: `https://tribecode.ai/api/analytics/events`
- **Batch Events**: `https://tribecode.ai/api/analytics/events/batch`
- **Knowledge Base**: `https://tribecode.ai/api/knowledge-base/articles`

### Test API Key
Using a valid production API key (obtain from https://tribecode.ai/tribe/settings/api-keys)

---

## Test Cases

### Test 1: Analytics Insights (insights.js)

**Endpoint**: `GET https://tribecode.ai/api/analytics/insights`

**Expected Behavior**:
- Accepts API key via Authorization header
- Returns array of insights
- Each insight has: id, user_id, recommendation, provider, event_scores

**Test Script**:
```bash
export TRIBE_API_KEY="your_api_key_here"
node examples/insights.js
```

**Success Criteria**:
- [ ] Script runs without errors
- [ ] Returns valid JSON response
- [ ] Response contains `insights` array
- [ ] Each insight has required fields
- [ ] Exit code 0

**Failure Scenarios to Test**:
- [ ] Invalid API key returns 401
- [ ] Missing API key returns 401
- [ ] Malformed request returns 400

---

### Test 2: Track Events (events.js)

**Endpoint**: `POST https://tribecode.ai/api/analytics/events`

**Expected Behavior**:
- Accepts API key via Authorization header
- Accepts event data in request body
- Returns success confirmation
- Event is stored and retrievable

**Test Script**:
```bash
export TRIBE_API_KEY="your_api_key_here"
node examples/events.js
```

**Success Criteria**:
- [ ] Script runs without errors
- [ ] Returns success response
- [ ] Event data is accepted
- [ ] Exit code 0

**Failure Scenarios to Test**:
- [ ] Invalid API key returns 401
- [ ] Missing required fields returns 400
- [ ] Invalid event type returns 400

---

### Test 3: Batch Events (batch-events.js)

**Endpoint**: `POST https://tribecode.ai/api/analytics/events/batch`

**Expected Behavior**:
- Accepts API key via Authorization header
- Accepts array of events in request body
- Returns success with count of processed events
- All events are stored

**Test Script**:
```bash
export TRIBE_API_KEY="your_api_key_here"
node examples/batch-events.js
```

**Success Criteria**:
- [ ] Script runs without errors
- [ ] Returns success response
- [ ] Batch processing confirmed
- [ ] Event count matches request
- [ ] Exit code 0

**Failure Scenarios to Test**:
- [ ] Invalid API key returns 401
- [ ] Empty events array returns 400
- [ ] Partial batch failure handling

---

### Test 4: Knowledge Base (knowledge-base.js)

**Endpoint**: `GET https://tribecode.ai/api/knowledge-base/articles`

**Expected Behavior**:
- Accepts API key via Authorization header
- Accepts optional query parameters (search, category)
- Returns array of articles
- Each article has: id, title, content, category

**Test Script**:
```bash
export TRIBE_API_KEY="your_api_key_here"
node examples/knowledge-base.js
```

**Success Criteria**:
- [ ] Script runs without errors
- [ ] Returns valid JSON response
- [ ] Response contains `articles` array
- [ ] Each article has required fields
- [ ] Exit code 0

**Query Parameter Tests**:
- [ ] Search parameter filters results
- [ ] Category parameter filters results
- [ ] Multiple parameters work together

**Failure Scenarios to Test**:
- [ ] Invalid API key returns 401
- [ ] Invalid query parameters handled gracefully

---

## Testing Methodology

### Phase 1: Manual Testing
1. Run each example script manually
2. Verify output matches expected format
3. Check for error handling
4. Validate response data structure

### Phase 2: Automated Testing
1. Create test harness script
2. Run all examples programmatically
3. Assert success/failure conditions
4. Generate test report

### Phase 3: Error Scenario Testing
1. Test with invalid API keys
2. Test with missing required fields
3. Test with malformed requests
4. Verify proper error responses

### Phase 4: Integration Testing
1. Test complete workflow (track event → fetch insights)
2. Verify data consistency
3. Test rate limiting (if implemented)
4. Test concurrent requests

---

## Test Execution Plan

### Step 1: Setup
```bash
cd /Users/almorris/TRIBE/tribe-api
npm install
export TRIBE_API_KEY="your_api_key_here"
```

### Step 2: Run Individual Tests
```bash
# Test 1: Insights
node examples/insights.js > test-results/insights.log 2>&1
echo "Exit code: $?" >> test-results/insights.log

# Test 2: Events
node examples/events.js > test-results/events.log 2>&1
echo "Exit code: $?" >> test-results/events.log

# Test 3: Batch Events
node examples/batch-events.js > test-results/batch-events.log 2>&1
echo "Exit code: $?" >> test-results/batch-events.log

# Test 4: Knowledge Base
node examples/knowledge-base.js > test-results/knowledge-base.log 2>&1
echo "Exit code: $?" >> test-results/knowledge-base.log
```

### Step 3: Create Automated Test Runner
Create `test/run-all-tests.js`:
```javascript
const { execSync } = require('child_process');
const examples = ['insights', 'events', 'batch-events', 'knowledge-base'];

async function runTests() {
  const results = [];

  for (const example of examples) {
    try {
      const output = execSync(`node examples/${example}.js`, {
        env: { ...process.env, TRIBE_API_KEY: process.env.TRIBE_API_KEY },
        encoding: 'utf-8',
        timeout: 30000
      });

      results.push({
        name: example,
        status: 'PASS',
        output: output
      });
    } catch (error) {
      results.push({
        name: example,
        status: 'FAIL',
        error: error.message,
        output: error.stdout
      });
    }
  }

  return results;
}
```

### Step 4: Validate Responses
For each test, verify:
1. HTTP status code (200 for success, 401 for auth errors)
2. Response structure matches expected format
3. Required fields are present
4. Data types are correct
5. Error messages are meaningful

---

## Expected Results

### Success Case: All Tests Pass
```
✅ insights.js - PASS
   - Returned 7 insights
   - All required fields present
   - Exit code: 0

✅ events.js - PASS
   - Event tracked successfully
   - Response confirmed
   - Exit code: 0

✅ batch-events.js - PASS
   - 5 events processed
   - Batch confirmed
   - Exit code: 0

✅ knowledge-base.js - PASS
   - Returned 12 articles
   - Search/filter working
   - Exit code: 0

Total: 4/4 PASSED
```

### Failure Case: Authentication Error
```
❌ insights.js - FAIL
   - HTTP 401: Invalid API key
   - Exit code: 1

Expected: Valid authentication required
```

### Failure Case: Endpoint Not Found
```
❌ events.js - FAIL
   - HTTP 404: Endpoint not found
   - Exit code: 1

Expected: Endpoint should exist at /api/analytics/events
```

---

## Validation Criteria

### For Each Example:

**Code Quality**:
- [ ] Uses correct base URL (`https://tribecode.ai/api`)
- [ ] Includes proper error handling
- [ ] Validates API key is set
- [ ] Provides meaningful output
- [ ] Has clear comments

**Functionality**:
- [ ] Connects to production endpoint
- [ ] Sends correct request format
- [ ] Handles success responses
- [ ] Handles error responses
- [ ] Exits with appropriate code

**Documentation**:
- [ ] README explains how to run
- [ ] Example output shown
- [ ] API key setup documented
- [ ] Error scenarios explained

---

## Known Issues to Document

Based on testing, document:
1. Any endpoints that don't exist
2. Any authentication issues
3. Any response format mismatches
4. Any missing error handling
5. Any rate limiting behavior

---

## Test Report Format

After testing, create `TEST_RESULTS.md`:

```markdown
# TRIBE API Test Results

**Date**: 2025-10-07
**Tester**: Automated test harness
**Environment**: Production (tribecode.ai)

## Summary
- Total Examples: 4
- Passed: X
- Failed: X
- Success Rate: X%

## Detailed Results

### insights.js
**Status**: PASS/FAIL
**Execution Time**: Xs
**Output**: [captured output]
**Issues**: [any issues found]

[... repeat for each example ...]

## Recommendations
1. [Any fixes needed]
2. [Any improvements suggested]
3. [Any documentation updates]
```

---

## Next Steps After Testing

1. **If All Pass**: Document successful test run, update README
2. **If Any Fail**:
   - Document failure details
   - Identify root cause
   - Create GitHub issues for fixes
   - Update examples as needed
3. **Update Documentation**:
   - Add test results to README
   - Update API_REFERENCE.md with working endpoints
   - Add troubleshooting guide

---

## Testing Tools Required

1. **Node.js**: v18+ (for running examples)
2. **npm**: For installing dependencies
3. **jq**: For parsing JSON responses in shell scripts
4. **curl**: For manual endpoint testing
5. **Git**: For version control

---

## Safety Considerations

- Use test API key only (not production user keys)
- Don't commit API keys to repository
- Rate limit testing to avoid overload
- Clean up test data after testing
- Use separate test user account if available

---

*Test plan created: 2025-10-07*
*Ready for execution*
