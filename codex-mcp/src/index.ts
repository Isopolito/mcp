/**
 * Codex CLI MCP Bridge Server
 *
 * This server acts as a bridge between Gemini CLI and Codex CLI,
 * enabling Gemini to consult with Codex for code generation and analysis.
 *
 * Architecture:
 * Gemini CLI -> This Bridge Server -> Codex CLI
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import { spawn } from "child_process";

// Tool schemas
const BrainstormSchema = z.object({
  problem_description: z.string().describe("Detailed description of the technical challenge or problem"),
  context: z.string().optional().describe("Additional context about your project, tech stack, or constraints"),
  approach_preference: z.string().optional().describe("Any preferred approaches or technologies to consider"),
});

const CodeAnalysisSchema = z.object({
  file_or_directory_path: z.string().describe("Path to the file or directory to analyze"),
  analysis_type: z.string().default("general").describe("Type of analysis: 'security', 'performance', 'architecture', 'refactoring', or 'general'"),
  specific_concerns: z.string().optional().describe("Specific areas of concern or questions about the code"),
});

const PlanningSchema = z.object({
  project_description: z.string().describe("Description of the project or feature you're planning"),
  planning_focus: z.string().describe("What aspect to plan: 'implementation', 'architecture', 'testing', 'deployment', etc."),
  constraints: z.string().optional().describe("Any constraints (time, resources, technology, etc.)"),
  goals: z.string().optional().describe("Specific goals or success criteria"),
});

// Execute Codex CLI command
async function executeCodex(prompt: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const codex = spawn("codex", ["-q", prompt], {
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    codex.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    codex.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    codex.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`Codex CLI failed with code ${code}: ${stderr}`));
      } else {
        resolve(stdout.trim());
      }
    });

    codex.on("error", (error) => {
      reject(new Error(`Failed to execute Codex CLI: ${error.message}`));
    });
  });
}

const server = new Server(
  {
    name: "codex-bridge",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Tool registration
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "brainstorm_with_codex",
        description: "Get Codex's perspective on technical challenges and coding problems",
        inputSchema: {
          type: "object",
          properties: {
            problem_description: {
              type: "string",
              description: "Detailed description of the technical challenge or problem",
            },
            context: {
              type: "string",
              description: "Additional context about your project, tech stack, or constraints",
            },
            approach_preference: {
              type: "string",
              description: "Any preferred approaches or technologies to consider",
            },
          },
          required: ["problem_description"],
        },
      },
      {
        name: "get_codex_code_analysis",
        description: "Have Codex analyze specific files or directories for code quality, security, or improvements",
        inputSchema: {
          type: "object",
          properties: {
            file_or_directory_path: {
              type: "string",
              description: "Path to the file or directory to analyze",
            },
            analysis_type: {
              type: "string",
              description: "Type of analysis: 'security', 'performance', 'architecture', 'refactoring', or 'general' or 'debugging'",
              default: "general",
            },
            specific_concerns: {
              type: "string",
              description: "Specific areas of concern or questions about the code",
            },
          },
          required: ["file_or_directory_path"],
        },
      },
      {
        name: "collaborative_planning",
        description: "Work with Codex on planning complex implementations and architectures",
        inputSchema: {
          type: "object",
          properties: {
            project_description: {
              type: "string",
              description: "Description of the project or feature you're planning",
            },
            planning_focus: {
              type: "string",
              description: "What aspect to plan: 'implementation', 'architecture', 'testing', 'deployment', etc.",
            },
            constraints: {
              type: "string",
              description: "Any constraints (time, resources, technology, etc.)",
            },
            goals: {
              type: "string",
              description: "Specific goals or success criteria",
            },
          },
          required: ["project_description", "planning_focus"],
        },
      },
    ],
  };
});

// Tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "brainstorm_with_codex": {
        const { problem_description, context, approach_preference } = BrainstormSchema.parse(args);

        let prompt = `You are a member of my elite software engineering team. Help me brainstorm solutions for this technical challenge:\n\n${problem_description}\n\n`;

        if (context) {
          prompt += `Context: ${context}\n\n`;
        }

        if (approach_preference) {
          prompt += `Preferred approach: ${approach_preference}\n\n`;
        }

        prompt += `Please provide multiple solution approaches with pros/cons and implementation considerations.`;

        const response = await executeCodex(prompt);

        return {
          content: [
            {
              type: "text",
              text: `## Codex Brainstorming Session\n\n**Challenge:** ${problem_description}\n\n${response}`,
            },
          ],
        };
      }

      case "get_codex_code_analysis": {
        const { file_or_directory_path, analysis_type, specific_concerns } = CodeAnalysisSchema.parse(args);

        let prompt = `You are a member of my elite software engineering team. Analyze this ${analysis_type} for: ${file_or_directory_path}\n\n`;

        if (specific_concerns) {
          prompt += `Focus on these specific concerns: ${specific_concerns}\n\n`;
        }

        prompt += `Please provide detailed insights and recommendations.`;

        const response = await executeCodex(prompt);

        return {
          content: [
            {
              type: "text",
              text: `## Codex Code Analysis: ${analysis_type}\n\n**Target:** ${file_or_directory_path}\n\n${response}`,
            },
          ],
        };
      }

      case "collaborative_planning": {
        const { project_description, planning_focus, constraints, goals } = PlanningSchema.parse(args);

        let prompt = `You are a member of my elite software engineering team. Let's collaborate on ${planning_focus} for this project:\n\n`;
        prompt += `Project: ${project_description}\n\n`;

        if (constraints) {
          prompt += `Constraints: ${constraints}\n\n`;
        }

        if (goals) {
          prompt += `Goals: ${goals}\n\n`;
        }

        prompt += `Please help me create a comprehensive plan with actionable steps and considerations.`;

        const response = await executeCodex(prompt);

        return {
          content: [
            {
              type: "text",
              text: `## Collaborative Planning Session\n\n**Focus:** ${planning_focus}\n\n${response}`,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    throw new Error(`Tool execution failed: ${error instanceof Error ? error.message : String(error)}`);
  }
});

// CLI argument handling
function showHelp() {
  console.log(`
Codex CLI Bridge Server v1.0.0

USAGE:
  codex-bridge [OPTIONS]

OPTIONS:
  --help, -h    Show this help message
  --version     Show version information

DESCRIPTION:
  MCP Bridge Server enabling Gemini CLI to consult with Codex CLI
  for code generation, analysis, and collaborative problem-solving.

TOOLS:
  brainstorm_with_codex        - Get Codex's perspective on technical challenges
  get_codex_code_analysis      - Have Codex analyze files/directories  
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
  await server.connect(transport);
  console.error("Codex CLI Bridge Server started");
}

if (require.main === module) {
  main().catch((error) => {
    console.error("Server failed to start:", error);
    process.exit(1);
  });
}

export { server };