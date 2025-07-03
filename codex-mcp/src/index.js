"use strict";
/**
 * Codex CLI MCP Bridge Server
 *
 * This server acts as a bridge between Gemini CLI and Codex CLI,
 * enabling Gemini to consult with Codex for code generation and analysis.
 *
 * Architecture:
 * Gemini CLI -> This Bridge Server -> Codex CLI
 */
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.server = void 0;
var index_js_1 = require("@modelcontextprotocol/sdk/server/index.js");
var stdio_js_1 = require("@modelcontextprotocol/sdk/server/stdio.js");
var types_js_1 = require("@modelcontextprotocol/sdk/types.js");
var zod_1 = require("zod");
var child_process_1 = require("child_process");
// Tool schemas
var BrainstormSchema = zod_1.z.object({
    problem_description: zod_1.z.string().describe("Detailed description of the technical challenge or problem"),
    context: zod_1.z.string().optional().describe("Additional context about your project, tech stack, or constraints"),
    approach_preference: zod_1.z.string().optional().describe("Any preferred approaches or technologies to consider"),
});
var CodeAnalysisSchema = zod_1.z.object({
    file_or_directory_path: zod_1.z.string().describe("Path to the file or directory to analyze"),
    analysis_type: zod_1.z.string().default("general").describe("Type of analysis: 'security', 'performance', 'architecture', 'refactoring', or 'general'"),
    specific_concerns: zod_1.z.string().optional().describe("Specific areas of concern or questions about the code"),
});
var PlanningSchema = zod_1.z.object({
    project_description: zod_1.z.string().describe("Description of the project or feature you're planning"),
    planning_focus: zod_1.z.string().describe("What aspect to plan: 'implementation', 'architecture', 'testing', 'deployment', etc."),
    constraints: zod_1.z.string().optional().describe("Any constraints (time, resources, technology, etc.)"),
    goals: zod_1.z.string().optional().describe("Specific goals or success criteria"),
});
// Execute Codex CLI command
function executeCodex(prompt) {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            return [2 /*return*/, new Promise(function (resolve, reject) {
                    var codex = (0, child_process_1.spawn)("codex", ["-q", prompt], {
                        stdio: ["pipe", "pipe", "pipe"],
                    });
                    var stdout = "";
                    var stderr = "";
                    codex.stdout.on("data", function (data) {
                        stdout += data.toString();
                    });
                    codex.stderr.on("data", function (data) {
                        stderr += data.toString();
                    });
                    codex.on("close", function (code) {
                        if (code !== 0) {
                            reject(new Error("Codex CLI failed with code ".concat(code, ": ").concat(stderr)));
                        }
                        else {
                            resolve(stdout.trim());
                        }
                    });
                    codex.on("error", function (error) {
                        reject(new Error("Failed to execute Codex CLI: ".concat(error.message)));
                    });
                })];
        });
    });
}
var server = new index_js_1.Server({
    name: "codex-bridge",
    version: "1.0.0",
}, {
    capabilities: {
        tools: {},
    },
});
exports.server = server;
// Tool registration
server.setRequestHandler(types_js_1.ListToolsRequestSchema, function () { return __awaiter(void 0, void 0, void 0, function () {
    return __generator(this, function (_a) {
        return [2 /*return*/, {
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
                                    description: "Type of analysis: 'security', 'performance', 'architecture', 'refactoring', or 'general'",
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
            }];
    });
}); });
// Tool execution
server.setRequestHandler(types_js_1.CallToolRequestSchema, function (request) { return __awaiter(void 0, void 0, void 0, function () {
    var _a, name, args, _b, _c, problem_description, context, approach_preference, prompt_1, response, _d, file_or_directory_path, analysis_type, specific_concerns, prompt_2, response, _e, project_description, planning_focus, constraints, goals, prompt_3, response, error_1;
    return __generator(this, function (_f) {
        switch (_f.label) {
            case 0:
                _a = request.params, name = _a.name, args = _a.arguments;
                _f.label = 1;
            case 1:
                _f.trys.push([1, 10, , 11]);
                _b = name;
                switch (_b) {
                    case "brainstorm_with_codex": return [3 /*break*/, 2];
                    case "get_codex_code_analysis": return [3 /*break*/, 4];
                    case "collaborative_planning": return [3 /*break*/, 6];
                }
                return [3 /*break*/, 8];
            case 2:
                _c = BrainstormSchema.parse(args), problem_description = _c.problem_description, context = _c.context, approach_preference = _c.approach_preference;
                prompt_1 = "Help me brainstorm solutions for this technical challenge:\n\n".concat(problem_description, "\n\n");
                if (context) {
                    prompt_1 += "Context: ".concat(context, "\n\n");
                }
                if (approach_preference) {
                    prompt_1 += "Preferred approach: ".concat(approach_preference, "\n\n");
                }
                prompt_1 += "Please provide multiple solution approaches with pros/cons and implementation considerations.";
                return [4 /*yield*/, executeCodex(prompt_1)];
            case 3:
                response = _f.sent();
                return [2 /*return*/, {
                        content: [
                            {
                                type: "text",
                                text: "## Codex Brainstorming Session\n\n**Challenge:** ".concat(problem_description, "\n\n").concat(response),
                            },
                        ],
                    }];
            case 4:
                _d = CodeAnalysisSchema.parse(args), file_or_directory_path = _d.file_or_directory_path, analysis_type = _d.analysis_type, specific_concerns = _d.specific_concerns;
                prompt_2 = "Analyze this ".concat(analysis_type, " for: ").concat(file_or_directory_path, "\n\n");
                if (specific_concerns) {
                    prompt_2 += "Focus on these specific concerns: ".concat(specific_concerns, "\n\n");
                }
                prompt_2 += "Please provide detailed insights and recommendations.";
                return [4 /*yield*/, executeCodex(prompt_2)];
            case 5:
                response = _f.sent();
                return [2 /*return*/, {
                        content: [
                            {
                                type: "text",
                                text: "## Codex Code Analysis: ".concat(analysis_type, "\n\n**Target:** ").concat(file_or_directory_path, "\n\n").concat(response),
                            },
                        ],
                    }];
            case 6:
                _e = PlanningSchema.parse(args), project_description = _e.project_description, planning_focus = _e.planning_focus, constraints = _e.constraints, goals = _e.goals;
                prompt_3 = "Let's collaborate on ".concat(planning_focus, " for this project:\n\n");
                prompt_3 += "Project: ".concat(project_description, "\n\n");
                if (constraints) {
                    prompt_3 += "Constraints: ".concat(constraints, "\n\n");
                }
                if (goals) {
                    prompt_3 += "Goals: ".concat(goals, "\n\n");
                }
                prompt_3 += "Please help me create a comprehensive plan with actionable steps and considerations.";
                return [4 /*yield*/, executeCodex(prompt_3)];
            case 7:
                response = _f.sent();
                return [2 /*return*/, {
                        content: [
                            {
                                type: "text",
                                text: "## Collaborative Planning Session\n\n**Focus:** ".concat(planning_focus, "\n\n").concat(response),
                            },
                        ],
                    }];
            case 8: throw new Error("Unknown tool: ".concat(name));
            case 9: return [3 /*break*/, 11];
            case 10:
                error_1 = _f.sent();
                throw new Error("Tool execution failed: ".concat(error_1 instanceof Error ? error_1.message : String(error_1)));
            case 11: return [2 /*return*/];
        }
    });
}); });
// CLI argument handling
function showHelp() {
    console.log("\nCodex CLI Bridge Server v1.0.0\n\nUSAGE:\n  codex-bridge [OPTIONS]\n\nOPTIONS:\n  --help, -h    Show this help message\n  --version     Show version information\n\nDESCRIPTION:\n  MCP Bridge Server enabling Gemini CLI to consult with Codex CLI\n  for code generation, analysis, and collaborative problem-solving.\n\nTOOLS:\n  brainstorm_with_codex        - Get Codex's perspective on technical challenges\n  get_codex_code_analysis      - Have Codex analyze files/directories  \n  collaborative_planning       - Collaborate on implementation planning\n");
}
// Start the server
function main() {
    return __awaiter(this, void 0, void 0, function () {
        var args, transport;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    args = process.argv.slice(2);
                    if (args.includes('--help') || args.includes('-h')) {
                        showHelp();
                        return [2 /*return*/];
                    }
                    if (args.includes('--version')) {
                        console.log('1.0.0');
                        return [2 /*return*/];
                    }
                    transport = new stdio_js_1.StdioServerTransport();
                    return [4 /*yield*/, server.connect(transport)];
                case 1:
                    _a.sent();
                    console.error("Codex CLI Bridge Server started");
                    return [2 /*return*/];
            }
        });
    });
}
if (require.main === module) {
    main().catch(function (error) {
        console.error("Server failed to start:", error);
        process.exit(1);
    });
}
