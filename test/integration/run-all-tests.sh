#!/bin/bash

# run-all-tests.sh - Master Test Runner for TRIBE CLI Integration Tests
# Executes all integration test suites and provides comprehensive reporting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_RESULTS_FILE="$SCRIPT_DIR/test-results-$(date +%Y%m%d-%H%M%S).log"
TRIBE_CLI_PATH="${TRIBE_CLI_PATH:-/Users/almorris/TRIBE/0zen/bin/tribe}"

# Test suites
TEST_SUITES=(
    "test-installation.sh:Installation Flow Tests"
    "test-configuration.sh:Configuration System Tests"
    "test-cli-commands.sh:CLI Command Tests"
    "test-oauth-flow.sh:OAuth Authentication Tests"
    "test-service-integration.sh:Service Integration Tests"
    "test-cross-platform.sh:Cross-Platform Tests"
    "test-documentation.sh:Documentation Validation Tests"
)

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$TEST_RESULTS_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$TEST_RESULTS_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$TEST_RESULTS_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_RESULTS_FILE"
}

log_header() {
    echo -e "${CYAN}${BOLD}$1${NC}" | tee -a "$TEST_RESULTS_FILE"
}

show_usage() {
    cat << EOF
TRIBE CLI Integration Test Suite

Usage: $0 [OPTIONS] [TEST_SUITE]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -q, --quick         Run quick tests only (skip slow tests)
    -f, --fail-fast     Stop on first test failure
    -o, --output FILE   Write results to specific file
    -c, --cli PATH      Specify TRIBE CLI binary path

TEST_SUITES:
    installation        Test NPX installation flow
    configuration       Test configuration system
    commands            Test CLI commands
    oauth               Test OAuth authentication
    services            Test service integration
    platform            Test cross-platform compatibility
    documentation       Test documentation accuracy
    all                 Run all test suites (default)

EXAMPLES:
    $0                          # Run all tests
    $0 --quick                  # Run quick tests only
    $0 --fail-fast installation # Run installation tests, stop on failure
    $0 commands oauth           # Run specific test suites
    $0 --cli /path/to/tribe     # Use specific CLI binary

ENVIRONMENT VARIABLES:
    TRIBE_CLI_PATH     Path to TRIBE CLI binary
    TRIBE_HOME         Custom home directory for tests
    TEST_QUICK         Set to 1 for quick tests only
    TEST_VERBOSE       Set to 1 for verbose output

EOF
}

parse_arguments() {
    VERBOSE=false
    QUICK=false
    FAIL_FAST=false
    SELECTED_TESTS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                export TEST_VERBOSE=1
                shift
                ;;
            -q|--quick)
                QUICK=true
                export TEST_QUICK=1
                shift
                ;;
            -f|--fail-fast)
                FAIL_FAST=true
                shift
                ;;
            -o|--output)
                TEST_RESULTS_FILE="$2"
                shift 2
                ;;
            -c|--cli)
                TRIBE_CLI_PATH="$2"
                export TRIBE_CLI_PATH="$2"
                shift 2
                ;;
            installation|configuration|commands|oauth|services|platform|documentation|all)
                SELECTED_TESTS+=("$1")
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Default to all tests if none specified
    if [[ ${#SELECTED_TESTS[@]} -eq 0 ]]; then
        SELECTED_TESTS=("all")
    fi
}

check_prerequisites() {
    log_info "Checking test prerequisites..."

    # Check if we're in the right directory
    if [[ ! -f "$SCRIPT_DIR/test-installation.sh" ]]; then
        log_error "Test scripts not found in current directory"
        log_error "Please run this script from the integration test directory"
        exit 1
    fi

    # Check CLI binary if specified
    if [[ -n "$TRIBE_CLI_PATH" ]] && [[ ! -f "$TRIBE_CLI_PATH" ]]; then
        log_warning "TRIBE CLI binary not found at: $TRIBE_CLI_PATH"
        log_warning "Some tests may be skipped"
    fi

    # Check required utilities
    REQUIRED_UTILS=("curl" "jq")
    MISSING_UTILS=()

    for util in "${REQUIRED_UTILS[@]}"; do
        if ! command -v "$util" &> /dev/null; then
            MISSING_UTILS+=("$util")
        fi
    done

    if [[ ${#MISSING_UTILS[@]} -gt 0 ]]; then
        log_warning "Missing utilities: ${MISSING_UTILS[*]}"
        log_warning "Some tests may be skipped or fail"
    fi

    log_success "Prerequisites check completed"
}

run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    local start_time
    local end_time
    local duration

    log_header ""
    log_header "Running: $test_name"
    log_header "Script: $test_script"
    log_header "$(printf '=%.0s' {1..60})"

    start_time=$(date +%s)

    # Run the test suite
    if [[ "$VERBOSE" == true ]]; then
        if "$SCRIPT_DIR/$test_script"; then
            local exit_code=0
        else
            local exit_code=$?
        fi
    else
        if "$SCRIPT_DIR/$test_script" 2>&1 | tee -a "$TEST_RESULTS_FILE"; then
            local exit_code=0
        else
            local exit_code=$?
        fi
    fi

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo "" | tee -a "$TEST_RESULTS_FILE"
    if [[ $exit_code -eq 0 ]]; then
        log_success "✅ $test_name completed successfully in ${duration}s"
    else
        log_error "❌ $test_name failed after ${duration}s"
    fi

    return $exit_code
}

generate_test_report() {
    local total_tests="$1"
    local passed_tests="$2"
    local failed_tests="$3"
    local start_time="$4"
    local end_time="$5"

    local duration=$((end_time - start_time))
    local success_rate=0

    if [[ $total_tests -gt 0 ]]; then
        success_rate=$((passed_tests * 100 / total_tests))
    fi

    log_header ""
    log_header "TRIBE CLI Integration Test Results"
    log_header "=================================="
    log_info "Test run completed on: $(date)"
    log_info "Platform: $(uname -s) $(uname -m)"
    log_info "CLI Path: $TRIBE_CLI_PATH"
    log_info "Duration: ${duration}s"
    log_info ""
    log_info "Results Summary:"
    log_info "  Total test suites: $total_tests"
    log_info "  Passed: $passed_tests"
    log_info "  Failed: $failed_tests"
    log_info "  Success rate: ${success_rate}%"
    log_header ""

    if [[ $failed_tests -eq 0 ]]; then
        log_success "🎉 All integration tests passed!"
        log_info "Results saved to: $TEST_RESULTS_FILE"
    else
        log_error "❌ $failed_tests test suite(s) failed"
        log_info "Check the detailed results in: $TEST_RESULTS_FILE"
    fi
}

run_selected_tests() {
    local selected_tests=("$@")
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local start_time
    local end_time

    start_time=$(date +%s)

    # Determine which tests to run
    local tests_to_run=()

    for selection in "${selected_tests[@]}"; do
        case "$selection" in
            installation)
                tests_to_run+=("test-installation.sh:Installation Flow Tests")
                ;;
            configuration)
                tests_to_run+=("test-configuration.sh:Configuration System Tests")
                ;;
            commands)
                tests_to_run+=("test-cli-commands.sh:CLI Command Tests")
                ;;
            oauth)
                tests_to_run+=("test-oauth-flow.sh:OAuth Authentication Tests")
                ;;
            services)
                tests_to_run+=("test-service-integration.sh:Service Integration Tests")
                ;;
            platform)
                tests_to_run+=("test-cross-platform.sh:Cross-Platform Tests")
                ;;
            documentation)
                tests_to_run+=("test-documentation.sh:Documentation Validation Tests")
                ;;
            all)
                tests_to_run=("${TEST_SUITES[@]}")
                ;;
        esac
    done

    # Remove duplicates
    local unique_tests=()
    for test in "${tests_to_run[@]}"; do
        local found=false
        for unique in "${unique_tests[@]}"; do
            if [[ "$test" == "$unique" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            unique_tests+=("$test")
        fi
    done

    log_header "TRIBE CLI Integration Test Suite"
    log_header "Starting test run with ${#unique_tests[@]} test suite(s)"
    log_info "Date: $(date)"
    log_info "Platform: $(uname -s) $(uname -m)"
    log_info "CLI Path: $TRIBE_CLI_PATH"
    log_info "Results file: $TEST_RESULTS_FILE"

    # Run each test suite
    for test_info in "${unique_tests[@]}"; do
        IFS=':' read -r test_script test_name <<< "$test_info"

        ((total_tests++))

        if run_test_suite "$test_script" "$test_name"; then
            ((passed_tests++))
        else
            ((failed_tests++))
            if [[ "$FAIL_FAST" == true ]]; then
                log_error "Stopping due to --fail-fast option"
                break
            fi
        fi
    done

    end_time=$(date +%s)
    generate_test_report "$total_tests" "$passed_tests" "$failed_tests" "$start_time" "$end_time"

    # Return appropriate exit code
    if [[ $failed_tests -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Main execution
main() {
    # Initialize test results file
    echo "TRIBE CLI Integration Test Run - $(date)" > "$TEST_RESULTS_FILE"
    echo "================================================================" >> "$TEST_RESULTS_FILE"
    echo "" >> "$TEST_RESULTS_FILE"

    # Parse command line arguments
    parse_arguments "$@"

    # Check prerequisites
    check_prerequisites

    # Run selected tests
    if run_selected_tests "${SELECTED_TESTS[@]}"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi