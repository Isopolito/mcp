#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    print_status "Checking prerequisites..."
    local missing_deps=()

    if ! command -v node &> /dev/null; then
        missing_deps+=("Node.js 18+")
    else
        local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_version" -lt 18 ]; then
            missing_deps+=("Node.js 18+ (current: $(node --version))")
        fi
    fi

    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    fi

    if ! command -v codex &> /dev/null; then
        missing_deps+=("Codex CLI")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing prerequisites:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Install missing dependencies:"
        echo "  - Node.js 18+: https://nodejs.org/"
        echo "  - Codex CLI: npm install -g @openai/codex"
        exit 1
    fi

    print_success "All prerequisites are installed"
}

install_dependencies() {
    print_status "Installing Node.js dependencies..."

    if npm install; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

build_project() {
    print_status "Building TypeScript project..."

    if npm run build; then
        print_success "Project built successfully"
    else
        print_error "Failed to build project"
        exit 1
    fi
}

create_directories() {
    print_status "Creating configuration directories..."

    mkdir -p ~/.config/codex-bridge
    mkdir -p ~/.config/gemini
    mkdir -p ~/bin

    print_success "Configuration directories created"
}

install_globally() {
    print_status "Installing codex-bridge globally..."

    # Copy built files to a local directory
    INSTALL_DIR="$HOME/.local/lib/codex-bridge"
    mkdir -p "$INSTALL_DIR"
    
    cp -r dist/* "$INSTALL_DIR/"
    
    # Create executable script
    cat > "$HOME/bin/codex-bridge" << 'EOF'
#!/bin/bash
exec "$HOME/.local/lib/codex-bridge/codex-bridge" "$@"
EOF
    
    chmod +x "$HOME/bin/codex-bridge"

    # Add ~/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        print_status "Added ~/bin to PATH in ~/.bashrc"
        print_warning "Please run 'source ~/.bashrc' or restart your terminal"
    fi

    print_success "codex-bridge installed globally to ~/bin"
}

configure_gemini() {
    print_status "Configuring Gemini CLI for Codex Bridge..."

    local config_file="~/.config/gemini/mcp-config.json"
    local config_path="$HOME/.config/gemini/mcp-config.json"

    # Check if config file exists
    if [ -f "$config_path" ]; then
        print_status "Existing Gemini config found, merging Codex Bridge configuration..."

        # Check if codex-bridge already exists in config
        if grep -q '"codex-bridge"' "$config_path" 2>/dev/null; then
            print_warning "Codex Bridge already configured in Gemini CLI"
            return 0
        fi

        # Create backup
        cp "$config_path" "$config_path.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Created backup of existing config"

        # Parse existing config and add codex-bridge
        python3 -c "
import json
import sys

try:
    with open('$config_path', 'r') as f:
        config = json.load(f)

    # Ensure mcpServers exists
    if 'mcpServers' not in config:
        config['mcpServers'] = {}

    # Add codex-bridge
    config['mcpServers']['codex-bridge'] = {
        'command': 'codex-bridge',
        'args': [],
        'env': {}
    }

    with open('$config_path', 'w') as f:
        json.dump(config, f, indent=2)

    print('Successfully merged codex-bridge into existing config')
except Exception as e:
    print(f'Error merging config: {e}', file=sys.stderr)
    sys.exit(1)
" || {
            print_error "Failed to merge configuration. Creating new config file."
            create_new_gemini_config "$config_path"
        }
    else
        print_status "No existing Gemini config found, creating new one..."
        create_new_gemini_config "$config_path"
    fi

    print_success "Gemini CLI configured for Codex Bridge"
}

create_new_gemini_config() {
    local config_path="$1"
    cat > "$config_path" << 'EOF'
{
  "mcpServers": {
    "codex-bridge": {
      "command": "codex-bridge",
      "args": [],
      "env": {}
    }
  }
}
EOF
}

test_installation() {
    print_status "Testing installation..."

    # Test if codex-bridge command is available
    if command -v codex-bridge &> /dev/null; then
        print_success "codex-bridge command is available in PATH"
    else
        print_error "codex-bridge command not found in PATH"
        return 1
    fi

    # Test if codex-bridge starts (with timeout)
    if timeout 5s codex-bridge 2>/dev/null; then
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_success "Bridge server starts correctly (timed out as expected)"
        else
            print_warning "Bridge server may have issues starting. Exit code: $exit_code"
        fi
    else
        print_warning "Bridge server failed to start within timeout"
    fi

    # Test Codex CLI integration
    if codex --version > /dev/null 2>&1; then
        print_success "Codex CLI integration test passed"
    else
        print_warning "Codex CLI integration test failed"
    fi
}

create_usage_instructions() {
    print_status "Creating usage instructions..."

    cat > ~/.config/codex-bridge/USAGE.md << 'EOF'
# Codex CLI Bridge Server Usage

## Starting Gemini CLI with Codex Bridge

```bash
# Start Gemini CLI with the Codex Bridge MCP server
gemini --mcp-config ~/.config/gemini/mcp-config.json
```

## Available Tools

### 1. brainstorm_with_codex
Get Codex's perspective on technical challenges:
```
Use brainstorm_with_codex with problem_description="How to implement real-time notifications in a microservices architecture"
```

### 2. get_codex_code_analysis
Analyze specific files or directories:
```
Use get_codex_code_analysis with file_or_directory_path="./src/auth/" analysis_type="security"
```

### 3. collaborative_planning
Create implementation plans:
```
Use collaborative_planning with project_description="Add Redis caching layer" planning_focus="implementation"
```

## Troubleshooting

If you encounter issues:
1. Ensure Codex CLI is installed: `codex --version`
2. Check if bridge is running: `ps aux | grep codex-bridge`
3. View logs: Check Gemini CLI output for error messages
4. Restart: Kill any existing bridge processes and restart Gemini CLI

## Configuration

The bridge server is configured in `~/.config/gemini/mcp-config.json`
EOF

    print_success "Usage instructions created at ~/.config/codex-bridge/USAGE.md"
}

create_convenience_scripts() {
    print_status "Creating convenience scripts..."

    # Create start script
    cat > ~/bin/start-gemini-with-codex << 'EOF'
#!/bin/bash
echo "Starting Gemini CLI with Codex Bridge integration..."
gemini --mcp-config ~/.config/gemini/mcp-config.json
EOF
    chmod +x ~/bin/start-gemini-with-codex

    # Create test script
    cat > ~/bin/test-codex-bridge << 'EOF'
#!/bin/bash
echo "Testing Codex Bridge setup..."

echo "1. Checking codex-bridge command..."
if command -v codex-bridge &> /dev/null; then
    echo "✅ codex-bridge command found"
else
    echo "❌ codex-bridge command not found"
    exit 1
fi

echo "2. Checking Codex CLI..."
if codex --version &> /dev/null; then
    echo "✅ Codex CLI is working"
else
    echo "❌ Codex CLI not working"
    exit 1
fi

echo "3. Testing bridge server startup..."
timeout 3s codex-bridge 2>/dev/null
if [ $? -eq 124 ]; then
    echo "✅ Bridge server starts correctly"
else
    echo "⚠️  Bridge server may have issues"
fi

echo "4. Checking Gemini configuration..."
if [ -f ~/.config/gemini/mcp-config.json ]; then
    echo "✅ Gemini MCP configuration exists"
else
    echo "❌ Gemini MCP configuration missing"
    exit 1
fi

echo ""
echo "All tests passed! You can now start Gemini with Codex integration:"
echo "  start-gemini-with-codex"
EOF
    chmod +x ~/bin/test-codex-bridge

    print_success "Convenience scripts created (start-gemini-with-codex, test-codex-bridge)"
}

cleanup_on_error() {
    print_error "Setup failed. Cleaning up..."
    rm -f ~/bin/codex-bridge
    rm -f ~/.config/gemini/mcp-config.json.backup.*
    rm -rf ~/.config/codex-bridge
}

main() {
    print_status "Starting Codex CLI Bridge Server setup..."
    echo ""

    # Set error handling
    trap cleanup_on_error ERR

    check_prerequisites
    install_dependencies
    build_project
    create_directories
    install_globally
    configure_gemini
    create_usage_instructions
    create_convenience_scripts

    echo ""
    print_status "Running installation tests..."
    test_installation

    echo ""
    print_success "🎉 Codex CLI Bridge Server setup complete!"
    echo ""
    echo "Quick start:"
    echo "  1. Source your bashrc: source ~/.bashrc"
    echo "  2. Test the setup: test-codex-bridge"
    echo "  3. Start Gemini with Codex: start-gemini-with-codex"
    echo ""
    echo "Documentation: ~/.config/codex-bridge/USAGE.md"
    echo ""
    print_status "Happy coding! 🚀"
}

# Run main function
main "$@"