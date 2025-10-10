# TRIBE CLI Integration Testing Suite

## Quick Start

```bash
# Run all tests
./run-all-tests.sh

# Run specific tests
./run-all-tests.sh installation oauth

# Quick tests only
./run-all-tests.sh --quick
```

## Test Scripts

| Script | Purpose | Key Tests |
|--------|---------|-----------|
| `test-installation.sh` | NPX installation flow | Package download, binary setup, directory creation |
| `test-cli-commands.sh` | CLI command validation | All commands, help text, error handling |
| `test-configuration.sh` | Configuration system | Config files, permissions, validation |
| `test-oauth-flow.sh` | OAuth authentication | Token management, credential storage |
| `test-service-integration.sh` | Service connectivity | Health checks, API endpoints, WebSocket |
| `test-cross-platform.sh` | Platform compatibility | File paths, permissions, browser integration |
| `test-documentation.sh` | Documentation accuracy | Examples match actual behavior |
| `run-all-tests.sh` | Master test runner | Orchestrates all test suites |

## Success Criteria

✅ **NPX Installation**: Package downloads and installs correctly
✅ **CLI Commands**: All documented commands work as expected
✅ **Configuration**: Config system handles errors gracefully
✅ **OAuth Authentication**: End-to-end auth flow validated
✅ **Service Integration**: Core services accessible and healthy
✅ **Cross-Platform**: Works on macOS, Linux, Windows
✅ **Documentation**: Examples accurate and up-to-date

## Test Coverage

- **Installation**: NPX flow, binary download, directory setup
- **Commands**: Basic, tutor, auth, config, error handling
- **Configuration**: JSON validation, permissions, env vars
- **Authentication**: OAuth flow, token management, security
- **Services**: Health checks, API connectivity, WebSocket
- **Platform**: Shell compatibility, file paths, network
- **Documentation**: Example accuracy, prerequisite validation

## Requirements

**Essential**:
- Bash 4.0+
- Node.js 16+ with npm/npx
- curl for HTTP requests

**Recommended**:
- jq for JSON processing
- kubectl for K8s tests
- Docker for container tests

## Documentation

See [`TESTING_GUIDE.md`](TESTING_GUIDE.md) for complete documentation including:
- Detailed test descriptions
- Troubleshooting guide
- Development guidelines
- CI/CD integration
- Platform-specific notes

## Example Output

```
TRIBE CLI Integration Test Results
==================================
Total test suites: 7
Passed: 7
Failed: 0
Success rate: 100%

🎉 All integration tests passed!
```

This comprehensive testing suite ensures quality delivery of the TRIBE CLI from installation through daily usage.