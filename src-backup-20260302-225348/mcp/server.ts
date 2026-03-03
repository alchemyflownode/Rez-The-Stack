import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, unlink } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';

const execAsync = promisify(exec);
const ALLOWED_APPS = ['notepad', 'calc', 'mspaint', 'chrome', 'code'];

const server = new Server(
  { name: 'rez-hive-mcp', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    { name: 'execute_python', description: 'Execute Python code', inputSchema: { type: 'object', properties: { code: { type: 'string' } }, required: ['code'] } },
    { name: 'launch_app', description: 'Launch app', inputSchema: { type: 'object', properties: { app: { type: 'string' } }, required: ['app'] } }
  ]
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  try {
    if (name === 'execute_python') {
      const tempFile = join(tmpdir(), ez_\.py);
      await writeFile(tempFile, args.code);
      const { stdout } = await execAsync(python "\", { timeout: 10000 });
      await unlink(tempFile);
      return { content: [{ type: 'text', text: stdout }] };
    }
    if (name === 'launch_app') {
      if (!ALLOWED_APPS.includes(args.app.toLowerCase())) throw new Error('App not allowed');
      await execAsync(start \);
      return { content: [{ type: 'text', text: 'Launched' }] };
    }
  } catch (e: any) { return { content: [{ type: 'text', text: e.message }], isError: true }; }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('🦊 MCP Server Active');
}
main();
