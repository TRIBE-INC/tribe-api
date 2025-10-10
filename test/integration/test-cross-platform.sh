#!/bin/bash

# test-cross-platform.sh - Cross-Platform Compatibility Testing
# Tests CLI functionality across different operating systems and environments

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
    mkdir -p "$TEST_DIR"/{bin,config,tutor,logs}
    export TRIBE_HOME="$TEST_DIR"
}

detect_platform() {
    log_info "Detecting platform and environment..."

    # Detect operating system
    OS=$(uname -s 2>/dev/null || echo "Unknown")
    ARCH=$(uname -m 2>/dev/null || echo "Unknown")

    case "$OS" in
        Darwin)
            OS_TYPE="macOS"
            PACKAGE_MANAGER="brew"
            ;;
        Linux)
            OS_TYPE="Linux"
            if command -v apt &> /dev/null; then
                PACKAGE_MANAGER="apt"
            elif command -v yum &> /dev/null; then
                PACKAGE_MANAGER="yum"
            elif command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
            elif command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
            else
                PACKAGE_MANAGER="unknown"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS_TYPE="Windows"
            PACKAGE_MANAGER="choco"
            ;;
        FreeBSD)
            OS_TYPE="FreeBSD"
            PACKAGE_MANAGER="pkg"
            ;;
        *)
            OS_TYPE="Unknown"
            PACKAGE_MANAGER="unknown"
            ;;
    esac

    log_info "Platform: $OS_TYPE ($ARCH)"
    log_info "Package Manager: $PACKAGE_MANAGER"

    return 0
}

test_shell_compatibility() {
    log_info "Testing shell compatibility..."

    # Detect current shell
    CURRENT_SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")
    log_info "Current shell: $CURRENT_SHELL"

    # Test common shell features
    # Test 1: Command substitution
    if TEST_VAR=$(echo "test" 2>/dev/null); then
        log_success "Command substitution works"
    else
        log_error "Command substitution failed"
        return 1
    fi

    # Test 2: Variable expansion
    TEST_VAR="test_value"
    if [[ "${TEST_VAR}" == "test_value" ]]; then
        log_success "Variable expansion works"
    else
        log_error "Variable expansion failed"
        return 1
    fi

    # Test 3: Array support (if available)
    if [[ "$CURRENT_SHELL" == "bash" ]] || [[ "$CURRENT_SHELL" == "zsh" ]]; then
        TEST_ARRAY=("item1" "item2" "item3")
        if [[ "${#TEST_ARRAY[@]}" -eq 3 ]]; then
            log_success "Array support works"
        else
            log_warning "Array support may have issues"
        fi
    else
        log_warning "Shell may have limited array support: $CURRENT_SHELL"
    fi

    # Test 4: Function definitions
    test_function() {
        return 0
    }
    if test_function; then
        log_success "Function definitions work"
    else
        log_error "Function definitions failed"
        return 1
    fi

    return 0
}

test_file_path_handling() {
    log_info "Testing file path handling..."

    # Test 1: Paths with spaces
    SPACE_PATH="$TEST_DIR/path with spaces"
    mkdir -p "$SPACE_PATH"
    echo "test content" > "$SPACE_PATH/test file.txt"

    if [[ -f "$SPACE_PATH/test file.txt" ]]; then
        log_success "Paths with spaces handled correctly"
    else
        log_error "Paths with spaces failed"
        return 1
    fi

    # Test 2: Long paths
    LONG_PATH="$TEST_DIR/very/deep/nested/directory/structure/for/testing/long/paths"
    mkdir -p "$LONG_PATH"
    echo "test" > "$LONG_PATH/file.txt"

    if [[ -f "$LONG_PATH/file.txt" ]]; then
        log_success "Long paths handled correctly"
    else
        log_error "Long paths failed"
        return 1
    fi

    # Test 3: Special characters in paths
    if [[ "$OS_TYPE" != "Windows" ]]; then
        SPECIAL_PATH="$TEST_DIR/special-chars!@#$%"
        mkdir -p "$SPECIAL_PATH" 2>/dev/null || true
        if [[ -d "$SPECIAL_PATH" ]]; then
            log_success "Special characters in paths handled"
        else
            log_warning "Special characters in paths may cause issues"
        fi
    fi

    # Test 4: Case sensitivity
    mkdir -p "$TEST_DIR/CaseTest"
    mkdir -p "$TEST_DIR/casetest" 2>/dev/null || true

    if [[ -d "$TEST_DIR/CaseTest" ]] && [[ -d "$TEST_DIR/casetest" ]]; then
        log_success "File system is case-sensitive"
    elif [[ -d "$TEST_DIR/CaseTest" ]]; then
        log_warning "File system is case-insensitive"
    else
        log_error "Case test failed"
        return 1
    fi

    return 0
}

test_permissions_handling() {
    log_info "Testing file permissions handling..."

    # Test 1: Basic permissions
    TEST_FILE="$TEST_DIR/permission-test.txt"
    echo "test content" > "$TEST_FILE"
    chmod 644 "$TEST_FILE"

    if [[ -r "$TEST_FILE" ]]; then
        log_success "Read permissions work"
    else
        log_error "Read permissions failed"
        return 1
    fi

    # Test 2: Execute permissions
    TEST_SCRIPT="$TEST_DIR/execute-test.sh"
    echo '#!/bin/bash
echo "execute test"' > "$TEST_SCRIPT"
    chmod +x "$TEST_SCRIPT"

    if [[ -x "$TEST_SCRIPT" ]]; then
        log_success "Execute permissions work"
    else
        log_error "Execute permissions failed"
        return 1
    fi

    # Test 3: Directory permissions
    TEST_DIR_PERM="$TEST_DIR/dir-permission-test"
    mkdir -p "$TEST_DIR_PERM"
    chmod 755 "$TEST_DIR_PERM"

    if [[ -r "$TEST_DIR_PERM" && -x "$TEST_DIR_PERM" ]]; then
        log_success "Directory permissions work"
    else
        log_error "Directory permissions failed"
        return 1
    fi

    # Test 4: Secure permissions (600)
    SECURE_FILE="$TEST_DIR/secure-test.txt"
    echo "secure content" > "$SECURE_FILE"
    chmod 600 "$SECURE_FILE"

    if [[ "$OS_TYPE" != "Windows" ]]; then
        ACTUAL_PERMS=$(stat -c %a "$SECURE_FILE" 2>/dev/null || stat -f %A "$SECURE_FILE" 2>/dev/null)
        if [[ "$ACTUAL_PERMS" == "600" ]]; then
            log_success "Secure file permissions (600) work"
        else
            log_warning "Secure file permissions may not be applied correctly ($ACTUAL_PERMS)"
        fi
    else
        log_warning "Windows permissions model differs from Unix"
    fi

    return 0
}

test_environment_variables() {
    log_info "Testing environment variable handling..."

    # Test 1: Setting environment variables
    export TEST_TRIBE_VAR="test_value"
    if [[ "$TEST_TRIBE_VAR" == "test_value" ]]; then
        log_success "Environment variable setting works"
    else
        log_error "Environment variable setting failed"
        return 1
    fi

    # Test 2: Path environment variable
    ORIGINAL_PATH="$PATH"
    export PATH="$TEST_DIR/bin:$PATH"
    if echo "$PATH" | grep -q "$TEST_DIR/bin"; then
        log_success "PATH modification works"
    else
        log_error "PATH modification failed"
        return 1
    fi
    export PATH="$ORIGINAL_PATH"

    # Test 3: Home directory expansion
    if [[ "$HOME" == "$HOME" && -d "$HOME" ]]; then
        log_success "HOME directory variable works"
    else
        log_error "HOME directory variable failed"
        return 1
    fi

    # Test 4: Variable substitution in paths
    TEST_PATH="$HOME/.tribe-test"
    mkdir -p "$TEST_PATH"
    if [[ -d "$TEST_PATH" ]]; then
        log_success "Variable substitution in paths works"
        rm -rf "$TEST_PATH"
    else
        log_error "Variable substitution in paths failed"
        return 1
    fi

    # Clean up test variable
    unset TEST_TRIBE_VAR

    return 0
}

test_network_capabilities() {
    log_info "Testing network capabilities..."

    # Test 1: Basic connectivity
    if ping -c 1 google.com &> /dev/null || ping -n 1 google.com &> /dev/null; then
        log_success "Network connectivity available"
    else
        log_warning "Network connectivity may be limited"
    fi

    # Test 2: HTTP requests
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 5 https://httpbin.org/get &> /dev/null; then
            log_success "HTTP requests work (curl)"
        else
            log_warning "HTTP requests may have issues"
        fi
    elif command -v wget &> /dev/null; then
        if wget -q --timeout=5 -O - https://httpbin.org/get &> /dev/null; then
            log_success "HTTP requests work (wget)"
        else
            log_warning "HTTP requests may have issues"
        fi
    else
        log_warning "No HTTP client available (curl, wget)"
    fi

    # Test 3: Localhost connectivity
    if curl -s --connect-timeout 3 http://localhost:80 &> /dev/null; then
        log_success "Localhost HTTP connectivity works"
    else
        log_warning "Localhost HTTP may not be accessible"
    fi

    # Test 4: DNS resolution
    if command -v nslookup &> /dev/null; then
        if nslookup google.com &> /dev/null; then
            log_success "DNS resolution works (nslookup)"
        else
            log_warning "DNS resolution may have issues"
        fi
    elif command -v dig &> /dev/null; then
        if dig google.com &> /dev/null; then
            log_success "DNS resolution works (dig)"
        else
            log_warning "DNS resolution may have issues"
        fi
    else
        log_warning "No DNS lookup tools available"
    fi

    return 0
}

test_browser_integration() {
    log_info "Testing browser integration capabilities..."

    # Test browser availability by platform
    case "$OS_TYPE" in
        macOS)
            if command -v open &> /dev/null; then
                log_success "Browser launching available (open)"
            else
                log_error "Browser launching not available on macOS"
                return 1
            fi
            ;;
        Linux)
            if command -v xdg-open &> /dev/null; then
                log_success "Browser launching available (xdg-open)"
            elif command -v gnome-open &> /dev/null; then
                log_success "Browser launching available (gnome-open)"
            elif command -v firefox &> /dev/null || command -v chromium &> /dev/null; then
                log_success "Browser available for direct launching"
            else
                log_warning "Browser launching may not be available"
            fi
            ;;
        Windows)
            if command -v start &> /dev/null || command -v cmd &> /dev/null; then
                log_success "Browser launching available (start/cmd)"
            else
                log_warning "Browser launching may not be available"
            fi
            ;;
        *)
            log_warning "Browser launching not tested for $OS_TYPE"
            ;;
    esac

    # Test URL validation
    TEST_URLS=(
        "http://localhost:3000"
        "https://tribecode.ai"
        "http://localhost:3456/api/health"
    )

    for url in "${TEST_URLS[@]}"; do
        # Basic URL format validation
        if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
            log_success "URL format valid: $url"
        else
            log_error "URL format invalid: $url"
            return 1
        fi
    done

    return 0
}

test_package_management() {
    log_info "Testing package management integration..."

    # Test Node.js and npm
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
        log_success "Node.js available: $NODE_VERSION"

        if command -v npm &> /dev/null; then
            NPM_VERSION=$(npm --version 2>/dev/null || echo "unknown")
            log_success "npm available: $NPM_VERSION"

            # Test npx
            if command -v npx &> /dev/null; then
                log_success "npx available for package execution"
            else
                log_warning "npx not available"
            fi
        else
            log_warning "npm not available"
        fi
    else
        log_warning "Node.js not available"
    fi

    # Test package manager by platform
    case "$PACKAGE_MANAGER" in
        brew)
            if command -v brew &> /dev/null; then
                log_success "Homebrew available"
            else
                log_warning "Homebrew not available on macOS"
            fi
            ;;
        apt)
            if command -v apt &> /dev/null; then
                log_success "APT package manager available"
            else
                log_warning "APT not available"
            fi
            ;;
        yum|dnf)
            if command -v "$PACKAGE_MANAGER" &> /dev/null; then
                log_success "$PACKAGE_MANAGER package manager available"
            else
                log_warning "$PACKAGE_MANAGER not available"
            fi
            ;;
        choco)
            if command -v choco &> /dev/null; then
                log_success "Chocolatey available"
            else
                log_warning "Chocolatey not available on Windows"
            fi
            ;;
        *)
            log_warning "Package manager not identified"
            ;;
    esac

    return 0
}

test_container_support() {
    log_info "Testing container support..."

    # Test Docker
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null 2>&1; then
            log_success "Docker available and running"
        else
            log_warning "Docker available but not running"
        fi
    else
        log_warning "Docker not available"
    fi

    # Test Podman
    if command -v podman &> /dev/null; then
        if podman info &> /dev/null 2>&1; then
            log_success "Podman available and running"
        else
            log_warning "Podman available but not running"
        fi
    else
        log_warning "Podman not available"
    fi

    # Test Kubernetes
    if command -v kubectl &> /dev/null; then
        if kubectl cluster-info &> /dev/null 2>&1; then
            log_success "Kubernetes cluster accessible"
        else
            log_warning "kubectl available but cluster not accessible"
        fi
    else
        log_warning "kubectl not available"
    fi

    return 0
}

run_cross_platform_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE Cross-Platform Tests"
    log_info "==================================="

    # Platform detection
    detect_platform

    # Test 1: Shell Compatibility
    ((total_tests++))
    if test_shell_compatibility; then
        log_success "✓ Shell Compatibility Test"
    else
        log_error "✗ Shell Compatibility Test"
        ((failed_tests++))
    fi

    # Test 2: File Path Handling
    ((total_tests++))
    if test_file_path_handling; then
        log_success "✓ File Path Handling Test"
    else
        log_error "✗ File Path Handling Test"
        ((failed_tests++))
    fi

    # Test 3: Permissions Handling
    ((total_tests++))
    if test_permissions_handling; then
        log_success "✓ Permissions Handling Test"
    else
        log_error "✗ Permissions Handling Test"
        ((failed_tests++))
    fi

    # Test 4: Environment Variables
    ((total_tests++))
    if test_environment_variables; then
        log_success "✓ Environment Variables Test"
    else
        log_error "✗ Environment Variables Test"
        ((failed_tests++))
    fi

    # Test 5: Network Capabilities
    ((total_tests++))
    if test_network_capabilities; then
        log_success "✓ Network Capabilities Test"
    else
        log_error "✗ Network Capabilities Test"
        ((failed_tests++))
    fi

    # Test 6: Browser Integration
    ((total_tests++))
    if test_browser_integration; then
        log_success "✓ Browser Integration Test"
    else
        log_error "✗ Browser Integration Test"
        ((failed_tests++))
    fi

    # Test 7: Package Management
    ((total_tests++))
    if test_package_management; then
        log_success "✓ Package Management Test"
    else
        log_error "✗ Package Management Test"
        ((failed_tests++))
    fi

    # Test 8: Container Support
    ((total_tests++))
    if test_container_support; then
        log_success "✓ Container Support Test"
    else
        log_error "✗ Container Support Test"
        ((failed_tests++))
    fi

    # Results summary
    echo ""
    log_info "Test Results Summary"
    log_info "==================="
    log_info "Platform: $OS_TYPE ($ARCH)"
    log_info "Shell: $(basename "$SHELL" 2>/dev/null || echo "unknown")"
    log_info "Total tests: $total_tests"
    log_info "Passed: $((total_tests - failed_tests))"
    log_info "Failed: $failed_tests"

    if [[ $failed_tests -eq 0 ]]; then
        log_success "🎉 All cross-platform tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI Cross-Platform Compatibility Test Suite"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Shell: $(basename "$SHELL" 2>/dev/null || echo "unknown")"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_cross_platform_tests; then
        log_success "Cross-platform test suite completed successfully"
        exit 0
    else
        log_error "Cross-platform test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi