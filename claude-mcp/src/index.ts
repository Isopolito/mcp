/**
 * Claude Code MCP Bridge Server
 *
 * This server acts as a bridge between Gemini CLI and Claude Code,
 * enabling Gemini to consult with Claude for brainstorming and problem-solving.
 *
 * Architecture:
 * Gemini CLI -> This Bridge Server -> Claude Code MCP Server
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";
import { z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";

const server = new Server(
  {
    name: "claude-bridge",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {
        list: true,
        call: true,
      },
    },
  }
);

// Tool schemas
const BrainstormSchema = z.object({
  problem_description: z.string().describe("Detailed description of the technical challenge or problem"),
  context: z.string().optional().describe("Additional context about your codebase, constraints, or environment"),
  brainstorm_type: z.string().describe("Type of brainstorming session"),
  include_code_analysis: z.boolean().optional().describe("Whether to include analysis of current codebase"),
});

const AnalysisSchema = z.object({
  file_or_directory_path: z.string().describe("Path to the file or directory to analyze"),
  analysis_type: z.string().describe("Type of analysis to perform"),
  specific_concerns: z.string().optional().describe("Specific areas or concerns to focus on"),
});

const PlanningSchema = z.object({
  project_description: z.string().describe("Description of the project or feature to plan"),
  planning_focus: z.string().describe("Focus of the planning session"),
  constraints: z.string().optional().describe("Technical or business constraints to consider"),
  goals: z.string().optional().describe("Specific goals or success criteria"),
});

// Helper function to execute Claude Code
async function executeClaudeCode(prompt: string, timeoutMs: number = 280000): Promise<string> {
  return new Promise((resolve, reject) => {
    const childProcess = spawn("claude", ["--print"], {
      stdio: ["pipe", "pipe", "pipe"],
      cwd: process.cwd()
    });

    let stdout = "";
    let stderr = "";

    const timeout = setTimeout(() => {
      childProcess.kill("SIGKILL");
      reject(new Error("Claude Code execution timed out"));
    }, timeoutMs);

    childProcess.stdout?.on("data", (data: Buffer) => {
      stdout += data.toString();
    });

    childProcess.stderr?.on("data", (data: Buffer) => {
      stderr += data.toString();
    });

    childProcess.stdin?.write(prompt);
    childProcess.stdin?.end();

    childProcess.on("close", (code) => {
      clearTimeout(timeout);
      if (code === 0) {
        resolve(stdout.trim() || "Claude Code completed but returned no output.");
      } else {
        reject(new Error(`Claude Code failed with code ${code}: ${stderr}`));
      }
    });

    childProcess.on("error", (error) => {
      clearTimeout(timeout);
      reject(new Error(`Failed to start Claude Code: ${error.message}`));
    });
  });
}

const toolDefinitions = [
  {
    name: "brainstorm_with_claude",
    description: "Get Claude Code's perspective on complex technical challenges and brainstorm solutions",
    schema: BrainstormSchema,
    handler: async (args: z.infer<typeof BrainstormSchema>) => {
      const { problem_description, context, brainstorm_type, include_code_analysis } = args;
      let prompt = `You are a member of my elite software engineering team. I'm working on a ${brainstorm_type} challenge and would like your perspective.\n\n`;
      prompt += `Problem: ${problem_description}\n\n`;

      if (context) {
        prompt += `Context: ${context}\n\n`;
      }

      if (include_code_analysis) {
        prompt += `Please also analyze the relevant code in the current directory and incorporate your findings into the brainstorming session.\n\n`;
      }

      prompt += `Please help me brainstorm solutions, approaches, and considerations for this challenge.`;

      const response = await executeClaudeCode(prompt);

      return {
        content: [
          {
            type: "text",
            text: `## Claude Code Brainstorming Session\n\n${response}`,
          },
        ],
      };
    },
  },
  {
    name: "get_claude_code_analysis",
    description: "Have Claude Code analyze specific files or directories for various aspects",
    schema: AnalysisSchema,
    handler: async (args: z.infer<typeof AnalysisSchema>) => {
      const { file_or_directory_path, analysis_type, specific_concerns } = args;
      let prompt = `You are an member of my elite software engineering team. Please perform a ${analysis_type} analysis of: ${file_or_directory_path}\n\n`;

      if (specific_concerns) {
        prompt += `Focus on these specific concerns: ${specific_concerns}\n\n`;
      }

      prompt += `Please provide detailed insights and recommendations.`;

      const response = await executeClaudeCode(prompt);

      return {
        content: [
          {
            type: "text",
            text: `## Claude Code Analysis: ${analysis_type}\n\n**Target:** ${file_or_directory_path}\n\n${response}`,
          },
        ],
      };
    },
  },
  {
    name: "collaborative_planning",
    description: "Collaborate with Claude Code on implementation planning and architectural decisions",
    schema: PlanningSchema,
    handler: async (args: z.infer<typeof PlanningSchema>) => {
      const { project_description, planning_focus, constraints, goals } = args;
      let prompt = `You are a member of my elite software engineering team. Let's collaborate on ${planning_focus} for this project:\n\n`;
      prompt += `Project: ${project_description}\n\n`;

      if (constraints) {
        prompt += `Constraints: ${constraints}\n\n`;
      }

      if (goals) {
        prompt += `Goals: ${goals}\n\n`;
      }

      prompt += `Please help me create a comprehensive plan with actionable steps and considerations.`;

      const response = await executeClaudeCode(prompt);

      return {
        content: [
          {
            type: "text",
            text: `## Collaborative Planning Session\n\n**Focus:** ${planning_focus}\n\n${response}`,
          },
        ],
      };
    },
  },
];

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: toolDefinitions.map(({ name, description, schema }) => ({
      name,
      description,
      inputSchema: zodToJsonSchema(schema),
    })),
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const tool = toolDefinitions.find((t) => t.name === name);

  if (!tool) {
    throw new Error(`Unknown tool: ${name}`);
  }

  try {
    const parsedArgs = tool.schema.parse(args);
    return await tool.handler(parsedArgs as any);
  } catch (error) {
    throw new Error(`Tool execution failed: ${error instanceof Error ? error.message : String(error)}`);
  }
});

// CLI argument handling
function showHelp() {
  console.log(`
Claude Code Bridge Server v1.0.0

USAGE:
  claude-bridge [OPTIONS]

OPTIONS:
  --help, -h    Show this help message
  --version     Show version information

DESCRIPTION:
  MCP Bridge Server enabling Gemini CLI to consult with Claude Code
  for brainstorming and collaborative problem-solving.

TOOLS:
  brainstorm_with_claude       - Get Claude's perspective on technical challenges
  get_claude_code_analysis     - Have Claude analyze files/directories  
  collaborative_planning       - Collaborate on implementation planning
`);
}

// Start the server
async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    return;
  }

  if (args.includes('--version')) {
    console.log('1.0.0');
    return;
  }

  const transport = new StdioServerTransport();
  transport.onclose = () => {
    console.error("Connection closed, shutting down.");
    process.exit(0);
  };

  await server.connect(transport);
  console.error("Claude Code Bridge Server started");

  process.on("SIGINT", async () => {
    console.error("Caught SIGINT, shutting down.");
    await transport.close();
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    console.error("Caught SIGTERM, shutting down.");
    await transport.close();
    process.exit(0);
  });

  // Keep the process alive until the transport is closed or a signal is received.
  await new Promise<void>(() => {});
}

if (require.main === module) {
  main().catch((error) => {
    console.error("Server failed to start:", error);
    process.exit(1);
  });
}

export { server };
