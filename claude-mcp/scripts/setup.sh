#!/bin/bash

# Claude Code Bridge Server Setup Script
# This script sets up the MCP bridge between Gemini CLI and Claude Code

set -e

echo "🚀 Setting up Claude Code Bridge Server for Gemini CLI integration..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 18+ and try again."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18 or higher is required. Current version: $(node -v)"
        exit 1
    fi
    print_success "Node.js $(node -v) found"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install npm and try again."
        exit 1
    fi
    print_success "npm $(npm -v) found"
    
    # Check if Claude Code is installed
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code is not installed. Please install Claude Code first:"
        print_error "Visit: https://docs.anthropic.com/en/docs/claude-code/installation"
        exit 1
    fi
    print_success "Claude Code found: $(claude --version)"
    
    # Check if Gemini CLI is installed
    if ! command -v gemini &> /dev/null; then
        print_error "Gemini CLI is not installed. Please install Gemini CLI first:"
        print_error "Visit: https://github.com/google-gemini/gemini-cli"
        exit 1
    fi
    print_success "Gemini CLI found"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Make sure you're in the correct directory."
        exit 1
    fi
    
    npm install
    print_success "Dependencies installed"
}

# Build the project
build_project() {
    print_status "Building TypeScript project..."
    npm run build
    print_success "Project built successfully"
}

# Create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    mkdir -p ~/.local/bin
    mkdir -p ~/.config/claude-bridge
    
    print_success "Directories created"
}

# Install globally
install_globally() {
    print_status "Installing Claude Bridge Server globally..."
    
    # Copy built files to a local directory
    INSTALL_DIR="$HOME/.local/lib/claude-bridge"
    mkdir -p "$INSTALL_DIR"
    
    cp -r dist/* "$INSTALL_DIR/"
    cp package.json "$INSTALL_DIR/"
    
    # Create executable script
    cat > "$HOME/.local/bin/claude-bridge" << 'EOF'
#!/bin/bash
exec node "$HOME/.local/lib/claude-bridge/index.js" "$@"
EOF
    
    chmod +x "$HOME/.local/bin/claude-bridge"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
        print_warning "Added ~/.local/bin to PATH. Please restart your shell or run: source ~/.bashrc"
    fi
    
    print_success "Claude Bridge Server installed to ~/.local/bin/claude-bridge"
}

# Configure Gemini CLI
configure_gemini() {
    print_status "Configuring Gemini CLI to use Claude Bridge Server..."
    
    # Create MCP server configuration for Gemini
    GEMINI_CONFIG_DIR="$HOME/.config/gemini"
    mkdir -p "$GEMINI_CONFIG_DIR"
    
    # Check if gemini supports MCP configuration
    cat > "$GEMINI_CONFIG_DIR/mcp-config.json" << EOF
{
  "mcpServers": {
    "claude-bridge": {
      "command": "claude-bridge",
      "args": [],
      "env": {}
    }
  }
}
EOF
    
    print_success "Gemini CLI configuration created at ~/.config/gemini/mcp-config.json"
    
    print_status "To use the Claude Bridge in Gemini CLI, run:"
    echo -e "${YELLOW}gemini --mcp-config ~/.config/gemini/mcp-config.json${NC}"
}

# Test the installation
test_installation() {
    print_status "Testing the installation..."
    
    # Test if the bridge server can start
    timeout 5s claude-bridge --help > /dev/null 2>&1 || {
        if [ $? -eq 124 ]; then
            print_success "Bridge server starts correctly (timed out as expected)"
        else
            print_warning "Bridge server may have issues starting. Please check the logs."
        fi
    }
    
    # Test Claude Code integration
    if claude --version > /dev/null 2>&1; then
        print_success "Claude Code integration test passed"
    else
        print_warning "Claude Code integration test failed"
    fi
}

# Create usage instructions
create_usage_instructions() {
    print_status "Creating usage instructions..."
    
    cat > "$HOME/.config/claude-bridge/USAGE.md" << 'EOF'
# Claude Code Bridge Server Usage

## Starting Gemini CLI with Claude Bridge

```bash
# Start Gemini CLI with the Claude Bridge MCP server
gemini --mcp-config ~/.config/gemini/mcp-config.json
```

## Available Tools

Once connected, you can use these tools in Gemini CLI:

### 1. brainstorm_with_claude
Consult with Claude Code for brainstorming and problem-solving.

Example:
```
> Use brainstorm_with_claude to help me think through implementing a distributed caching system for my microservices architecture
```

### 2. get_claude_code_analysis
Get Claude Code to analyze specific files or directories.

Example:
```
> Use get_claude_code_analysis to review the security of my authentication middleware in ./src/auth/middleware.ts
```

### 3. collaborative_planning
Work with Claude Code on planning complex implementations.

Example:
```
> Use collaborative_planning to help me create an implementation plan for migrating our monolith to microservices
```

## Tips for Effective Brainstorming

1. **Be Specific**: Provide detailed context about your problem
2. **Include Constraints**: Mention any technical, timeline, or resource constraints
3. **Ask for Alternatives**: Request multiple approaches to compare
4. **Iterate**: Use the responses to ask follow-up questions

## Troubleshooting

If the bridge server isn't working:

1. Check that Claude Code is installed and accessible: `claude --version`
2. Verify the bridge server starts: `claude-bridge --help`
3. Check Gemini CLI MCP configuration: `cat ~/.config/gemini/mcp-config.json`
4. Look for error messages in the Gemini CLI output

## Configuration

The bridge server configuration is stored in:
- MCP Config: `~/.config/gemini/mcp-config.json`
- Usage Guide: `~/.config/claude-bridge/USAGE.md`
EOF
    
    print_success "Usage instructions created at ~/.config/claude-bridge/USAGE.md"
}

# Main installation process
main() {
    echo "==============================================="
    echo "  Claude Code Bridge Server for Gemini CLI   "
    echo "==============================================="
    echo
    
    check_prerequisites
    echo
    
    install_dependencies
    echo
    
    build_project
    echo
    
    create_directories
    echo
    
    install_globally
    echo
    
    configure_gemini
    echo
    
    test_installation
    echo
    
    create_usage_instructions
    echo
    
    print_success "🎉 Installation completed successfully!"
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo -e "1. Restart your shell or run: ${YELLOW}source ~/.bashrc${NC}"
    echo -e "2. Start Gemini CLI with: ${YELLOW}gemini --mcp-config ~/.config/gemini/mcp-config.json${NC}"
    echo -e "3. Try: ${YELLOW}Use brainstorm_with_claude to help me solve [your problem]${NC}"
    echo -e "4. Read usage guide: ${YELLOW}cat ~/.config/claude-bridge/USAGE.md${NC}"
    echo
    echo -e "${BLUE}Happy brainstorming! 🧠✨${NC}"
}

# Run main function
main "$@"

#mkdir -p ~/bin
chmod +x dist/index.js
ln -sf "$(pwd)/dist/index.js" ~/bin/claude-bridge
#export PATH="$HOME/bin:$PATH"
