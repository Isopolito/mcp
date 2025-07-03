#!/bin/bash

echo "Configuring Gemini CLI for Claude Bridge Server..."

# Create Gemini config directory
mkdir -p ~/.gemini

# Create settings.json with MCP configuration
cat > ~/.gemini/settings.json << 'EOF'
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

echo "✅ Gemini CLI configured successfully!"
echo "📄 Configuration written to: ~/.gemini/settings.json"
echo ""
echo "🚀 Usage:"
echo "   gemini                    # Start Gemini CLI with Claude bridge"
echo "   /mcp                      # Check MCP server status"
echo ""
echo "💡 Example commands in Gemini CLI:"
echo "   Use brainstorm_with_claude to help me design a caching system"
echo "   Use get_claude_code_analysis to review my authentication code"