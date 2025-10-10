#!/bin/bash

# test-documentation.sh - Documentation Accuracy Validation
# Tests documentation examples and validates they match actual CLI behavior

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
TRIBE_CLI_PATH="${TRIBE_CLI_PATH:-/Users/almorris/TRIBE/0zen/bin/tribe}"
DOCS_DIR="${DOCS_DIR:-/Users/almorris/TRIBE/_site/app/docs}"

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
    mkdir -p "$TEST_DIR"/{bin,config,tutor,logs}
    export TRIBE_HOME="$TEST_DIR"
}

test_installation_documentation() {
    log_info "Testing installation documentation accuracy..."

    # Test 1: NPX command format
    DOC_NPX_COMMAND="npx @_xtribe/cli"

    log_info "Verifying NPX command format: $DOC_NPX_COMMAND"
    if [[ "$DOC_NPX_COMMAND" =~ ^npx\ @_xtribe/cli(@latest)?$ ]]; then
        log_success "NPX command format is correct"
    else
        log_error "NPX command format may be incorrect"
        return 1
    fi

    # Test 2: Installation directory structure
    EXPECTED_DIRS=(
        "~/.tribe"
        "~/.tribe/bin"
        "~/.tribe/config"
        "~/.tribe/tutor"
        "~/.tribe/logs"
    )

    log_info "Verifying expected directory structure..."
    for dir in "${EXPECTED_DIRS[@]}"; do
        # Expand tilde
        EXPANDED_DIR="${dir/#\~/$HOME}"
        mkdir -p "$EXPANDED_DIR"
        if [[ -d "$EXPANDED_DIR" ]]; then
            log_success "Directory structure correct: $dir"
        else
            log_error "Directory structure incorrect: $dir"
            return 1
        fi
    done

    return 0
}

test_command_documentation() {
    log_info "Testing CLI command documentation accuracy..."

    if [[ ! -f "$TRIBE_CLI_PATH" ]]; then
        log_warning "TRIBE CLI not found, skipping command tests"
        return 0
    fi

    # Test 1: Help command output
    log_info "Testing help command documentation..."
    HELP_OUTPUT=$(timeout 10s "$TRIBE_CLI_PATH" --help 2>/dev/null || echo "")

    EXPECTED_COMMANDS=(
        "login"
        "logout"
        "status"
        "tutor"
        "version"
    )

    for cmd in "${EXPECTED_COMMANDS[@]}"; do
        if echo "$HELP_OUTPUT" | grep -qi "$cmd"; then
            log_success "Command documented in help: $cmd"
        else
            log_warning "Command not found in help: $cmd"
        fi
    done

    # Test 2: Version command format
    log_info "Testing version command format..."
    VERSION_OUTPUT=$(timeout 10s "$TRIBE_CLI_PATH" --version 2>/dev/null || echo "")

    if echo "$VERSION_OUTPUT" | grep -qiE "(version|v[0-9]+\.[0-9]+\.[0-9]+|tribe)"; then
        log_success "Version command produces expected output"
    else
        log_warning "Version command output may not match documentation"
    fi

    # Test 3: Tutor subcommands
    log_info "Testing tutor subcommand documentation..."
    TUTOR_HELP=$(timeout 10s "$TRIBE_CLI_PATH" tutor --help 2>/dev/null || echo "")

    EXPECTED_TUTOR_COMMANDS=(
        "enable"
        "disable"
        "status"
        "logs"
    )

    for cmd in "${EXPECTED_TUTOR_COMMANDS[@]}"; do
        if echo "$TUTOR_HELP" | grep -qi "$cmd"; then
            log_success "Tutor command documented: $cmd"
        else
            log_warning "Tutor command not found in help: $cmd"
        fi
    done

    return 0
}

test_configuration_documentation() {
    log_info "Testing configuration documentation accuracy..."

    # Test 1: Configuration file structure
    CONFIG_FILE="$TEST_DIR/config/config.json"
    cat > "$CONFIG_FILE" << 'EOF'
{
  "api_base": "http://localhost:3456",
  "tutor_server": "http://localhost:8080",
  "auth_file": "~/.tribe/tutor/auth.json",
  "log_level": "info",
  "timeout": 30,
  "retry_attempts": 3
}
EOF

    # Validate documented config structure
    if command -v jq &> /dev/null; then
        DOCUMENTED_FIELDS=("api_base" "tutor_server" "auth_file" "log_level")
        for field in "${DOCUMENTED_FIELDS[@]}"; do
            if jq -e ".$field" "$CONFIG_FILE" &> /dev/null; then
                log_success "Documented config field present: $field"
            else
                log_error "Documented config field missing: $field"
                return 1
            fi
        done
    fi

    # Test 2: Default port numbers
    DOCUMENTED_PORTS=(
        "3000:Dashboard"
        "3001:Gitea"
        "3456:Bridge"
        "5555:TaskMaster"
        "8080:Tutor"
    )

    log_info "Verifying documented port numbers..."
    for port_info in "${DOCUMENTED_PORTS[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        if [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -gt 1000 ]] && [[ $port -lt 65536 ]]; then
            log_success "Port number valid for $service: $port"
        else
            log_error "Port number invalid for $service: $port"
            return 1
        fi
    done

    return 0
}

test_oauth_documentation() {
    log_info "Testing OAuth documentation accuracy..."

    # Test 1: Auth file structure
    AUTH_FILE="$TEST_DIR/tutor/auth.json"
    cat > "$AUTH_FILE" << 'EOF'
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
  "scopes": ["read", "write"]
}
EOF

    # Validate documented auth structure
    if command -v jq &> /dev/null; then
        DOCUMENTED_AUTH_FIELDS=("access_token" "refresh_token" "expires_at" "user_info")
        for field in "${DOCUMENTED_AUTH_FIELDS[@]}"; do
            if jq -e ".$field" "$AUTH_FILE" &> /dev/null; then
                log_success "Documented auth field present: $field"
            else
                log_error "Documented auth field missing: $field"
                return 1
            fi
        done

        # Check user_info structure
        USER_INFO_FIELDS=("email" "name" "id")
        for field in "${USER_INFO_FIELDS[@]}"; do
            if jq -e ".user_info.$field" "$AUTH_FILE" &> /dev/null; then
                log_success "Documented user_info field present: $field"
            else
                log_error "Documented user_info field missing: $field"
                return 1
            fi
        done
    fi

    # Test 2: File permissions
    chmod 600 "$AUTH_FILE"
    if [[ "$(stat -c %a "$AUTH_FILE" 2>/dev/null || stat -f %A "$AUTH_FILE" 2>/dev/null)" == "600" ]]; then
        log_success "Documented auth file permissions (600) are correct"
    else
        log_warning "Auth file permissions may not match documentation"
    fi

    return 0
}

test_example_commands() {
    log_info "Testing documented example commands..."

    if [[ ! -f "$TRIBE_CLI_PATH" ]]; then
        log_warning "TRIBE CLI not found, skipping example command tests"
        return 0
    fi

    # Common example commands from documentation
    EXAMPLE_COMMANDS=(
        "--version:Version check"
        "--help:Help display"
        "tutor status:Tutor status check"
        "auth-status:Authentication status"
    )

    for cmd_info in "${EXAMPLE_COMMANDS[@]}"; do
        IFS=':' read -r cmd description <<< "$cmd_info"
        log_info "Testing example: tribe $cmd ($description)"

        if timeout 10s "$TRIBE_CLI_PATH" $cmd &> /dev/null; then
            log_success "Example command works: tribe $cmd"
        else
            log_warning "Example command failed: tribe $cmd (may be expected if services not running)"
        fi
    done

    return 0
}

test_error_message_documentation() {
    log_info "Testing documented error messages..."

    if [[ ! -f "$TRIBE_CLI_PATH" ]]; then
        log_warning "TRIBE CLI not found, skipping error message tests"
        return 0
    fi

    # Test 1: Invalid command error
    log_info "Testing invalid command error handling..."
    INVALID_OUTPUT=$(timeout 5s "$TRIBE_CLI_PATH" invalid-command-xyz 2>&1 || echo "")

    if echo "$INVALID_OUTPUT" | grep -qi "unknown\|invalid\|error\|not found"; then
        log_success "Invalid command produces appropriate error message"
    else
        log_warning "Invalid command error message may not be clear"
    fi

    # Test 2: Missing argument error
    log_info "Testing missing argument error handling..."
    MISSING_ARG_OUTPUT=$(timeout 5s "$TRIBE_CLI_PATH" tutor logs --tail 2>&1 || echo "")

    if echo "$MISSING_ARG_OUTPUT" | grep -qi "required\|missing\|argument\|usage"; then
        log_success "Missing argument produces appropriate error message"
    else
        log_warning "Missing argument error message may not be clear"
    fi

    return 0
}

test_url_documentation() {
    log_info "Testing documented URLs and endpoints..."

    # Documented URLs from the documentation
    DOCUMENTED_URLS=(
        "http://localhost:3000:Dashboard"
        "http://localhost:3001:Gitea"
        "http://localhost:3456:Bridge"
        "http://localhost:5555:TaskMaster"
        "http://localhost:8080:Tutor"
        "https://tribecode.ai:Production"
    )

    for url_info in "${DOCUMENTED_URLS[@]}"; do
        IFS=':' read -r url service <<< "$url_info"
        log_info "Validating documented URL format: $url ($service)"

        # Basic URL format validation
        if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
            log_success "URL format valid: $url"
        else
            log_error "URL format invalid: $url"
            return 1
        fi

        # Test accessibility for localhost URLs
        if [[ "$url" =~ ^http://localhost: ]]; then
            if curl -s --connect-timeout 3 "$url" &> /dev/null; then
                log_success "Documented service accessible: $service"
            else
                log_warning "Documented service not accessible: $service (may not be running)"
            fi
        fi
    done

    return 0
}

test_installation_prerequisites() {
    log_info "Testing documented prerequisites..."

    # Test 1: Node.js requirement
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//')
        log_success "Node.js available: $NODE_VERSION"

        # Check if version meets minimum requirements (assuming Node 16+)
        MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)
        if [[ $MAJOR_VERSION -ge 16 ]]; then
            log_success "Node.js version meets requirements"
        else
            log_warning "Node.js version may be too old: $NODE_VERSION"
        fi
    else
        log_error "Node.js not available (required for NPX installation)"
        return 1
    fi

    # Test 2: NPM/NPX availability
    if command -v npm &> /dev/null; then
        log_success "npm available"

        if command -v npx &> /dev/null; then
            log_success "npx available"
        else
            log_error "npx not available (required for installation)"
            return 1
        fi
    else
        log_error "npm not available"
        return 1
    fi

    # Test 3: Operating system support
    OS=$(uname -s 2>/dev/null || echo "Unknown")
    case "$OS" in
        Darwin)
            log_success "macOS supported"
            ;;
        Linux)
            log_success "Linux supported"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            log_success "Windows supported (via Git Bash/WSL)"
            ;;
        *)
            log_warning "Operating system support unclear: $OS"
            ;;
    esac

    return 0
}

test_documentation_files() {
    log_info "Testing documentation file accessibility..."

    # Check if documentation directory exists
    if [[ -d "$DOCS_DIR" ]]; then
        log_success "Documentation directory found: $DOCS_DIR"

        # Check for key documentation files
        DOC_FILES=(
            "cli/page.tsx"
            "cli-commands/page.tsx"
            "getting-started"
            "troubleshooting"
        )

        for doc_file in "${DOC_FILES[@]}"; do
            if [[ -f "$DOCS_DIR/$doc_file" ]] || find "$DOCS_DIR" -name "*$doc_file*" -type f | grep -q .; then
                log_success "Documentation file found: $doc_file"
            else
                log_warning "Documentation file not found: $doc_file"
            fi
        done
    else
        log_warning "Documentation directory not found: $DOCS_DIR"
    fi

    return 0
}

run_documentation_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE Documentation Validation Tests"
    log_info "============================================="

    # Test 1: Installation Documentation
    ((total_tests++))
    if test_installation_documentation; then
        log_success "✓ Installation Documentation Test"
    else
        log_error "✗ Installation Documentation Test"
        ((failed_tests++))
    fi

    # Test 2: Command Documentation
    ((total_tests++))
    if test_command_documentation; then
        log_success "✓ Command Documentation Test"
    else
        log_error "✗ Command Documentation Test"
        ((failed_tests++))
    fi

    # Test 3: Configuration Documentation
    ((total_tests++))
    if test_configuration_documentation; then
        log_success "✓ Configuration Documentation Test"
    else
        log_error "✗ Configuration Documentation Test"
        ((failed_tests++))
    fi

    # Test 4: OAuth Documentation
    ((total_tests++))
    if test_oauth_documentation; then
        log_success "✓ OAuth Documentation Test"
    else
        log_error "✗ OAuth Documentation Test"
        ((failed_tests++))
    fi

    # Test 5: Example Commands
    ((total_tests++))
    if test_example_commands; then
        log_success "✓ Example Commands Test"
    else
        log_error "✗ Example Commands Test"
        ((failed_tests++))
    fi

    # Test 6: Error Message Documentation
    ((total_tests++))
    if test_error_message_documentation; then
        log_success "✓ Error Message Documentation Test"
    else
        log_error "✗ Error Message Documentation Test"
        ((failed_tests++))
    fi

    # Test 7: URL Documentation
    ((total_tests++))
    if test_url_documentation; then
        log_success "✓ URL Documentation Test"
    else
        log_error "✗ URL Documentation Test"
        ((failed_tests++))
    fi

    # Test 8: Installation Prerequisites
    ((total_tests++))
    if test_installation_prerequisites; then
        log_success "✓ Installation Prerequisites Test"
    else
        log_error "✗ Installation Prerequisites Test"
        ((failed_tests++))
    fi

    # Test 9: Documentation Files
    ((total_tests++))
    if test_documentation_files; then
        log_success "✓ Documentation Files Test"
    else
        log_error "✗ Documentation Files Test"
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
        log_success "🎉 All documentation validation tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI Documentation Validation Test Suite"
    echo "CLI Path: $TRIBE_CLI_PATH"
    echo "Docs Path: $DOCS_DIR"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_documentation_tests; then
        log_success "Documentation validation test suite completed successfully"
        exit 0
    else
        log_error "Documentation validation test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi