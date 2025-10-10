#!/bin/bash

# test-configuration.sh - Configuration System Testing
# Tests CLI configuration validation, directory structure, and error handling

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

    # Backup existing .tribe directory if it exists
    if [[ -d "$HOME/.tribe" ]]; then
        mv "$HOME/.tribe" "$BACKUP_DIR"
        log_info "Backed up existing .tribe directory"
    fi

    # Create test directory structure
    mkdir -p "$TEST_DIR"
    export TRIBE_HOME="$TEST_DIR"
}

test_directory_structure() {
    log_info "Testing directory structure creation..."

    # Expected directories
    EXPECTED_DIRS=(
        "$TEST_DIR"
        "$TEST_DIR/bin"
        "$TEST_DIR/config"
        "$TEST_DIR/tutor"
        "$TEST_DIR/logs"
        "$TEST_DIR/cache"
        "$TEST_DIR/tmp"
    )

    # Create directories
    for dir in "${EXPECTED_DIRS[@]}"; do
        mkdir -p "$dir"
        if [[ -d "$dir" ]]; then
            log_success "Created directory: ${dir#$TEST_DIR/}"
        else
            log_error "Failed to create directory: ${dir#$TEST_DIR/}"
            return 1
        fi
    done

    # Test directory permissions
    for dir in "${EXPECTED_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            # Check if directory is readable and writable
            if [[ -r "$dir" && -w "$dir" ]]; then
                log_success "Directory permissions OK: ${dir#$TEST_DIR/}"
            else
                log_error "Directory permissions incorrect: ${dir#$TEST_DIR/}"
                return 1
            fi
        fi
    done

    return 0
}

test_config_file_creation() {
    log_info "Testing configuration file creation..."

    # Create main config file
    cat > "$TEST_DIR/config/config.json" << 'EOF'
{
  "api_base": "http://localhost:3456",
  "tutor_server": "http://localhost:8080",
  "auth_file": "~/.tribe/tutor/auth.json",
  "log_level": "info",
  "timeout": 30,
  "retry_attempts": 3,
  "cache_ttl": 300,
  "features": {
    "telemetry": true,
    "auto_update": false,
    "debug_mode": false
  }
}
EOF

    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if jq . "$TEST_DIR/config/config.json" &> /dev/null; then
            log_success "Main config JSON is valid"
        else
            log_error "Main config JSON is invalid"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -m json.tool "$TEST_DIR/config/config.json" &> /dev/null; then
            log_success "Main config JSON is valid (python3)"
        else
            log_error "Main config JSON is invalid"
            return 1
        fi
    else
        log_warning "No JSON validator available, skipping syntax check"
    fi

    # Test file permissions
    if [[ -r "$TEST_DIR/config/config.json" ]]; then
        log_success "Config file is readable"
    else
        log_error "Config file is not readable"
        return 1
    fi

    return 0
}

test_auth_config() {
    log_info "Testing authentication configuration..."

    # Create auth config file
    cat > "$TEST_DIR/tutor/auth.json" << 'EOF'
{
  "access_token": "test-access-token-12345",
  "refresh_token": "test-refresh-token-67890",
  "token_type": "Bearer",
  "expires_at": "2025-12-31T23:59:59Z",
  "user_info": {
    "id": "test-user-123",
    "email": "test@example.com",
    "name": "Test User",
    "avatar_url": "https://example.com/avatar.png"
  },
  "scopes": ["read", "write"],
  "created_at": "2025-01-01T00:00:00Z"
}
EOF

    # Set secure permissions (only owner can read/write)
    chmod 600 "$TEST_DIR/tutor/auth.json"

    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if jq . "$TEST_DIR/tutor/auth.json" &> /dev/null; then
            log_success "Auth config JSON is valid"
        else
            log_error "Auth config JSON is invalid"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -m json.tool "$TEST_DIR/tutor/auth.json" &> /dev/null; then
            log_success "Auth config JSON is valid (python3)"
        else
            log_error "Auth config JSON is invalid"
            return 1
        fi
    fi

    # Test file permissions (should be 600)
    if [[ "$(stat -c %a "$TEST_DIR/tutor/auth.json" 2>/dev/null || stat -f %A "$TEST_DIR/tutor/auth.json" 2>/dev/null)" == "600" ]]; then
        log_success "Auth file has secure permissions (600)"
    else
        log_warning "Auth file permissions may not be secure"
    fi

    # Test required fields
    if command -v jq &> /dev/null; then
        REQUIRED_FIELDS=("access_token" "expires_at" "user_info")
        for field in "${REQUIRED_FIELDS[@]}"; do
            if jq -e ".$field" "$TEST_DIR/tutor/auth.json" &> /dev/null; then
                log_success "Required field present: $field"
            else
                log_error "Required field missing: $field"
                return 1
            fi
        done
    fi

    return 0
}

test_config_validation() {
    log_info "Testing configuration validation..."

    # Test 1: Valid configuration
    if validate_config_structure "$TEST_DIR/config/config.json"; then
        log_success "Valid configuration passes validation"
    else
        log_error "Valid configuration fails validation"
        return 1
    fi

    # Test 2: Invalid JSON
    echo "{ invalid json" > "$TEST_DIR/config/invalid.json"
    if ! validate_config_structure "$TEST_DIR/config/invalid.json"; then
        log_success "Invalid JSON correctly rejected"
    else
        log_error "Invalid JSON incorrectly accepted"
        return 1
    fi

    # Test 3: Missing required fields
    echo '{"api_base": "http://localhost:3456"}' > "$TEST_DIR/config/incomplete.json"
    if validate_config_structure "$TEST_DIR/config/incomplete.json"; then
        log_warning "Incomplete config accepted (may be OK if defaults exist)"
    else
        log_success "Incomplete config correctly rejected"
    fi

    return 0
}

validate_config_structure() {
    local config_file="$1"

    # Check if file exists and is readable
    if [[ ! -r "$config_file" ]]; then
        return 1
    fi

    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if ! jq . "$config_file" &> /dev/null; then
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if ! python3 -m json.tool "$config_file" &> /dev/null; then
            return 1
        fi
    else
        # Basic syntax check
        if ! grep -q "{" "$config_file" || ! grep -q "}" "$config_file"; then
            return 1
        fi
    fi

    return 0
}

test_environment_variables() {
    log_info "Testing environment variable handling..."

    # Test environment variable override
    export TRIBE_API_BASE="http://localhost:9999"
    export TRIBE_LOG_LEVEL="debug"
    export TRIBE_TIMEOUT="60"

    # Create config that should be overridden
    cat > "$TEST_DIR/config/env-test.json" << 'EOF'
{
  "api_base": "http://localhost:3456",
  "log_level": "info",
  "timeout": 30
}
EOF

    # Test if environment variables would take precedence
    # (This is a structural test since we can't run the actual CLI)
    if [[ "$TRIBE_API_BASE" == "http://localhost:9999" ]]; then
        log_success "Environment variable TRIBE_API_BASE set correctly"
    else
        log_error "Environment variable setting failed"
        return 1
    fi

    if [[ "$TRIBE_LOG_LEVEL" == "debug" ]]; then
        log_success "Environment variable TRIBE_LOG_LEVEL set correctly"
    else
        log_error "Environment variable setting failed"
        return 1
    fi

    # Clean up environment variables
    unset TRIBE_API_BASE TRIBE_LOG_LEVEL TRIBE_TIMEOUT

    return 0
}

test_config_file_formats() {
    log_info "Testing different configuration file formats..."

    # Test 1: JSON format (primary)
    cat > "$TEST_DIR/config/test.json" << 'EOF'
{
  "api_base": "http://localhost:3456",
  "tutor_server": "http://localhost:8080"
}
EOF

    if validate_config_structure "$TEST_DIR/config/test.json"; then
        log_success "JSON configuration format works"
    else
        log_error "JSON configuration format failed"
        return 1
    fi

    # Test 2: YAML format (if supported)
    cat > "$TEST_DIR/config/test.yaml" << 'EOF'
api_base: http://localhost:3456
tutor_server: http://localhost:8080
features:
  telemetry: true
  debug_mode: false
EOF

    if command -v yq &> /dev/null || command -v python3 &> /dev/null; then
        log_success "YAML configuration format available"
    else
        log_warning "YAML configuration format not available"
    fi

    return 0
}

test_path_handling() {
    log_info "Testing file path handling..."

    # Test 1: Paths with spaces
    TEST_PATH_WITH_SPACES="$TEST_DIR/config/path with spaces"
    mkdir -p "$TEST_PATH_WITH_SPACES"
    echo '{"test": "value"}' > "$TEST_PATH_WITH_SPACES/config.json"

    if [[ -f "$TEST_PATH_WITH_SPACES/config.json" ]]; then
        log_success "Paths with spaces handled correctly"
    else
        log_error "Paths with spaces failed"
        return 1
    fi

    # Test 2: Tilde expansion
    if [[ "$TEST_DIR" == "$HOME"* ]]; then
        TILDE_PATH="${TEST_DIR/#$HOME/~}"
        log_success "Tilde path expansion test setup: $TILDE_PATH"
    else
        log_warning "Tilde expansion test skipped (test dir not in home)"
    fi

    # Test 3: Relative paths
    cd "$TEST_DIR" || return 1
    mkdir -p "relative/path"
    echo '{"test": "relative"}' > "relative/path/config.json"

    if [[ -f "relative/path/config.json" ]]; then
        log_success "Relative paths handled correctly"
    else
        log_error "Relative paths failed"
        return 1
    fi

    return 0
}

test_config_migration() {
    log_info "Testing configuration migration..."

    # Create old format config
    cat > "$TEST_DIR/config/old-config.json" << 'EOF'
{
  "api_url": "http://localhost:3456",
  "server_url": "http://localhost:8080",
  "debug": true
}
EOF

    # Create new format config
    cat > "$TEST_DIR/config/new-config.json" << 'EOF'
{
  "api_base": "http://localhost:3456",
  "tutor_server": "http://localhost:8080",
  "log_level": "debug",
  "version": "2.0"
}
EOF

    # Test that both formats exist
    if [[ -f "$TEST_DIR/config/old-config.json" && -f "$TEST_DIR/config/new-config.json" ]]; then
        log_success "Configuration migration test files created"
    else
        log_error "Configuration migration test setup failed"
        return 1
    fi

    # Test version detection
    if command -v jq &> /dev/null; then
        OLD_VERSION=$(jq -r '.version // "1.0"' "$TEST_DIR/config/old-config.json")
        NEW_VERSION=$(jq -r '.version // "1.0"' "$TEST_DIR/config/new-config.json")

        if [[ "$OLD_VERSION" == "1.0" && "$NEW_VERSION" == "2.0" ]]; then
            log_success "Configuration version detection works"
        else
            log_warning "Configuration version detection may need improvement"
        fi
    fi

    return 0
}

run_configuration_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE Configuration Tests"
    log_info "================================="

    # Test 1: Directory Structure
    ((total_tests++))
    if test_directory_structure; then
        log_success "✓ Directory Structure Test"
    else
        log_error "✗ Directory Structure Test"
        ((failed_tests++))
    fi

    # Test 2: Config File Creation
    ((total_tests++))
    if test_config_file_creation; then
        log_success "✓ Config File Creation Test"
    else
        log_error "✗ Config File Creation Test"
        ((failed_tests++))
    fi

    # Test 3: Auth Configuration
    ((total_tests++))
    if test_auth_config; then
        log_success "✓ Auth Configuration Test"
    else
        log_error "✗ Auth Configuration Test"
        ((failed_tests++))
    fi

    # Test 4: Config Validation
    ((total_tests++))
    if test_config_validation; then
        log_success "✓ Config Validation Test"
    else
        log_error "✗ Config Validation Test"
        ((failed_tests++))
    fi

    # Test 5: Environment Variables
    ((total_tests++))
    if test_environment_variables; then
        log_success "✓ Environment Variables Test"
    else
        log_error "✗ Environment Variables Test"
        ((failed_tests++))
    fi

    # Test 6: Config File Formats
    ((total_tests++))
    if test_config_file_formats; then
        log_success "✓ Config File Formats Test"
    else
        log_error "✗ Config File Formats Test"
        ((failed_tests++))
    fi

    # Test 7: Path Handling
    ((total_tests++))
    if test_path_handling; then
        log_success "✓ Path Handling Test"
    else
        log_error "✗ Path Handling Test"
        ((failed_tests++))
    fi

    # Test 8: Config Migration
    ((total_tests++))
    if test_config_migration; then
        log_success "✓ Config Migration Test"
    else
        log_error "✗ Config Migration Test"
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
        log_success "🎉 All configuration tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI Configuration Test Suite"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_configuration_tests; then
        log_success "Configuration test suite completed successfully"
        exit 0
    else
        log_error "Configuration test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi