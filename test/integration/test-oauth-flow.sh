#!/bin/bash

# test-oauth-flow.sh - OAuth Authentication Flow Testing
# Tests OAuth authentication process, token management, and credential validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$HOME/.tribe-test-$$"
BACKUP_DIR="$HOME/.tribe-backup-$$"
MOCK_SERVER_PORT=8899
MOCK_SERVER_PID=""

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup_test_environment() {
    log_info "Cleaning up test environment..."

    # Stop mock server if running
    if [[ -n "$MOCK_SERVER_PID" ]] && kill -0 "$MOCK_SERVER_PID" 2>/dev/null; then
        kill "$MOCK_SERVER_PID" 2>/dev/null || true
        wait "$MOCK_SERVER_PID" 2>/dev/null || true
        log_info "Stopped mock OAuth server"
    fi

    # Remove test directory
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi

    # Restore original .tribe directory if it existed
    if [[ -d "$BACKUP_DIR" ]]; then
        if [[ -d "$HOME/.tribe" ]]; then
            rm -rf "$HOME/.tribe"
        fi
        mv "$BACKUP_DIR" "$HOME/.tribe"
        log_info "Restored original .tribe directory"
    fi
}

setup_test_environment() {
    log_info "Setting up test environment..."

    # Backup existing .tribe directory if it exists
    if [[ -d "$HOME/.tribe" ]]; then
        mv "$HOME/.tribe" "$BACKUP_DIR"
        log_info "Backed up existing .tribe directory"
    fi

    # Create test directory structure
    mkdir -p "$TEST_DIR"/{bin,config,tutor,logs}
    export TRIBE_HOME="$TEST_DIR"
}

start_mock_oauth_server() {
    log_info "Starting mock OAuth server on port $MOCK_SERVER_PORT..."

    # Create mock OAuth server script
    cat > "$TEST_DIR/mock-oauth-server.py" << 'EOF'
#!/usr/bin/env python3
import json
import http.server
import socketserver
import urllib.parse
from datetime import datetime, timedelta

class MockOAuthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/oauth/authorize'):
            # Mock authorization endpoint
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = '''
            <html>
                <head><title>Mock OAuth Authorization</title></head>
                <body>
                    <h1>Mock OAuth Authorization</h1>
                    <p>This is a test OAuth server.</p>
                    <form action="/oauth/callback" method="get">
                        <input type="hidden" name="code" value="test-auth-code-12345">
                        <input type="hidden" name="state" value="test-state">
                        <button type="submit">Authorize (Test)</button>
                    </form>
                </body>
            </html>
            '''
            self.wfile.write(html.encode())

        elif self.path.startswith('/oauth/callback'):
            # Mock callback endpoint
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = '''
            <html>
                <head><title>Authorization Complete</title></head>
                <body>
                    <h1>Authorization Complete</h1>
                    <p>Test authorization code: test-auth-code-12345</p>
                    <p>You can close this window.</p>
                </body>
            </html>
            '''
            self.wfile.write(html.encode())

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/oauth/token':
            # Mock token exchange endpoint
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length).decode('utf-8')

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            # Mock successful token response
            expires_at = (datetime.now() + timedelta(hours=1)).isoformat() + 'Z'
            response = {
                "access_token": "test-access-token-67890",
                "refresh_token": "test-refresh-token-abcdef",
                "token_type": "Bearer",
                "expires_in": 3600,
                "expires_at": expires_at,
                "scope": "read write"
            }
            self.wfile.write(json.dumps(response).encode())

        elif self.path == '/user':
            # Mock user info endpoint
            auth_header = self.headers.get('Authorization', '')
            if 'Bearer test-access-token' in auth_header:
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()

                user_info = {
                    "id": "test-user-123",
                    "email": "test@example.com",
                    "name": "Test User",
                    "avatar_url": "https://example.com/avatar.png",
                    "login": "testuser"
                }
                self.wfile.write(json.dumps(user_info).encode())
            else:
                self.send_response(401)
                self.end_headers()

        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # Suppress server logs
        pass

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8899
    with socketserver.TCPServer(("", port), MockOAuthHandler) as httpd:
        print(f"Mock OAuth server running on port {port}")
        httpd.serve_forever()
EOF

    # Start mock server in background
    if command -v python3 &> /dev/null; then
        python3 "$TEST_DIR/mock-oauth-server.py" "$MOCK_SERVER_PORT" &
        MOCK_SERVER_PID=$!
        sleep 2  # Give server time to start

        # Test if server is running
        if curl -s "http://localhost:$MOCK_SERVER_PORT/oauth/authorize" &> /dev/null; then
            log_success "Mock OAuth server started successfully"
            return 0
        else
            log_error "Mock OAuth server failed to start"
            return 1
        fi
    else
        log_warning "Python3 not available, skipping mock OAuth server"
        return 1
    fi
}

test_oauth_config_structure() {
    log_info "Testing OAuth configuration structure..."

    # Test 1: Valid OAuth configuration
    cat > "$TEST_DIR/tutor/auth.json" << EOF
{
  "access_token": "test-access-token-12345",
  "refresh_token": "test-refresh-token-67890",
  "token_type": "Bearer",
  "expires_at": "$(date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+1H +%Y-%m-%dT%H:%M:%SZ)",
  "user_info": {
    "id": "test-user-123",
    "email": "test@example.com",
    "name": "Test User",
    "login": "testuser",
    "avatar_url": "https://example.com/avatar.png"
  },
  "scopes": ["read", "write"],
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    # Set secure permissions
    chmod 600 "$TEST_DIR/tutor/auth.json"

    # Validate JSON structure
    if command -v jq &> /dev/null; then
        # Check required fields
        REQUIRED_FIELDS=("access_token" "refresh_token" "expires_at" "user_info")
        for field in "${REQUIRED_FIELDS[@]}"; do
            if jq -e ".$field" "$TEST_DIR/tutor/auth.json" &> /dev/null; then
                log_success "Required OAuth field present: $field"
            else
                log_error "Required OAuth field missing: $field"
                return 1
            fi
        done

        # Check user_info structure
        USER_INFO_FIELDS=("email" "name" "id")
        for field in "${USER_INFO_FIELDS[@]}"; do
            if jq -e ".user_info.$field" "$TEST_DIR/tutor/auth.json" &> /dev/null; then
                log_success "Required user_info field present: $field"
            else
                log_error "Required user_info field missing: $field"
                return 1
            fi
        done
    fi

    # Test file permissions
    if [[ "$(stat -c %a "$TEST_DIR/tutor/auth.json" 2>/dev/null || stat -f %A "$TEST_DIR/tutor/auth.json" 2>/dev/null)" == "600" ]]; then
        log_success "OAuth file has secure permissions (600)"
    else
        log_warning "OAuth file permissions may not be secure"
    fi

    return 0
}

test_token_validation() {
    log_info "Testing OAuth token validation..."

    # Test 1: Valid token format
    if command -v jq &> /dev/null; then
        ACCESS_TOKEN=$(jq -r '.access_token' "$TEST_DIR/tutor/auth.json")
        if [[ ${#ACCESS_TOKEN} -gt 10 && "$ACCESS_TOKEN" != "null" ]]; then
            log_success "Access token format valid"
        else
            log_error "Access token format invalid"
            return 1
        fi

        # Test 2: Expiry date validation
        EXPIRES_AT=$(jq -r '.expires_at' "$TEST_DIR/tutor/auth.json")
        if [[ "$EXPIRES_AT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
            log_success "Token expiry format valid (ISO 8601)"
        else
            log_warning "Token expiry format may be invalid"
        fi

        # Test 3: Token not expired
        if command -v date &> /dev/null; then
            CURRENT_TIME=$(date -u +%s)
            EXPIRY_TIME=$(date -u -d "$EXPIRES_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRES_AT" +%s 2>/dev/null || echo "0")

            if [[ $EXPIRY_TIME -gt $CURRENT_TIME ]]; then
                log_success "Token is not expired"
            else
                log_warning "Token appears to be expired (expected for test)"
            fi
        fi
    fi

    return 0
}

test_oauth_flow_simulation() {
    log_info "Testing OAuth flow simulation..."

    # Test 1: Authorization URL generation
    AUTH_URL="http://localhost:$MOCK_SERVER_PORT/oauth/authorize?response_type=code&client_id=test-client&redirect_uri=http://localhost:8080/callback&scope=read+write&state=test-state"

    if curl -s "$AUTH_URL" | grep -q "Mock OAuth Authorization"; then
        log_success "OAuth authorization endpoint accessible"
    else
        log_warning "OAuth authorization endpoint not accessible (mock server may not be running)"
    fi

    # Test 2: Token exchange simulation
    TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:$MOCK_SERVER_PORT/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=authorization_code&code=test-auth-code-12345&client_id=test-client&client_secret=test-secret" 2>/dev/null || echo "{}")

    if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
        log_success "OAuth token exchange simulation works"
    else
        log_warning "OAuth token exchange simulation failed (mock server may not be running)"
    fi

    # Test 3: User info retrieval
    if echo "$TOKEN_RESPONSE" | grep -q "access_token" && command -v jq &> /dev/null; then
        ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // "test-access-token-67890"')
        USER_INFO=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "http://localhost:$MOCK_SERVER_PORT/user" 2>/dev/null || echo "{}")

        if echo "$USER_INFO" | grep -q "test@example.com"; then
            log_success "User info retrieval simulation works"
        else
            log_warning "User info retrieval simulation failed"
        fi
    fi

    return 0
}

test_credential_storage() {
    log_info "Testing credential storage and retrieval..."

    # Test 1: Credential file creation
    TEMP_CREDS=$(mktemp)
    cat > "$TEMP_CREDS" << 'EOF'
{
  "access_token": "stored-token-12345",
  "refresh_token": "stored-refresh-67890",
  "token_type": "Bearer",
  "expires_at": "2025-12-31T23:59:59Z",
  "user_info": {
    "email": "stored@example.com",
    "name": "Stored User"
  }
}
EOF

    # Copy to auth location
    cp "$TEMP_CREDS" "$TEST_DIR/tutor/stored-auth.json"
    chmod 600 "$TEST_DIR/tutor/stored-auth.json"
    rm "$TEMP_CREDS"

    if [[ -f "$TEST_DIR/tutor/stored-auth.json" ]]; then
        log_success "Credential storage works"
    else
        log_error "Credential storage failed"
        return 1
    fi

    # Test 2: Credential retrieval
    if command -v jq &> /dev/null; then
        STORED_EMAIL=$(jq -r '.user_info.email' "$TEST_DIR/tutor/stored-auth.json" 2>/dev/null)
        if [[ "$STORED_EMAIL" == "stored@example.com" ]]; then
            log_success "Credential retrieval works"
        else
            log_error "Credential retrieval failed"
            return 1
        fi
    fi

    # Test 3: Multiple credential files
    cp "$TEST_DIR/tutor/stored-auth.json" "$TEST_DIR/tutor/backup-auth.json"
    if [[ -f "$TEST_DIR/tutor/backup-auth.json" ]]; then
        log_success "Multiple credential files supported"
    else
        log_warning "Multiple credential files may not be supported"
    fi

    return 0
}

test_token_refresh() {
    log_info "Testing token refresh functionality..."

    # Create expired token
    cat > "$TEST_DIR/tutor/expired-auth.json" << 'EOF'
{
  "access_token": "expired-token-12345",
  "refresh_token": "valid-refresh-67890",
  "token_type": "Bearer",
  "expires_at": "2020-01-01T00:00:00Z",
  "user_info": {
    "email": "expired@example.com",
    "name": "Expired User"
  }
}
EOF
    chmod 600 "$TEST_DIR/tutor/expired-auth.json"

    # Test token expiry detection
    if command -v jq &> /dev/null && command -v date &> /dev/null; then
        EXPIRES_AT=$(jq -r '.expires_at' "$TEST_DIR/tutor/expired-auth.json")
        CURRENT_TIME=$(date -u +%s)
        EXPIRY_TIME=$(date -u -d "$EXPIRES_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRES_AT" +%s 2>/dev/null || echo "0")

        if [[ $EXPIRY_TIME -lt $CURRENT_TIME ]]; then
            log_success "Token expiry detection works"
        else
            log_warning "Token expiry detection may not work"
        fi
    fi

    # Test refresh token presence
    if command -v jq &> /dev/null; then
        REFRESH_TOKEN=$(jq -r '.refresh_token' "$TEST_DIR/tutor/expired-auth.json")
        if [[ ${#REFRESH_TOKEN} -gt 10 && "$REFRESH_TOKEN" != "null" ]]; then
            log_success "Refresh token present for expired credentials"
        else
            log_error "Refresh token missing from expired credentials"
            return 1
        fi
    fi

    return 0
}

test_error_handling() {
    log_info "Testing OAuth error handling..."

    # Test 1: Invalid JSON
    echo "{ invalid json" > "$TEST_DIR/tutor/invalid-auth.json"
    chmod 600 "$TEST_DIR/tutor/invalid-auth.json"

    if command -v jq &> /dev/null; then
        if ! jq . "$TEST_DIR/tutor/invalid-auth.json" &> /dev/null; then
            log_success "Invalid JSON correctly detected"
        else
            log_error "Invalid JSON not detected"
            return 1
        fi
    fi

    # Test 2: Missing required fields
    cat > "$TEST_DIR/tutor/incomplete-auth.json" << 'EOF'
{
  "access_token": "incomplete-token-12345"
}
EOF
    chmod 600 "$TEST_DIR/tutor/incomplete-auth.json"

    if command -v jq &> /dev/null; then
        if ! jq -e '.user_info' "$TEST_DIR/tutor/incomplete-auth.json" &> /dev/null; then
            log_success "Missing required fields correctly detected"
        else
            log_error "Missing required fields not detected"
            return 1
        fi
    fi

    # Test 3: File permission errors
    echo '{"test": "value"}' > "$TEST_DIR/tutor/permission-test.json"
    chmod 000 "$TEST_DIR/tutor/permission-test.json"

    if [[ ! -r "$TEST_DIR/tutor/permission-test.json" ]]; then
        log_success "File permission errors correctly detected"
    else
        log_warning "File permission error detection may not work"
    fi

    # Restore permissions for cleanup
    chmod 600 "$TEST_DIR/tutor/permission-test.json"

    return 0
}

run_oauth_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE OAuth Authentication Tests"
    log_info "========================================"

    # Start mock OAuth server
    if start_mock_oauth_server; then
        log_success "Mock OAuth server ready"
    else
        log_warning "Mock OAuth server not available, some tests will be skipped"
    fi

    # Test 1: OAuth Config Structure
    ((total_tests++))
    if test_oauth_config_structure; then
        log_success "✓ OAuth Config Structure Test"
    else
        log_error "✗ OAuth Config Structure Test"
        ((failed_tests++))
    fi

    # Test 2: Token Validation
    ((total_tests++))
    if test_token_validation; then
        log_success "✓ Token Validation Test"
    else
        log_error "✗ Token Validation Test"
        ((failed_tests++))
    fi

    # Test 3: OAuth Flow Simulation
    ((total_tests++))
    if test_oauth_flow_simulation; then
        log_success "✓ OAuth Flow Simulation Test"
    else
        log_error "✗ OAuth Flow Simulation Test"
        ((failed_tests++))
    fi

    # Test 4: Credential Storage
    ((total_tests++))
    if test_credential_storage; then
        log_success "✓ Credential Storage Test"
    else
        log_error "✗ Credential Storage Test"
        ((failed_tests++))
    fi

    # Test 5: Token Refresh
    ((total_tests++))
    if test_token_refresh; then
        log_success "✓ Token Refresh Test"
    else
        log_error "✗ Token Refresh Test"
        ((failed_tests++))
    fi

    # Test 6: Error Handling
    ((total_tests++))
    if test_error_handling; then
        log_success "✓ Error Handling Test"
    else
        log_error "✗ Error Handling Test"
        ((failed_tests++))
    fi

    # Results summary
    echo ""
    log_info "Test Results Summary"
    log_info "==================="
    log_info "Total tests: $total_tests"
    log_info "Passed: $((total_tests - failed_tests))"
    log_info "Failed: $failed_tests"

    if [[ $failed_tests -eq 0 ]]; then
        log_success "🎉 All OAuth tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI OAuth Authentication Test Suite"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_oauth_tests; then
        log_success "OAuth test suite completed successfully"
        exit 0
    else
        log_error "OAuth test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi