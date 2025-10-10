# TRIBE CLI Integration Testing Guide

## Overview

This comprehensive testing suite validates the complete TRIBE CLI functionality from installation through daily usage. The tests ensure quality delivery across platforms and user experiences.

## Quick Start

```bash
# Run all tests
cd /Users/almorris/TRIBE/tribe-api/test/integration
./run-all-tests.sh

# Run specific test suites
./run-all-tests.sh installation oauth
./run-all-tests.sh --quick
./run-all-tests.sh --fail-fast commands

# Run individual test script
./test-installation.sh
```

## Test Suites

### 1. Installation Flow Tests (`test-installation.sh`)
**Purpose**: Validates NPX installation, binary download, and directory setup.

**Tests**:
- NPX package availability and execution
- Binary download and platform detection
- `~/.tribe` directory structure creation
- Version and help command functionality
- Configuration file initialization
- Platform compatibility checks

**Key Validations**:
- ✅ NPX command works: `npx @_xtribe/cli@latest`
- ✅ Binary execution: `tribe --version`, `tribe --help`
- ✅ Directory structure: `~/.tribe/{bin,config,tutor,logs}`
- ✅ File permissions: 755 for directories, 644 for files
- ✅ Cross-platform path handling

### 2. CLI Command Tests (`test-cli-commands.sh`)
**Purpose**: Validates all CLI commands work correctly and handle errors properly.

**Tests**:
- Basic commands: `--version`, `--help`, `status`
- Tutor commands: `tutor enable`, `tutor disable`, `tutor status`, `tutor logs`
- Authentication commands: `login`, `logout`, `auth-status`
- Configuration commands: `config validate`, `config show`
- Error handling for invalid commands and arguments
- Command response time and performance

**Key Validations**:
- ✅ All documented commands are functional
- ✅ Help text matches documentation
- ✅ Error messages are clear and actionable
- ✅ Commands respond within reasonable time (<2 seconds)

### 3. Configuration System Tests (`test-configuration.sh`)
**Purpose**: Tests configuration file handling, validation, and directory management.

**Tests**:
- Configuration directory structure creation
- JSON configuration file validation
- Authentication file structure and permissions
- Environment variable handling
- Path handling (spaces, special characters, relative paths)
- Configuration migration between versions

**Key Validations**:
- ✅ Config files have valid JSON structure
- ✅ Auth files have secure permissions (600)
- ✅ Environment variables override config files
- ✅ Paths with spaces and special characters work
- ✅ Configuration validation catches errors

### 4. OAuth Authentication Tests (`test-oauth-flow.sh`)
**Purpose**: Tests OAuth authentication flow, token management, and credential storage.

**Tests**:
- OAuth configuration structure validation
- Token format and expiry validation
- Credential storage and retrieval
- Token refresh functionality
- Mock OAuth server simulation
- Error handling for invalid credentials

**Key Validations**:
- ✅ OAuth tokens have correct structure
- ✅ User info contains required fields
- ✅ Credential files have secure permissions
- ✅ Token expiry detection works
- ✅ Refresh tokens are preserved

### 5. Service Integration Tests (`test-service-integration.sh`)
**Purpose**: Tests integration with TRIBE services, health checks, and connectivity.

**Tests**:
- Service health endpoint checks
- Port forwarding functionality
- Service discovery and DNS resolution
- API endpoint accessibility
- WebSocket connectivity
- Docker and Kubernetes integration
- CLI service commands

**Key Validations**:
- ✅ Core services respond: Bridge (3456), TaskMaster (5555), Gitea (3001)
- ✅ API endpoints return expected responses
- ✅ WebSocket connections can be established
- ✅ Port forwarding works with kubectl
- ✅ Service discovery resolves correctly

### 6. Cross-Platform Tests (`test-cross-platform.sh`)
**Purpose**: Validates functionality across different operating systems and environments.

**Tests**:
- Shell compatibility (bash, zsh)
- File path handling across platforms
- Permissions management
- Environment variable handling
- Network capabilities
- Browser integration by platform
- Package management integration
- Container support detection

**Key Validations**:
- ✅ Works on macOS, Linux, Windows (WSL/Git Bash)
- ✅ File paths with spaces work across platforms
- ✅ Permissions are correctly applied
- ✅ Browser launching works per platform
- ✅ Network connectivity functions

### 7. Documentation Validation Tests (`test-documentation.sh`)
**Purpose**: Ensures documentation examples match actual CLI behavior.

**Tests**:
- Installation command accuracy
- CLI help output matches documentation
- Configuration examples are valid
- OAuth examples match actual structure
- Example commands work as documented
- Error messages match documentation
- URL and endpoint documentation
- Prerequisites are correctly documented

**Key Validations**:
- ✅ All documented commands exist and work
- ✅ Configuration examples are valid JSON
- ✅ URLs and ports match actual services
- ✅ Prerequisites are correctly stated
- ✅ Examples produce expected output

## Running Tests

### Prerequisites

**Required**:
- Bash 4.0+ (macOS users may need to upgrade)
- Node.js 16+ with npm/npx
- curl for HTTP requests
- jq for JSON processing (recommended)

**Optional**:
- kubectl for Kubernetes integration tests
- Docker for container tests
- Python3 for mock OAuth server

### Environment Variables

```bash
# Required
export TRIBE_CLI_PATH="/path/to/tribe/binary"

# Optional
export TRIBE_HOME="/custom/tribe/directory"
export TEST_QUICK=1              # Skip slow tests
export TEST_VERBOSE=1            # Enable verbose output
```

### Test Execution Options

```bash
# Run all tests (recommended for complete validation)
./run-all-tests.sh

# Quick tests only (for rapid feedback)
./run-all-tests.sh --quick

# Stop on first failure (for debugging)
./run-all-tests.sh --fail-fast

# Specific test suites
./run-all-tests.sh installation configuration
./run-all-tests.sh oauth services

# Custom CLI binary path
./run-all-tests.sh --cli /custom/path/to/tribe

# Save results to specific file
./run-all-tests.sh --output my-test-results.log

# Verbose output
./run-all-tests.sh --verbose
```

### Individual Test Scripts

Each test can be run independently:

```bash
./test-installation.sh          # Installation flow
./test-cli-commands.sh          # CLI commands
./test-configuration.sh         # Configuration system
./test-oauth-flow.sh           # OAuth authentication
./test-service-integration.sh  # Service integration
./test-cross-platform.sh      # Cross-platform compatibility
./test-documentation.sh        # Documentation validation
```

## Interpreting Results

### Success Indicators
- ✅ Green checkmarks indicate passed tests
- 🎉 All tests passed message at the end
- Exit code 0

### Warning Indicators
- ⚠️ Yellow warnings for non-critical issues
- Services not running (expected in some environments)
- Optional dependencies missing

### Failure Indicators
- ❌ Red X marks indicate failed tests
- Detailed error messages in output
- Exit code 1

### Sample Output

```
TRIBE CLI Integration Test Suite
Starting test run with 7 test suite(s)
Date: 2025-10-09 12:00:00
Platform: Darwin arm64
CLI Path: /Users/almorris/TRIBE/0zen/bin/tribe

Running: Installation Flow Tests
============================================================
[INFO] Testing NPX installation flow...
[SUCCESS] ✓ NPX Installation Test
[SUCCESS] ✓ Binary Download Test
[SUCCESS] ✓ Directory Creation Test
✅ Installation Flow Tests completed successfully in 15s

Running: CLI Command Tests
============================================================
[INFO] Testing basic CLI commands...
[SUCCESS] ✓ Basic Commands Test
[SUCCESS] ✓ Tutor Commands Test
✅ CLI Command Tests completed successfully in 12s

...

TRIBE CLI Integration Test Results
==================================
Test run completed on: Wed Oct  9 12:05:30 PDT 2025
Platform: Darwin arm64
CLI Path: /Users/almorris/TRIBE/0zen/bin/tribe
Duration: 89s

Results Summary:
  Total test suites: 7
  Passed: 7
  Failed: 0
  Success rate: 100%

🎉 All integration tests passed!
```

## Test Environment Isolation

Each test suite:
- Creates isolated test environment in `~/.tribe-test-$$`
- Backs up existing `~/.tribe` directory
- Restores original state on completion
- Uses process ID for unique directory names
- Cleans up temporary files automatically

## Troubleshooting

### Common Issues

**NPX Installation Fails**
```bash
# Check Node.js version
node --version  # Should be 16+

# Update npm
npm install -g npm@latest

# Clear npm cache
npm cache clean --force
```

**CLI Binary Not Found**
```bash
# Set explicit path
export TRIBE_CLI_PATH="/path/to/tribe"

# Check if binary exists and is executable
ls -la /Users/almorris/TRIBE/0zen/bin/tribe
```

**Permission Errors**
```bash
# Fix script permissions
chmod +x /Users/almorris/TRIBE/tribe-api/test/integration/*.sh

# Check directory permissions
ls -la ~/.tribe
```

**Service Connection Failures**
```bash
# Check if services are running
kubectl get pods -n tribe-system
curl http://localhost:3456/
curl http://localhost:5555/

# Start services if needed
cd ~/TRIBE && ./start.sh
```

**JSON Validation Errors**
```bash
# Install jq for better JSON validation
brew install jq  # macOS
sudo apt install jq  # Ubuntu/Debian
```

### Debugging Test Failures

1. **Run individual test script** to isolate the issue
2. **Use verbose mode**: `./run-all-tests.sh --verbose`
3. **Check test results file** for detailed error messages
4. **Verify prerequisites** are installed and accessible
5. **Check environment variables** are set correctly

### Platform-Specific Notes

**macOS**:
- May need to upgrade bash: `brew install bash`
- Ensure Xcode command line tools: `xcode-select --install`

**Linux**:
- Install curl: `sudo apt install curl`
- Install jq: `sudo apt install jq`

**Windows (WSL/Git Bash)**:
- Use WSL2 for best compatibility
- Install Windows subsystem dependencies
- May need to adjust path handling

## Test Development Guidelines

### Adding New Tests

1. **Create new test script** following naming convention: `test-feature.sh`
2. **Use common logging functions**: `log_info`, `log_success`, `log_warning`, `log_error`
3. **Include cleanup function** with trap on EXIT
4. **Add to TEST_SUITES array** in `run-all-tests.sh`
5. **Document in this guide**

### Test Script Structure

```bash
#!/bin/bash
set -euo pipefail

# Test configuration
TEST_DIR="$HOME/.tribe-test-$$"
BACKUP_DIR="$HOME/.tribe-backup-$$"

# Cleanup function
cleanup_test_environment() {
    # Remove test files
    # Restore original state
}

# Setup function
setup_test_environment() {
    # Create test environment
    # Backup existing state
}

# Individual test functions
test_feature_one() {
    log_info "Testing feature one..."
    # Test implementation
    return 0  # or 1 for failure
}

# Main test runner
run_feature_tests() {
    local failed_tests=0
    local total_tests=0

    # Run each test
    ((total_tests++))
    if test_feature_one; then
        log_success "✓ Feature One Test"
    else
        log_error "✗ Feature One Test"
        ((failed_tests++))
    fi

    # Return summary
    if [[ $failed_tests -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Main function
main() {
    trap cleanup_test_environment EXIT
    setup_test_environment
    run_feature_tests
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Continuous Integration

### GitHub Actions Integration

```yaml
name: TRIBE CLI Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]

    steps:
    - uses: actions/checkout@v2

    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '16'

    - name: Install dependencies
      run: |
        sudo apt-get update && sudo apt-get install -y curl jq  # Ubuntu
        # brew install jq  # macOS

    - name: Run integration tests
      run: |
        cd tribe-api/test/integration
        ./run-all-tests.sh --quick
```

### Local Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running TRIBE CLI integration tests..."
cd tribe-api/test/integration

if ! ./run-all-tests.sh --quick; then
    echo "❌ Integration tests failed. Commit aborted."
    exit 1
fi

echo "✅ Integration tests passed."
```

## Success Criteria Summary

The testing suite validates these critical success criteria:

- [ ] **NPX Installation**: `npx @_xtribe/cli@latest` works on all platforms
- [ ] **Core Commands**: All documented CLI commands are functional
- [ ] **Configuration**: Config system works with proper error handling
- [ ] **Authentication**: OAuth flow tested end-to-end
- [ ] **Service Integration**: Core services validated and accessible
- [ ] **Cross-Platform**: Compatibility confirmed across platforms
- [ ] **Documentation**: All examples work as documented

**Target**: 100% pass rate across all test suites with comprehensive validation of user experience from installation through daily usage.