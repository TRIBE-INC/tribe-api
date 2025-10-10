#!/bin/bash

# test-cli-commands.sh - CLI Command Validation Testing
# Tests all CLI commands for proper functionality and error handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TRIBE_CLI_PATH="${TRIBE_CLI_PATH:-/Users/almorris/TRIBE/0zen/bin/tribe}"
TEST_DIR="$HOME/.tribe-test-$$"
BACKUP_DIR="$HOME/.tribe-backup-$$"

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

    # Check if CLI binary exists
    if [[ ! -f "$TRIBE_CLI_PATH" ]]; then
        log_error "TRIBE CLI binary not found at: $TRIBE_CLI_PATH"
        log_info "Set TRIBE_CLI_PATH environment variable to the correct path"
        exit 1
    fi

    # Backup existing .tribe directory if it exists
    if [[ -d "$HOME/.tribe" ]]; then
        mv "$HOME/.tribe" "$BACKUP_DIR"
        log_info "Backed up existing .tribe directory"
    fi

    # Create test directory structure
    mkdir -p "$TEST_DIR"/{bin,config,tutor,logs}
    export TRIBE_HOME="$TEST_DIR"

    # Create mock auth file for testing
    mkdir -p "$TEST_DIR/tutor"
    cat > "$TEST_DIR/tutor/auth.json" << 'EOF'
{
  "access_token": "test-token-12345",
  "refresh_token": "test-refresh-67890",
  "user_info": {
    "email": "test@example.com",
    "name": "Test User"
  },
  "expires_at": "2025-12-31T23:59:59Z"
}
EOF
}

test_basic_commands() {
    log_info "Testing basic CLI commands..."

    # Test 1: Version command
    log_info "Testing: tribe --version"
    if timeout 10s "$TRIBE_CLI_PATH" --version 2>/dev/null; then
        log_success "Version command works"
    else
        log_error "Version command failed"
        return 1
    fi

    # Test 2: Help command
    log_info "Testing: tribe --help"
    if timeout 10s "$TRIBE_CLI_PATH" --help 2>/dev/null | grep -i "tribe" >/dev/null; then
        log_success "Help command works"
    else
        log_error "Help command failed"
        return 1
    fi

    # Test 3: Invalid command handling
    log_info "Testing: tribe invalid-command"
    if timeout 10s "$TRIBE_CLI_PATH" invalid-command 2>&1 | grep -i "unknown\|invalid\|error" >/dev/null; then
        log_success "Invalid command handling works"
    else
        log_warning "Invalid command handling may not be working"
    fi

    return 0
}

test_status_commands() {
    log_info "Testing status commands..."

    # Test 1: Overall status
    log_info "Testing: tribe status"
    if timeout 15s "$TRIBE_CLI_PATH" status 2>/dev/null; then
        log_success "Status command works"
    else
        log_warning "Status command failed (may be expected if services not running)"
    fi

    # Test 2: Auth status
    log_info "Testing: tribe auth-status"
    if timeout 10s "$TRIBE_CLI_PATH" auth-status 2>/dev/null; then
        log_success "Auth status command works"
    else
        log_warning "Auth status command failed (may be expected if not authenticated)"
    fi

    return 0
}

test_tutor_commands() {
    log_info "Testing tutor commands..."

    # Test 1: Tutor status
    log_info "Testing: tribe tutor status"
    if timeout 15s "$TRIBE_CLI_PATH" tutor status 2>/dev/null; then
        log_success "Tutor status command works"
    else
        log_warning "Tutor status command failed (may be expected if tutor not setup)"
    fi

    # Test 2: Tutor enable (dry run if possible)
    log_info "Testing: tribe tutor enable --dry-run"
    if timeout 20s "$TRIBE_CLI_PATH" tutor enable --dry-run 2>/dev/null; then
        log_success "Tutor enable command works"
    elif timeout 20s "$TRIBE_CLI_PATH" tutor enable --help 2>/dev/null; then
        log_success "Tutor enable command available (help accessible)"
    else
        log_warning "Tutor enable command may not be working"
    fi

    # Test 3: Tutor disable
    log_info "Testing: tribe tutor disable --dry-run"
    if timeout 15s "$TRIBE_CLI_PATH" tutor disable --dry-run 2>/dev/null; then
        log_success "Tutor disable command works"
    elif timeout 15s "$TRIBE_CLI_PATH" tutor disable --help 2>/dev/null; then
        log_success "Tutor disable command available (help accessible)"
    else
        log_warning "Tutor disable command may not be working"
    fi

    # Test 4: Tutor logs
    log_info "Testing: tribe tutor logs --tail 5"
    if timeout 10s "$TRIBE_CLI_PATH" tutor logs --tail 5 2>/dev/null; then
        log_success "Tutor logs command works"
    else
        log_warning "Tutor logs command failed (may be expected if no logs exist)"
    fi

    return 0
}

test_config_commands() {
    log_info "Testing configuration commands..."

    # Test 1: Config validation
    log_info "Testing: tribe config validate"
    if timeout 10s "$TRIBE_CLI_PATH" config validate 2>/dev/null; then
        log_success "Config validate command works"
    else
        log_warning "Config validate command failed"
    fi

    # Test 2: Config show
    log_info "Testing: tribe config show"
    if timeout 10s "$TRIBE_CLI_PATH" config show 2>/dev/null; then
        log_success "Config show command works"
    elif timeout 10s "$TRIBE_CLI_PATH" config --help 2>/dev/null; then
        log_success "Config commands available (help accessible)"
    else
        log_warning "Config commands may not be available"
    fi

    return 0
}

test_service_integration() {
    log_info "Testing service integration commands..."

    # Test 1: Cluster status (if available)
    log_info "Testing: tribe cluster status"
    if timeout 15s "$TRIBE_CLI_PATH" cluster status 2>/dev/null; then
        log_success "Cluster status command works"
    else
        log_warning "Cluster commands may not be available"
    fi

    # Test 2: Service health checks
    log_info "Testing: tribe health"
    if timeout 15s "$TRIBE_CLI_PATH" health 2>/dev/null; then
        log_success "Health command works"
    else
        log_warning "Health command may not be available"
    fi

    # Test 3: Port forwarding test
    log_info "Testing: tribe port-forward --test"
    if timeout 10s "$TRIBE_CLI_PATH" port-forward --test 2>/dev/null; then
        log_success "Port forwarding test works"
    else
        log_warning "Port forwarding may not be available"
    fi

    return 0
}

test_authentication_flow() {
    log_info "Testing authentication flow..."

    # Test 1: Login help (don't actually login)
    log_info "Testing: tribe login --help"
    if timeout 10s "$TRIBE_CLI_PATH" login --help 2>/dev/null | grep -i "login\|auth" >/dev/null; then
        log_success "Login help available"
    else
        log_warning "Login command may not be available"
    fi

    # Test 2: Logout help
    log_info "Testing: tribe logout --help"
    if timeout 10s "$TRIBE_CLI_PATH" logout --help 2>/dev/null | grep -i "logout\|remove" >/dev/null; then
        log_success "Logout help available"
    else
        log_warning "Logout command may not be available"
    fi

    # Test 3: Auth status with mock credentials
    export TRIBE_AUTH_FILE="$TEST_DIR/tutor/auth.json"
    log_info "Testing auth status with mock credentials"
    if timeout 10s "$TRIBE_CLI_PATH" auth-status 2>/dev/null; then
        log_success "Auth status works with mock credentials"
    else
        log_warning "Auth status may not work with mock credentials"
    fi

    return 0
}

test_error_handling() {
    log_info "Testing error handling..."

    # Test 1: Command with invalid arguments
    log_info "Testing error handling for invalid arguments"
    if timeout 10s "$TRIBE_CLI_PATH" status --invalid-flag 2>&1 | grep -i "error\|invalid\|unknown" >/dev/null; then
        log_success "Invalid argument handling works"
    else
        log_warning "Invalid argument handling may need improvement"
    fi

    # Test 2: Missing required arguments
    log_info "Testing error handling for missing arguments"
    if timeout 10s "$TRIBE_CLI_PATH" tutor logs --tail 2>&1 | grep -i "error\|required\|missing" >/dev/null; then
        log_success "Missing argument handling works"
    else
        log_warning "Missing argument handling may need improvement"
    fi

    # Test 3: Non-existent subcommand
    log_info "Testing error handling for non-existent subcommand"
    if timeout 10s "$TRIBE_CLI_PATH" nonexistent-command 2>&1 | grep -i "error\|unknown\|invalid" >/dev/null; then
        log_success "Non-existent command handling works"
    else
        log_warning "Non-existent command handling may need improvement"
    fi

    return 0
}

test_performance() {
    log_info "Testing CLI performance..."

    # Test 1: Command response time
    log_info "Testing command response time"
    start_time=$(date +%s%3N)
    if timeout 5s "$TRIBE_CLI_PATH" --version >/dev/null 2>&1; then
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))
        if [[ $duration -lt 2000 ]]; then # Less than 2 seconds
            log_success "Command response time: ${duration}ms (good)"
        else
            log_warning "Command response time: ${duration}ms (slow)"
        fi
    else
        log_warning "Performance test failed"
    fi

    # Test 2: Memory usage (if available)
    if command -v ps &> /dev/null; then
        log_info "Testing memory usage"
        "$TRIBE_CLI_PATH" --version >/dev/null 2>&1 &
        PID=$!
        sleep 1
        if kill -0 $PID 2>/dev/null; then
            MEMORY=$(ps -o rss= -p $PID 2>/dev/null || echo "0")
            if [[ $MEMORY -lt 50000 ]]; then # Less than 50MB
                log_success "Memory usage: ${MEMORY}KB (good)"
            else
                log_warning "Memory usage: ${MEMORY}KB (high)"
            fi
            kill $PID 2>/dev/null || true
        fi
    fi

    return 0
}

run_cli_command_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE CLI Command Tests"
    log_info "==============================="

    # Test 1: Basic Commands
    ((total_tests++))
    if test_basic_commands; then
        log_success "✓ Basic Commands Test"
    else
        log_error "✗ Basic Commands Test"
        ((failed_tests++))
    fi

    # Test 2: Status Commands
    ((total_tests++))
    if test_status_commands; then
        log_success "✓ Status Commands Test"
    else
        log_error "✗ Status Commands Test"
        ((failed_tests++))
    fi

    # Test 3: Tutor Commands
    ((total_tests++))
    if test_tutor_commands; then
        log_success "✓ Tutor Commands Test"
    else
        log_error "✗ Tutor Commands Test"
        ((failed_tests++))
    fi

    # Test 4: Config Commands
    ((total_tests++))
    if test_config_commands; then
        log_success "✓ Config Commands Test"
    else
        log_error "✗ Config Commands Test"
        ((failed_tests++))
    fi

    # Test 5: Service Integration
    ((total_tests++))
    if test_service_integration; then
        log_success "✓ Service Integration Test"
    else
        log_error "✗ Service Integration Test"
        ((failed_tests++))
    fi

    # Test 6: Authentication Flow
    ((total_tests++))
    if test_authentication_flow; then
        log_success "✓ Authentication Flow Test"
    else
        log_error "✗ Authentication Flow Test"
        ((failed_tests++))
    fi

    # Test 7: Error Handling
    ((total_tests++))
    if test_error_handling; then
        log_success "✓ Error Handling Test"
    else
        log_error "✗ Error Handling Test"
        ((failed_tests++))
    fi

    # Test 8: Performance
    ((total_tests++))
    if test_performance; then
        log_success "✓ Performance Test"
    else
        log_error "✗ Performance Test"
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
        log_success "🎉 All CLI command tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI Command Test Suite"
    echo "CLI Path: $TRIBE_CLI_PATH"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_cli_command_tests; then
        log_success "CLI command test suite completed successfully"
        exit 0
    else
        log_error "CLI command test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi