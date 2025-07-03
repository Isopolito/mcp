#!/bin/bash

# Enhanced Integration Test Script with Debugging
# This script provides detailed debugging output for failed tests

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Create log directory
LOG_DIR="$HOME/.cache/claude-bridge-tests"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-$(date +%Y%m%d-%H%M%S).log"

# Function to print colored output
print_status() {
    local msg="$1"
    echo -e "${BLUE}[TEST]${NC} $msg" | tee -a "$LOG_FILE"
}

print_success() {
    local msg="$1"
    echo -e "${GREEN}[PASS]${NC} $msg" | tee -a "$LOG_FILE"
}

print_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg" | tee -a "$LOG_FILE"
}

print_error() {
    local msg="$1"
    echo -e "${RED}[FAIL]${NC} $msg" | tee -a "$LOG_FILE"
}

print_debug() {
    local msg="$1"
    echo -e "${PURPLE}[DEBUG]${NC} $msg" | tee -a "$LOG_FILE"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test with detailed output
run_test() {
    local test_name="$1"
    local test_command="$2"

    print_status "Running test: $test_name"
    echo "========== $test_name ==========" >> "$LOG_FILE"

    if eval "$test_command" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_debug "Check log file for details: $LOG_FILE"
    fi
    echo "================================" >> "$LOG_FILE"
}

# Test 1: Check prerequisites with detailed output
test_prerequisites() {
    print_debug "Checking Node.js..."
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found"
        return 1
    fi

    local node_version=$(node -v)
    print_debug "Node.js version: $node_version"

    local major_version=$(echo "$node_version" | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$major_version" -lt 18 ]; then
        print_error "Node.js version must be 18+. Current: $node_version"
        return 1
    fi

    print_debug "Checking Claude Code..."
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code not found"
        print_debug "PATH: $PATH"
        print_debug "Try: which claude"
        which claude || echo "Claude not in PATH"
        return 1
    fi

    local claude_version=$(claude --version 2>&1 || echo "version check failed")
    print_debug "Claude Code version: $claude_version"

    print_debug "Checking Gemini CLI..."
    if ! command -v gemini &> /dev/null; then
        print_error "Gemini CLI not found"
        print_debug "PATH: $PATH"
        print_debug "Try: which gemini"
        which gemini || echo "Gemini not in PATH"
        return 1
    fi

    local gemini_version=$(gemini --version 2>&1 || echo "version check failed")
    print_debug "Gemini CLI version: $gemini_version"

    print_debug "Checking Claude Bridge Server..."
    if ! command -v claude-bridge &> /dev/null; then
        print_error "Claude Bridge Server not found"
        print_debug "Expected location: ~/.local/bin/claude-bridge"
        ls -la ~/.local/bin/claude-bridge 2>&1 || echo "Bridge server not found"
        print_debug "PATH: $PATH"
        return 1
    fi

    local bridge_path=$(which claude-bridge)
    print_debug "Bridge server location: $bridge_path"
    ls -la "$bridge_path"

    return 0
}

# Test 2: Bridge server startup with debugging
test_bridge_startup() {
    print_debug "Testing bridge server startup..."

    # Test if the bridge server can start
    print_debug "Attempting to start claude-bridge..."

    local temp_log="$LOG_DIR/bridge-startup.log"
    timeout 10s claude-bridge > "$temp_log" 2>&1 &
    local pid=$!

    print_debug "Bridge server PID: $pid"
    sleep 3

    if kill -0 "$pid" 2>/dev/null; then
        print_debug "Bridge server is running"
        print_debug "Bridge server output:"
        head -20 "$temp_log"
        kill "$pid" 2>/dev/null
        return 0
    else
        print_error "Bridge server failed to start"
        print_debug "Bridge server output:"
        cat "$temp_log"
        return 1
    fi
}

# Test 3: MCP protocol communication with detailed debugging
test_mcp_protocol() {
    print_debug "Testing MCP protocol communication..."

    # Create a more robust test script
    local test_script="/tmp/test_mcp_debug.js"
    cat > "$test_script" << 'EOF'
const { spawn } = require('child_process');

async function testMCP() {
    console.log('Starting MCP protocol test...');

    const server = spawn('claude-bridge', [], {
        stdio: ['pipe', 'pipe', 'pipe']
    });

    let stdout_data = '';
    let stderr_data = '';

    server.stdout.on('data', (data) => {
        stdout_data += data.toString();
        console.log('STDOUT:', data.toString());
    });

    server.stderr.on('data', (data) => {
        stderr_data += data.toString();
        console.log('STDERR:', data.toString());
    });

    server.on('error', (error) => {
        console.error('Process error:', error);
        process.exit(1);
    });

    // Send MCP initialization
    const initMessage = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {
                "name": "test-client",
                "version": "1.0.0"
            }
        }
    };

    console.log('Sending init message:', JSON.stringify(initMessage));
    server.stdin.write(JSON.stringify(initMessage) + '\n');

    setTimeout(() => {
        console.log('Test timeout reached');
        console.log('Final stdout:', stdout_data);
        console.log('Final stderr:', stderr_data);

        server.kill();

        if (stdout_data.includes('capabilities') || stdout_data.includes('result')) {
            console.log('MCP test PASSED');
            process.exit(0);
        } else {
            console.log('MCP test FAILED');
            process.exit(1);
        }
    }, 5000);
}

testMCP().catch(console.error);
EOF

    print_debug "Running MCP protocol test script..."
    if node "$test_script"; then
        print_debug "MCP protocol test passed"
        rm -f "$test_script"
        return 0
    else
        print_error "MCP protocol test failed"
        print_debug "Test script location: $test_script (preserved for debugging)"
        return 1
    fi
}

# Test 4: Configuration files with detailed checks
test_configuration() {
    print_debug "Testing configuration files..."

    local gemini_config="$HOME/.config/gemini/mcp-config.json"
    local usage_guide="$HOME/.config/claude-bridge/USAGE.md"

    print_debug "Checking Gemini MCP config: $gemini_config"
    if [ ! -f "$gemini_config" ]; then
        print_error "Gemini MCP configuration not found"
        print_debug "Directory contents:"
        ls -la "$HOME/.config/gemini/" 2>&1 || echo "Gemini config dir doesn't exist"
        return 1
    fi

    print_debug "Gemini config exists, checking JSON validity..."
    if ! python3 -c "import json; json.load(open('$gemini_config'))" 2>&1; then
        print_error "Invalid JSON in Gemini MCP configuration"
        print_debug "Config file contents:"
        cat "$gemini_config"
        return 1
    fi

    print_debug "Gemini config JSON is valid"
    print_debug "Config contents:"
    cat "$gemini_config"

    print_debug "Checking usage guide: $usage_guide"
    if [ ! -f "$usage_guide" ]; then
        print_error "Usage guide not found"
        print_debug "Directory contents:"
        ls -la "$HOME/.config/claude-bridge/" 2>&1 || echo "Claude bridge config dir doesn't exist"
        return 1
    fi

    print_debug "Usage guide exists"
    return 0
}

# Test 5: Claude Code integration with better error handling
test_claude_integration() {
    print_debug "Testing Claude Code integration..."

    print_debug "Testing claude --version..."
    local version_output
    if version_output=$(claude --version 2>&1); then
        print_debug "Claude version: $version_output"
    else
        print_error "Claude Code version check failed"
        print_debug "Error: $version_output"
        return 1
    fi

    print_debug "Testing Claude Code with simple query..."
    local test_output
    if test_output=$(echo "What is 2+2?" | timeout 10s claude --print 2>&1); then
        print_debug "Claude query successful: $test_output"
        return 0
    else
        local exit_code=$?
        print_warning "Claude Code query test failed (exit code: $exit_code)"
        print_debug "Output: $test_output"
        if [ $exit_code -eq 124 ]; then
            print_debug "Test timed out - may require authentication"
        fi
        return 0  # Don't fail for auth issues
    fi
}

# Main test runner
main() {
    echo "=============================================="
    echo "   Claude Code Bridge Server Debug Test   "
    echo "=============================================="
    echo "Log file: $LOG_FILE"
    echo

    # Run all tests
    run_test "Prerequisites Check" "test_prerequisites"
    run_test "Bridge Server Startup" "test_bridge_startup"
    run_test "MCP Protocol Communication" "test_mcp_protocol"
    run_test "Configuration Files" "test_configuration"
    run_test "Claude Code Integration" "test_claude_integration"

    echo
    echo "=============================================="
    echo "                Test Results                  "
    echo "=============================================="
    echo
    print_success "Tests Passed: $TESTS_PASSED"

    if [ $TESTS_FAILED -gt 0 ]; then
        print_error "Tests Failed: $TESTS_FAILED"
        echo
        print_error "Check the log file for detailed error information:"
        print_error "$LOG_FILE"
        echo
        print_debug "Recent log entries:"
        tail -50 "$LOG_FILE"
    else
        echo
        print_success "🎉 All tests passed!"
    fi
}

# Cleanup function
cleanup() {
    echo
    print_warning "Tests interrupted. Cleaning up..."

    # Kill any remaining bridge server processes
    pkill -f "claude-bridge" 2>/dev/null || true

    # Remove temporary files
    rm -f /tmp/test_mcp_debug.js

    echo "Log file preserved: $LOG_FILE"

    exit 130
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Run main function
main "$@"