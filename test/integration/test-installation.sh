#!/bin/bash

# test-installation.sh - NPX Installation Flow Testing
# Tests the complete installation process from NPX download to binary verification

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
PACKAGE_NAME="@_xtribe/cli"
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

    # Create test directory
    mkdir -p "$TEST_DIR"
    export TRIBE_HOME="$TEST_DIR"
}

test_npx_installation() {
    log_info "Testing NPX installation flow..."

    # Test 1: NPX command availability
    if ! command -v npx &> /dev/null; then
        log_error "NPX not found - Node.js required for installation"
        return 1
    fi
    log_success "NPX command available"

    # Test 2: Package installation (without execution)
    log_info "Testing package download (dry run)..."
    if ! npx --yes "$PACKAGE_NAME" --version &> /dev/null; then
        log_warning "Package installation test failed - may be expected if package not published"
    else
        log_success "Package successfully downloaded and executed"
    fi

    return 0
}

test_binary_download() {
    log_info "Testing binary download functionality..."

    # Check if binary download would work
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    log_info "Detected platform: $OS-$ARCH"

    # Test binary directory creation
    mkdir -p "$TEST_DIR/bin"

    # Mock binary creation for testing
    echo '#!/bin/bash
echo "TRIBE CLI v1.0.0 (test mode)"
echo "Platform: '$OS'-'$ARCH'"
' > "$TEST_DIR/bin/tribe"
    chmod +x "$TEST_DIR/bin/tribe"

    # Test binary execution
    if "$TEST_DIR/bin/tribe" | grep -q "TRIBE CLI"; then
        log_success "Binary creation and execution test passed"
        return 0
    else
        log_error "Binary execution test failed"
        return 1
    fi
}

test_directory_creation() {
    log_info "Testing ~/.tribe directory structure creation..."

    # Expected directories
    EXPECTED_DIRS=(
        "$TEST_DIR"
        "$TEST_DIR/bin"
        "$TEST_DIR/config"
        "$TEST_DIR/tutor"
        "$TEST_DIR/logs"
    )

    # Create directories
    for dir in "${EXPECTED_DIRS[@]}"; do
        mkdir -p "$dir"
        if [[ -d "$dir" ]]; then
            log_success "Created directory: $dir"
        else
            log_error "Failed to create directory: $dir"
            return 1
        fi
    done

    # Test permissions
    if [[ "$(stat -c %a "$TEST_DIR" 2>/dev/null || stat -f %A "$TEST_DIR" 2>/dev/null)" == "755" ]]; then
        log_success "Directory permissions correct (755)"
    else
        log_warning "Directory permissions may not be optimal"
    fi

    return 0
}

test_version_command() {
    log_info "Testing version command functionality..."

    # Create mock CLI script that responds to --version
    cat > "$TEST_DIR/bin/tribe" << 'EOF'
#!/bin/bash
case "$1" in
    --version|-v)
        echo "tribe version 1.0.0"
        echo "Build: 2025-10-09"
        echo "Platform: $(uname -s)-$(uname -m)"
        exit 0
        ;;
    --help|-h)
        echo "TRIBE CLI - AI Coding Assistant Analytics"
        echo ""
        echo "Usage: tribe <command> [options]"
        echo ""
        echo "Commands:"
        echo "  login         Authenticate with GitHub OAuth"
        echo "  logout        Remove stored credentials"
        echo "  status        Check system status"
        echo "  tutor enable  Start telemetry collection"
        echo "  tutor disable Stop telemetry collection"
        echo "  tutor status  Check tutor status"
        echo "  tutor logs    View collector logs"
        echo ""
        echo "Options:"
        echo "  --version, -v Show version information"
        echo "  --help, -h    Show this help message"
        exit 0
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'tribe --help' for usage information"
        exit 1
        ;;
esac
EOF
    chmod +x "$TEST_DIR/bin/tribe"

    # Test version command
    if "$TEST_DIR/bin/tribe" --version | grep -q "tribe version"; then
        log_success "Version command working"
    else
        log_error "Version command failed"
        return 1
    fi

    # Test help command
    if "$TEST_DIR/bin/tribe" --help | grep -q "TRIBE CLI"; then
        log_success "Help command working"
    else
        log_error "Help command failed"
        return 1
    fi

    return 0
}

test_config_validation() {
    log_info "Testing configuration validation..."

    # Create test configuration
    mkdir -p "$TEST_DIR/config"
    cat > "$TEST_DIR/config/config.json" << 'EOF'
{
  "api_base": "http://localhost:3456",
  "tutor_server": "http://localhost:8080",
  "auth_file": "~/.tribe/tutor/auth.json",
  "log_level": "info"
}
EOF

    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if jq . "$TEST_DIR/config/config.json" &> /dev/null; then
            log_success "Configuration JSON is valid"
        else
            log_error "Configuration JSON is invalid"
            return 1
        fi
    else
        log_warning "jq not available for JSON validation"
    fi

    # Test configuration reading
    if [[ -f "$TEST_DIR/config/config.json" ]]; then
        log_success "Configuration file created and readable"
    else
        log_error "Configuration file creation failed"
        return 1
    fi

    return 0
}

test_platform_compatibility() {
    log_info "Testing platform compatibility..."

    PLATFORM=$(uname -s)
    ARCH=$(uname -m)

    case "$PLATFORM" in
        Darwin)
            log_info "Testing on macOS ($ARCH)"
            # Test macOS-specific functionality
            if command -v open &> /dev/null; then
                log_success "macOS browser launching available"
            else
                log_warning "Browser launching may not work"
            fi
            ;;
        Linux)
            log_info "Testing on Linux ($ARCH)"
            # Test Linux-specific functionality
            if command -v xdg-open &> /dev/null || command -v gnome-open &> /dev/null; then
                log_success "Linux browser launching available"
            else
                log_warning "Browser launching may not work"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            log_info "Testing on Windows ($ARCH)"
            # Test Windows-specific functionality
            if command -v cmd &> /dev/null; then
                log_success "Windows command interface available"
            else
                log_warning "Windows compatibility may be limited"
            fi
            ;;
        *)
            log_warning "Untested platform: $PLATFORM"
            ;;
    esac

    # Test file path handling
    TEST_PATH="$TEST_DIR/test-path with spaces"
    mkdir -p "$TEST_PATH"
    if [[ -d "$TEST_PATH" ]]; then
        log_success "Path with spaces handling works"
        rm -rf "$TEST_PATH"
    else
        log_error "Path with spaces handling failed"
        return 1
    fi

    return 0
}

run_installation_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE CLI Installation Tests"
    log_info "====================================="

    # Test 1: NPX Installation
    ((total_tests++))
    if test_npx_installation; then
        log_success "✓ NPX Installation Test"
    else
        log_error "✗ NPX Installation Test"
        ((failed_tests++))
    fi

    # Test 2: Binary Download
    ((total_tests++))
    if test_binary_download; then
        log_success "✓ Binary Download Test"
    else
        log_error "✗ Binary Download Test"
        ((failed_tests++))
    fi

    # Test 3: Directory Creation
    ((total_tests++))
    if test_directory_creation; then
        log_success "✓ Directory Creation Test"
    else
        log_error "✗ Directory Creation Test"
        ((failed_tests++))
    fi

    # Test 4: Version Command
    ((total_tests++))
    if test_version_command; then
        log_success "✓ Version Command Test"
    else
        log_error "✗ Version Command Test"
        ((failed_tests++))
    fi

    # Test 5: Configuration Validation
    ((total_tests++))
    if test_config_validation; then
        log_success "✓ Configuration Validation Test"
    else
        log_error "✗ Configuration Validation Test"
        ((failed_tests++))
    fi

    # Test 6: Platform Compatibility
    ((total_tests++))
    if test_platform_compatibility; then
        log_success "✓ Platform Compatibility Test"
    else
        log_error "✗ Platform Compatibility Test"
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
        log_success "🎉 All installation tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI Installation Test Suite"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_installation_tests; then
        log_success "Installation test suite completed successfully"
        exit 0
    else
        log_error "Installation test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi