# Claude Code Bridge Server for Gemini CLI

An MCP (Model Context Protocol) bridge server that enables Gemini CLI to seamlessly consult with Claude Code for brainstorming, problem-solving, and collaborative development.

## 🎯 Overview

This bridge server solves a key challenge in AI-assisted development: enabling different AI tools to collaborate effectively. When Gemini CLI encounters a particularly complex problem, it can now "talk" to Claude Code to get alternative perspectives, detailed analysis, and collaborative brainstorming.

### Architecture

```
Gemini CLI → Claude Bridge Server → Claude Code
     ↑              ↑                    ↑
   User Query    MCP Protocol    Direct Integration
```

## 🚀 Features

- **Brainstorming Sessions**: Get Claude Code's perspective on complex technical challenges
- **Code Analysis**: Have Claude Code analyze specific files or directories
- **Collaborative Planning**: Work together on implementation plans and architectural decisions
- **Multiple Analysis Types**: Security, performance, maintainability, and best practices analysis
- **Seamless Integration**: Works natively with Gemini CLI's MCP support

## 📋 Prerequisites

- **Node.js 18+**: Required for running the bridge server
- **Claude Code**: Must be installed and accessible via `claude` command
- **Gemini CLI**: Must be installed and accessible via `gemini` command

### Installing Prerequisites

1. **Claude Code**: Follow installation instructions at [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code/installation)
2. **Gemini CLI**: Install from [Gemini CLI Repository](https://github.com/google-gemini/gemini-cli)

## 🛠️ Installation

### Quick Setup

```bash
# Clone or download the source code
git clone <your-repo-url>
cd claude-code-bridge-server

# Run the automated setup script
chmod +x setup.sh
./setup.sh
```

### Manual Installation

If you prefer to install manually:

```bash
# Install dependencies
npm install

# Build the project
npm run build

# Install globally
npm install -g .
```

## 🎮 Usage

### Starting Gemini CLI with Claude Bridge

```bash
# Start Gemini CLI with the MCP bridge
gemini --mcp-config ~/.config/gemini/mcp-config.json
```

### Available Tools

Once connected, you can use these tools within Gemini CLI:

#### 1. 🧠 Brainstorm with Claude

```
Use brainstorm_with_claude to help me think through implementing a distributed caching system for my microservices architecture
```

**Parameters:**
- `problem_description`: Detailed description of your challenge
- `context`: Additional context about your codebase or constraints
- `brainstorm_type`: architecture | debugging | optimization | design_patterns | general
- `include_code_analysis`: Whether to analyze your current codebase

#### 2. 🔍 Get Code Analysis

```
Use get_claude_code_analysis to review the security of my authentication middleware in ./src/auth/middleware.ts
```

**Parameters:**
- `file_path`: Path to file or directory to analyze
- `analysis_type`: security | performance | maintainability | best_practices | refactoring
- `specific_questions`: Specific questions about the code

#### 3. 🤝 Collaborative Planning

```
Use collaborative_planning to help me create an implementation plan for migrating our monolith to microservices
```

**Parameters:**
- `project_goal`: What you're trying to build or accomplish
- `constraints`: Technical constraints, timeline, or requirements
- `current_approach`: Your current approach or what you've tried
- `collaboration_focus`: implementation_plan | architecture_review | risk_assessment | alternative_approaches

## 💡 Example Workflows

### Architecture Brainstorming

```
Use brainstorm_with_claude with these parameters:
- problem_description: "I need to design a real-time notification system that can handle 1M+ users"
- context: "Using Node.js microservices, Redis, and PostgreSQL"
- brainstorm_type: "architecture"
- include_code_analysis: false
```

### Security Review

```
Use get_claude_code_analysis with these parameters:
- file_path: "./src/auth/"
- analysis_type: "security"
- specific_questions: "Are there any authentication bypass vulnerabilities?"
```

### Implementation Planning

```
Use collaborative_planning with these parameters:
- project_goal: "Build a CI/CD pipeline with automated testing and deployment"
- constraints: "Must work with existing Docker setup and GitHub Actions"
- collaboration_focus: "implementation_plan"
```

## 🔧 Configuration

### Gemini CLI Configuration

The setup script creates a configuration file at `~/.config/gemini/mcp-config.json`:

```json
{
  "mcpServers": {
    "claude-bridge": {
      "command": "claude-bridge",
      "args": [],
      "env": {}
    }
  }
}
```

### Environment Variables

The bridge server respects these environment variables:

- `CLAUDE_CODE_TIMEOUT`: Timeout for Claude Code queries (default: 60 seconds)
- `CLAUDE_CODE_PATH`: Custom path to Claude Code executable (default: `claude`)

## 🐛 Troubleshooting

### Common Issues

1. **"Command not found: claude-bridge"**
   ```bash
   # Add to PATH
   export PATH="$HOME/.local/bin:$PATH"
   source ~/.bashrc
   ```

2. **"Claude Code not found"**
   ```bash
   # Verify Claude Code installation
   claude --version
   ```

3. **"Gemini CLI MCP connection failed"**
   ```bash
   # Check MCP configuration
   cat ~/.config/gemini/mcp-config.json
   
   # Test bridge server
   claude-bridge --help
   ```

### Debug Mode

Run the bridge server with debug output:

```bash
DEBUG=1 claude-bridge
```

### Logs

Bridge server logs are written to stderr and can be viewed in Gemini CLI output.

## 🧪 Development

### Project Structure

```
src/
├── index.ts              # Main bridge server implementation
├── types/                # TypeScript type definitions
└── utils/                # Utility functions

dist/                     # Compiled JavaScript (generated)
├── index.js
└── ...

config/
├── tsconfig.json         # TypeScript configuration
└── package.json          # Dependencies and scripts
```

### Building from Source

```bash
# Install dependencies
npm install

# Development with hot reload
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Lint code
npm run lint

# Format code
npm run format
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `npm test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style

- Use TypeScript for type safety
- Follow ESLint and Prettier configurations
- Write tests for new functionality
- Document public APIs

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Anthropic](https://www.anthropic.com/) for Claude Code and MCP specification
- [Google](https://ai.google.dev/) for Gemini CLI
- [Model Context Protocol](https://modelcontextprotocol.io/) community

## 📚 Related Projects

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/) - Anthropic's AI coding assistant
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) - Google's terminal AI agent
- [MCP Servers](https://github.com/modelcontextprotocol/servers) - Official MCP server implementations

## 🔗 Links

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code/)
- [Gemini CLI Documentation](https://cloud.google.com/gemini/docs/codeassist/gemini-cli)

---

**Happy coding and brainstorming! 🚀🧠**
