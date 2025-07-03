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
declare const server: Server<{
    method: string;
    params?: {
        [x: string]: unknown;
        _meta?: {
            [x: string]: unknown;
            progressToken?: string | number | undefined;
        } | undefined;
    } | undefined;
}, {
    method: string;
    params?: {
        [x: string]: unknown;
        _meta?: {
            [x: string]: unknown;
        } | undefined;
    } | undefined;
}, {
    [x: string]: unknown;
    _meta?: {
        [x: string]: unknown;
    } | undefined;
}>;
export { server };
