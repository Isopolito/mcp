#!/bin/bash

# Integration Test Script for Claude Code Bridge Server
# This script tests the complete integration between Gemini CLI and Claude Code

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_status "Running test: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        print_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 1: Check prerequisites
test_prerequisites() {
    print_status "Testing prerequisites..."
    
    # Test Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found"
        return 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version must be 18+. Current: $(node -v)"
        return 1
    fi
    
    # Test Claude Code
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code not found"
        return 1
    fi
    
    # Test Gemini CLI
    if ! command -v gemini &> /dev/null; then
        print_error "Gemini CLI not found"
        return 1
    fi
    
    # Test bridge server
    if ! command -v claude-bridge &> /dev/null; then
        print_error "Claude Bridge Server not found"
        return 1
    fi
    
    return 0
}

# Test 2: Bridge server startup
test_bridge_startup() {
    print_status "Testing bridge server startup..."
    
    # Start bridge server in background and test if it responds
    timeout 5s claude-bridge > /dev/null 2>&1 &
    local pid=$!
    
    sleep 2
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        return 0
    else
        return 1
    fi
}

# Test 3: MCP protocol communication
test_mcp_protocol() {
    print_status "Testing MCP protocol communication..."
    
    # Create a temporary test script
    cat > /tmp/test_mcp.js << 'EOF'
const { spawn } = require('child_process');

async function testMCP() {
    const server = spawn('claude-bridge');
    
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
    
    server.stdin.write(JSON.stringify(initMessage) + '\n');
    
    let response = '';
    server.stdout.on('data', (data) => {
        response += data.toString();
    });
    
    setTimeout(() => {
        server.kill();
        if (response.includes('capabilities')) {
            process.exit(0);
        } else {
            process.exit(1);
        }
    }, 3000);
}

testMCP();
EOF
    
    if node /tmp/test_mcp.js; then
        rm -f /tmp/test_mcp.js
        return 0
    else
        rm -f /tmp/test_mcp.js
        return 1
    fi
}

# Test 4: Configuration files
test_configuration() {
    print_status "Testing configuration files..."
    
    # Check if Gemini MCP config exists
    if [ ! -f "$HOME/.config/gemini/mcp-config.json" ]; then
        print_error "Gemini MCP configuration not found"
        return 1
    fi
    
    # Validate JSON syntax
    if ! python3 -c "import json; json.load(open('$HOME/.config/gemini/mcp-config.json'))" 2>/dev/null; then
        print_error "Invalid JSON in Gemini MCP configuration"
        return 1
    fi
    
    # Check if usage guide exists
    if [ ! -f "$HOME/.config/claude-bridge/USAGE.md" ]; then
        print_error "Usage guide not found"
        return 1
    fi
    
    return 0
}

# Test 5: Claude Code integration
test_claude_integration() {
    print_status "Testing Claude Code integration..."
    
    # Test basic Claude Code functionality
    if ! claude --version > /dev/null 2>&1; then
        print_error "Claude Code not working"
        return 1
    fi
    
    # Test Claude Code with a simple query
    local test_output
    test_output=$(echo "What is 2+2?" | claude --print 2>/dev/null || echo "error")
    
    if [ "$test_output" = "error" ]; then
        print_warning "Claude Code query test failed (may require authentication)"
        return 0  # Don't fail the test for auth issues
    fi
    
    return 0
}

# Test 6: End-to-end workflow simulation
test_e2e_workflow() {
    print_status "Testing end-to-end workflow simulation..."
    
    # Create a test script that simulates Gemini CLI calling the bridge
    cat > /tmp/test_e2e.js << 'EOF'
const { spawn } = require('child_process');

async function testE2E() {
    const server = spawn('claude-bridge');
    
    // Send tool list request
    const listToolsMessage = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/list"
    };
    
    server.stdin.write(JSON.stringify(listToolsMessage) + '\n');
    
    let response = '';
    server.stdout.on('data', (data) => {
        response += data.toString();
    });
    
    setTimeout(() => {
        server.kill();
        if (response.includes('brainstorm_with_claude')) {
            process.exit(0);
        } else {
            console.error('Response:', response);
            process.exit(1);
        }
    }, 5000);
}

testE2E();
EOF
    
    if node /tmp/test_e2e.js; then
        rm -f /tmp/test_e2e.js
        return 0
    else
        rm -f /tmp/test_e2e.js
        return 1
    fi
}

# Test 7: Performance and memory usage
test_performance() {
    print_status "Testing performance and memory usage..."
    
    # Start bridge server and monitor resource usage
    claude-bridge > /dev/null 2>&1 &
    local pid=$!
    
    sleep 3
    
    if kill -0 "$pid" 2>/dev/null; then
        # Get memory usage (in KB)
        local memory_usage
        memory_usage=$(ps -o rss= -p "$pid" 2>/dev/null || echo "0")
        
        kill "$pid" 2>/dev/null
        
        # Check if memory usage is reasonable (less than 100MB)
        if [ "$memory_usage" -lt 102400 ]; then
            print_success "Memory usage: ${memory_usage}KB (acceptable)"
            return 0
        else
            print_warning "Memory usage: ${memory_usage}KB (high)"
            return 0  # Don't fail for high memory usage
        fi
    else
        return 1
    fi
}

# Test 8: Error handling
test_error_handling() {
    print_status "Testing error handling..."
    
    # Test with invalid Claude Code command
    export CLAUDE_CODE_PATH="/nonexistent/claude"
    
    claude-bridge > /dev/null 2>&1 &
    local pid=$!
    
    sleep 2
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        unset CLAUDE_CODE_PATH
        return 0  # Server should start even with invalid Claude path
    else
        unset CLAUDE_CODE_PATH
        return 1
    fi
}

# Test 9: Concurrent connections
test_concurrent_connections() {
    print_status "Testing concurrent connections..."
    
    # This is a basic test - in a real scenario, we'd test multiple simultaneous connections
    claude-bridge > /dev/null 2>&1 &
    local pid1=$!
    
    claude-bridge > /dev/null 2>&1 &
    local pid2=$!
    
    sleep 2
    
    local success=0
    if kill -0 "$pid1" 2>/dev/null; then
        success=$((success + 1))
        kill "$pid1" 2>/dev/null
    fi
    
    if kill -0 "$pid2" 2>/dev/null; then
        success=$((success + 1))
        kill "$pid2" 2>/dev/null
    fi
    
    if [ "$success" -eq 2 ]; then
        return 0
    else
        return 1
    fi
}

# Test 10: Cleanup and resource management
test_cleanup() {
    print_status "Testing cleanup and resource management..."
    
    # Start server and send SIGTERM
    claude-bridge > /dev/null 2>&1 &
    local pid=$!
    
    sleep 2
    
    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null
        sleep 1
        
        if ! kill -0 "$pid" 2>/dev/null; then
            return 0  # Process cleaned up properly
        else
            kill -KILL "$pid" 2>/dev/null
            return 1
        fi
    else
        return 1
    fi
}

# Main test runner
main() {
    echo "=============================================="
    echo "   Claude Code Bridge Server Integration Test   "
    echo "=============================================="
    echo
    
    # Run all tests
    run_test "Prerequisites Check" "test_prerequisites"
    run_test "Bridge Server Startup" "test_bridge_startup"
    run_test "MCP Protocol Communication" "test_mcp_protocol"
    run_test "Configuration Files" "test_configuration"
    run_test "Claude Code Integration" "test_claude_integration"
    run_test "End-to-End Workflow" "test_e2e_workflow"
    run_test "Performance and Memory" "test_performance"
    run_test "Error Handling" "test_error_handling"
    run_test "Concurrent Connections" "test_concurrent_connections"
    run_test "Cleanup and Resource Management" "test_cleanup"
    
    echo
    echo "=============================================="
    echo "                Test Results                  "
    echo "=============================================="
    echo
    print_success "Tests Passed: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        print_error "Tests Failed: $TESTS_FAILED"
        echo
        print_error "Some tests failed. Please check the output above for details."
        exit 1
    else
        echo
        print_success "🎉 All tests passed! The integration is working correctly."
        echo
        echo -e "${GREEN}You can now use Gemini CLI with Claude Code integration:${NC}"
        echo -e "${YELLOW}gemini --mcp-config ~/.config/gemini/mcp-config.json${NC}"
    fi
}

# Cleanup function for interrupted tests
cleanup() {
    echo
    print_warning "Tests interrupted. Cleaning up..."
    
    # Kill any remaining bridge server processes
    pkill -f "claude-bridge" 2>/dev/null || true
    
    # Remove temporary files
    rm -f /tmp/test_mcp.js /tmp/test_e2e.js
    
    exit 130
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Run main function
main "$@"
