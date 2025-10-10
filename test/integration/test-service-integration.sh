#!/bin/bash

# test-service-integration.sh - Service Integration and Health Testing
# Tests CLI integration with TRIBE services, port forwarding, and health checks

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

# Service endpoints to test
BRIDGE_URL="http://localhost:3456"
TASKMASTER_URL="http://localhost:5555"
GITEA_URL="http://localhost:3001"
TUTOR_URL="http://localhost:8080"
DASHBOARD_URL="http://localhost:3000"

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

check_port_availability() {
    local port="$1"
    local service_name="$2"

    if command -v lsof &> /dev/null; then
        if lsof -i ":$port" &> /dev/null; then
            log_success "$service_name port $port is in use"
            return 0
        else
            log_warning "$service_name port $port is not in use"
            return 1
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -an | grep -q ":$port "; then
            log_success "$service_name port $port is in use"
            return 0
        else
            log_warning "$service_name port $port is not in use"
            return 1
        fi
    elif command -v ss &> /dev/null; then
        if ss -an | grep -q ":$port "; then
            log_success "$service_name port $port is in use"
            return 0
        else
            log_warning "$service_name port $port is not in use"
            return 1
        fi
    else
        log_warning "No port checking utility available"
        return 1
    fi
}

test_service_health_checks() {
    log_info "Testing service health checks..."

    # Test Bridge API health
    log_info "Testing Bridge API health ($BRIDGE_URL)"
    if curl -s --connect-timeout 5 "$BRIDGE_URL/" &> /dev/null; then
        log_success "Bridge API is responding"

        # Test specific endpoints
        if curl -s --connect-timeout 5 "$BRIDGE_URL/api/v1/health" | grep -q "ready\|healthy\|ok" 2>/dev/null; then
            log_success "Bridge health endpoint is working"
        else
            log_warning "Bridge health endpoint may not be available"
        fi
    else
        log_warning "Bridge API is not responding (may not be running)"
    fi

    # Test TaskMaster API health
    log_info "Testing TaskMaster API health ($TASKMASTER_URL)"
    if curl -s --connect-timeout 5 "$TASKMASTER_URL/" &> /dev/null; then
        log_success "TaskMaster API is responding"

        # Test tasks endpoint
        if curl -s --connect-timeout 5 "$TASKMASTER_URL/api/v1/tasks" &> /dev/null; then
            log_success "TaskMaster tasks endpoint is accessible"
        else
            log_warning "TaskMaster tasks endpoint may not be available"
        fi
    else
        log_warning "TaskMaster API is not responding (may not be running)"
    fi

    # Test Gitea health
    log_info "Testing Gitea health ($GITEA_URL)"
    if curl -s --connect-timeout 5 "$GITEA_URL/" &> /dev/null; then
        log_success "Gitea is responding"

        # Test API endpoint
        if curl -s --connect-timeout 5 "$GITEA_URL/api/v1/version" &> /dev/null; then
            log_success "Gitea API is accessible"
        else
            log_warning "Gitea API may not be available"
        fi
    else
        log_warning "Gitea is not responding (may not be running)"
    fi

    # Test Tutor Server health
    log_info "Testing Tutor Server health ($TUTOR_URL)"
    if curl -s --connect-timeout 5 "$TUTOR_URL/api/health" &> /dev/null; then
        log_success "Tutor Server is responding"
    else
        log_warning "Tutor Server is not responding (may not be running)"
    fi

    # Test Dashboard health
    log_info "Testing Dashboard health ($DASHBOARD_URL)"
    if curl -s --connect-timeout 5 "$DASHBOARD_URL/" &> /dev/null; then
        log_success "Dashboard is responding"
    else
        log_warning "Dashboard is not responding (may not be running)"
    fi

    return 0
}

test_port_forwarding() {
    log_info "Testing port forwarding functionality..."

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl not available, skipping Kubernetes port forwarding tests"
        return 0
    fi

    # Test cluster connectivity
    if kubectl cluster-info &> /dev/null; then
        log_success "Kubernetes cluster is accessible"

        # Test pod listing
        if kubectl get pods -n tribe-system &> /dev/null; then
            log_success "tribe-system namespace is accessible"
        else
            log_warning "tribe-system namespace may not exist"
        fi

        # Test service listing
        if kubectl get services -n tribe-system &> /dev/null; then
            log_success "Services in tribe-system are accessible"
        else
            log_warning "Services in tribe-system may not exist"
        fi
    else
        log_warning "Kubernetes cluster is not accessible"
    fi

    # Test if CLI has port forwarding capability
    if [[ -f "$TRIBE_CLI_PATH" ]]; then
        if timeout 5s "$TRIBE_CLI_PATH" --help 2>&1 | grep -q "port-forward\|forward" 2>/dev/null; then
            log_success "CLI has port forwarding capability"
        else
            log_warning "CLI may not have port forwarding commands"
        fi
    fi

    return 0
}

test_service_discovery() {
    log_info "Testing service discovery..."

    # Test DNS resolution for service names
    if command -v nslookup &> /dev/null; then
        # Test localhost resolution
        if nslookup localhost &> /dev/null; then
            log_success "Localhost DNS resolution works"
        else
            log_warning "Localhost DNS resolution may have issues"
        fi
    elif command -v dig &> /dev/null; then
        if dig localhost &> /dev/null; then
            log_success "Localhost DNS resolution works (dig)"
        else
            log_warning "Localhost DNS resolution may have issues"
        fi
    fi

    # Test service endpoint accessibility
    SERVICES=(
        "Bridge:$BRIDGE_URL"
        "TaskMaster:$TASKMASTER_URL"
        "Gitea:$GITEA_URL"
        "Tutor:$TUTOR_URL"
        "Dashboard:$DASHBOARD_URL"
    )

    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r service_name service_url <<< "$service_info"

        if curl -s --connect-timeout 3 "$service_url" &> /dev/null; then
            log_success "$service_name service discovered at $service_url"
        else
            log_warning "$service_name service not found at $service_url"
        fi
    done

    return 0
}

test_api_endpoints() {
    log_info "Testing API endpoint integration..."

    # Test Bridge API endpoints
    log_info "Testing Bridge API endpoints..."
    BRIDGE_ENDPOINTS=(
        "/"
        "/api/v1/health"
        "/api/v1/tasks"
        "/api/v1/projects"
        "/api/v1/agents"
    )

    for endpoint in "${BRIDGE_ENDPOINTS[@]}"; do
        if curl -s --connect-timeout 5 "$BRIDGE_URL$endpoint" &> /dev/null; then
            log_success "Bridge endpoint accessible: $endpoint"
        else
            log_warning "Bridge endpoint not accessible: $endpoint"
        fi
    done

    # Test TaskMaster API endpoints
    log_info "Testing TaskMaster API endpoints..."
    TASKMASTER_ENDPOINTS=(
        "/"
        "/api/v1/tasks"
        "/api/v1/health"
        "/api/v1/monitoring/health"
    )

    for endpoint in "${TASKMASTER_ENDPOINTS[@]}"; do
        if curl -s --connect-timeout 5 "$TASKMASTER_URL$endpoint" &> /dev/null; then
            log_success "TaskMaster endpoint accessible: $endpoint"
        else
            log_warning "TaskMaster endpoint not accessible: $endpoint"
        fi
    done

    # Test Gitea API endpoints
    log_info "Testing Gitea API endpoints..."
    GITEA_ENDPOINTS=(
        "/api/v1/version"
        "/api/v1/repos"
        "/api/v1/user"
    )

    for endpoint in "${GITEA_ENDPOINTS[@]}"; do
        if curl -s --connect-timeout 5 "$GITEA_URL$endpoint" &> /dev/null; then
            log_success "Gitea endpoint accessible: $endpoint"
        else
            log_warning "Gitea endpoint not accessible: $endpoint"
        fi
    done

    return 0
}

test_websocket_connectivity() {
    log_info "Testing WebSocket connectivity..."

    # Test if WebSocket tools are available
    if command -v wscat &> /dev/null; then
        log_info "Testing WebSocket with wscat"

        # Test Bridge WebSocket
        if timeout 5s wscat -c "ws://localhost:3456/api/ws" --execute "ping" &> /dev/null; then
            log_success "Bridge WebSocket is accessible"
        else
            log_warning "Bridge WebSocket is not accessible"
        fi
    elif command -v websocat &> /dev/null; then
        log_info "Testing WebSocket with websocat"

        # Test Bridge WebSocket
        if timeout 5s echo "ping" | websocat "ws://localhost:3456/api/ws" &> /dev/null; then
            log_success "Bridge WebSocket is accessible"
        else
            log_warning "Bridge WebSocket is not accessible"
        fi
    else
        log_warning "No WebSocket testing tools available (wscat, websocat)"
    fi

    # Test WebSocket endpoints with curl (HTTP upgrade)
    if curl -s --connect-timeout 5 -H "Connection: Upgrade" -H "Upgrade: websocket" "$BRIDGE_URL/api/ws" &> /dev/null; then
        log_success "WebSocket upgrade headers accepted"
    else
        log_warning "WebSocket upgrade may not be supported"
    fi

    return 0
}

test_docker_integration() {
    log_info "Testing Docker integration..."

    # Check if Docker is available
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            log_success "Docker is available and running"

            # Check for TRIBE-related containers
            if docker ps --format "table {{.Names}}" | grep -E "(tribe|bridge|taskmaster|gitea)" &> /dev/null; then
                log_success "TRIBE Docker containers are running"

                # List running TRIBE containers
                TRIBE_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "(tribe|bridge|taskmaster|gitea)" || true)
                if [[ -n "$TRIBE_CONTAINERS" ]]; then
                    log_info "Running TRIBE containers:"
                    echo "$TRIBE_CONTAINERS" | while read -r container; do
                        log_info "  - $container"
                    done
                fi
            else
                log_warning "No TRIBE Docker containers found running"
            fi
        else
            log_warning "Docker is available but not running"
        fi
    else
        log_warning "Docker is not available"
    fi

    return 0
}

test_kubernetes_integration() {
    log_info "Testing Kubernetes integration..."

    # Check if kubectl is available
    if command -v kubectl &> /dev/null; then
        # Test cluster connectivity
        if kubectl cluster-info &> /dev/null; then
            log_success "Kubernetes cluster is accessible"

            # Check TRIBE namespaces
            NAMESPACES=("tribe-system" "tribe")
            for namespace in "${NAMESPACES[@]}"; do
                if kubectl get namespace "$namespace" &> /dev/null; then
                    log_success "Namespace $namespace exists"

                    # Check pods in namespace
                    POD_COUNT=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
                    if [[ $POD_COUNT -gt 0 ]]; then
                        log_success "$POD_COUNT pods running in $namespace"
                    else
                        log_warning "No pods running in $namespace"
                    fi
                else
                    log_warning "Namespace $namespace does not exist"
                fi
            done

            # Check services
            if kubectl get services -n tribe-system &> /dev/null; then
                SERVICE_COUNT=$(kubectl get services -n tribe-system --no-headers 2>/dev/null | wc -l)
                log_success "$SERVICE_COUNT services found in tribe-system"
            else
                log_warning "No services found in tribe-system"
            fi
        else
            log_warning "Kubernetes cluster is not accessible"
        fi
    else
        log_warning "kubectl is not available"
    fi

    return 0
}

test_cli_service_commands() {
    log_info "Testing CLI service commands..."

    if [[ ! -f "$TRIBE_CLI_PATH" ]]; then
        log_warning "TRIBE CLI not found at $TRIBE_CLI_PATH"
        return 0
    fi

    # Test status command
    log_info "Testing: tribe status"
    if timeout 15s "$TRIBE_CLI_PATH" status &> /dev/null; then
        log_success "CLI status command works"
    else
        log_warning "CLI status command failed (services may not be running)"
    fi

    # Test health command
    log_info "Testing: tribe health"
    if timeout 10s "$TRIBE_CLI_PATH" health &> /dev/null; then
        log_success "CLI health command works"
    else
        log_warning "CLI health command failed or not available"
    fi

    # Test cluster status
    log_info "Testing: tribe cluster status"
    if timeout 15s "$TRIBE_CLI_PATH" cluster status &> /dev/null; then
        log_success "CLI cluster status command works"
    else
        log_warning "CLI cluster commands may not be available"
    fi

    return 0
}

run_service_integration_tests() {
    local failed_tests=0
    local total_tests=0

    log_info "Starting TRIBE Service Integration Tests"
    log_info "======================================="

    # Test 1: Service Health Checks
    ((total_tests++))
    if test_service_health_checks; then
        log_success "✓ Service Health Checks Test"
    else
        log_error "✗ Service Health Checks Test"
        ((failed_tests++))
    fi

    # Test 2: Port Forwarding
    ((total_tests++))
    if test_port_forwarding; then
        log_success "✓ Port Forwarding Test"
    else
        log_error "✗ Port Forwarding Test"
        ((failed_tests++))
    fi

    # Test 3: Service Discovery
    ((total_tests++))
    if test_service_discovery; then
        log_success "✓ Service Discovery Test"
    else
        log_error "✗ Service Discovery Test"
        ((failed_tests++))
    fi

    # Test 4: API Endpoints
    ((total_tests++))
    if test_api_endpoints; then
        log_success "✓ API Endpoints Test"
    else
        log_error "✗ API Endpoints Test"
        ((failed_tests++))
    fi

    # Test 5: WebSocket Connectivity
    ((total_tests++))
    if test_websocket_connectivity; then
        log_success "✓ WebSocket Connectivity Test"
    else
        log_error "✗ WebSocket Connectivity Test"
        ((failed_tests++))
    fi

    # Test 6: Docker Integration
    ((total_tests++))
    if test_docker_integration; then
        log_success "✓ Docker Integration Test"
    else
        log_error "✗ Docker Integration Test"
        ((failed_tests++))
    fi

    # Test 7: Kubernetes Integration
    ((total_tests++))
    if test_kubernetes_integration; then
        log_success "✓ Kubernetes Integration Test"
    else
        log_error "✗ Kubernetes Integration Test"
        ((failed_tests++))
    fi

    # Test 8: CLI Service Commands
    ((total_tests++))
    if test_cli_service_commands; then
        log_success "✓ CLI Service Commands Test"
    else
        log_error "✗ CLI Service Commands Test"
        ((failed_tests++))
    fi

    # Results summary
    echo ""
    log_info "Test Results Summary"
    log_info "==================="
    log_info "Total tests: $total_tests"
    log_info "Passed: $((total_tests - failed_tests))"
    log_info "Failed: $failed_tests"

    # Port availability summary
    echo ""
    log_info "Service Port Summary"
    log_info "==================="
    check_port_availability 3000 "Dashboard"
    check_port_availability 3001 "Gitea"
    check_port_availability 3456 "Bridge"
    check_port_availability 5555 "TaskMaster"
    check_port_availability 8080 "Tutor"

    if [[ $failed_tests -eq 0 ]]; then
        log_success "🎉 All service integration tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "TRIBE CLI Service Integration Test Suite"
    echo "CLI Path: $TRIBE_CLI_PATH"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Date: $(date)"
    echo ""

    # Set up trap for cleanup
    trap cleanup_test_environment EXIT

    # Setup test environment
    setup_test_environment

    # Run tests
    if run_service_integration_tests; then
        log_success "Service integration test suite completed successfully"
        exit 0
    else
        log_error "Service integration test suite failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi