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
