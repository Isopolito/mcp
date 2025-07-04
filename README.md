# Multi-Agent Coding Environment (Gemini, Claude, Codex)

This repository provides the necessary components to set up a powerful multi-agent coding environment. In this setup, **Gemini CLI** acts as the orchestrator, delegating complex coding and planning tasks to specialized AI models like **Claude Code** and **OpenAI Codex** via custom Model Context Protocol (MCP) bridge servers.

## 🎯 Overview

This project addresses the challenge of leveraging the unique strengths of different AI models in a collaborative development workflow. Gemini, with its orchestration capabilities, can intelligently route specific tasks to the most suitable AI agent:

*   **Claude Code:** Ideal for brainstorming, architectural design, code analysis (security, performance, maintainability), and collaborative planning.
*   **OpenAI Codex:** Excellent for code generation, scaffolding new features, refactoring, and executing code within a sandboxed environment.

This creates a highly efficient and versatile AI-assisted development pipeline.

## 🏗️ Architecture

```
User Query
    ↓
Gemini CLI (Orchestrator)
    ↓
MCP Bridge Servers
    ├───► Claude Code Bridge (claude-mcp) ───► Claude Code
    └───► OpenAI Codex Bridge (codex-mcp) ───► OpenAI Codex CLI
```

## ✨ Features

By integrating these agents, you can:

*   **Brainstorm and Plan:** Utilize Claude Code for high-level architectural discussions, design pattern considerations, and detailed implementation planning.
*   **Code Generation & Refactoring:** Delegate code scaffolding, feature implementation, and refactoring tasks to OpenAI Codex.
*   **Code Analysis:** Get in-depth security, performance, and maintainability analysis from Claude Code.
*   **Seamless Collaboration:** Experience a unified workflow where Gemini intelligently manages interactions with specialized AI tools.

## 🚀 Getting Started

To set up this multi-agent environment, follow these steps:

1.  **Clone this repository:**

    ```bash
    git clone <your-repo-url>
    cd mcp
    ```

2.  **Set up Claude Code Bridge:**

    Navigate to the `claude-mcp` directory and follow the instructions in its `README.md` for installation and configuration.

    ```bash
    cd claude-mcp
    # Follow instructions in claude-mcp/README.md
    ```

3.  **Set up OpenAI Codex Bridge:**

    Navigate to the `codex-mcp` directory and follow the instructions in its `README.md` for installation and configuration.

    ```bash
    cd ../codex-mcp
    # Follow instructions in codex-mcp/README.md
    ```

4.  **Configure Gemini CLI:**

    Ensure your Gemini CLI is configured to use both `claude-bridge` and `codex-bridge` as MCP servers. The setup scripts within each bridge's directory should assist with this configuration.

    Additionally, this repository includes [`GEMINI_COLLAB.md`](./GEMINI_COLLAB.md), an example of how to configure the Gemini CLI to adopt a new persona, specifically an "AI Project Coordinator" who orchestrates a team of AI engineers. To enable this collaborative mode, add `GEMINI_COLLAB.md` to your Gemini CLI configuration's `contextFileName` array, as shown below:

    ```json
    {
      "theme": "Atom One",
      "selectedAuthType": "oauth-personal",
      "SystemPrompts": {
        "Software Engineer": "You are an experienced, world class, software engineer."
      },
      "contextFileName": [
        "GEMINI.md",
        "GEMINI_COLLAB.md",
        "GEMINI_EXAMPLES.md"
      ],
      "mcpServers": {
        "claude-bridge": {
          "command": "/home/ash/bin/claude-bridge",
          "args": [],
          "env": {},
          "timeout": 280000
        },
        "codex-bridge": {
          "command": "/home/ash/bin/codex-bridge",
          "args": [],
          "env": {},
          "timeout": 280000
        }
      },
      "preferredEditor": "vim"
    }
    ```

## 📂 Project Structure

*   `claude-mcp/`: Contains the MCP bridge server for integrating Claude Code with Gemini CLI.
*   `codex-mcp/`: Contains the MCP bridge server for integrating OpenAI Codex CLI with Gemini CLI.

## 🤝 Contributing

Contributions are welcome! Please refer to the individual `README.md` files within `claude-mcp/` and `codex-mcp/` for specific contribution guidelines related to each bridge server.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. (Note: A `LICENSE` file should be added to the root of this repository if not already present.)
