/// MCP (Model Context Protocol) server for log_pilot — exposes runtime log state to AI coding agents.
///
/// Start the server from your IDE's MCP configuration (`.cursor/mcp.json`):
/// ```json
/// {
///   "mcpServers": {
///     "LogPilot": {
///       "command": "dart",
///       "args": ["run", "log_pilot_mcp"]
///     }
///   }
/// }
/// ```
///
/// For manual URI (e.g. Flutter Web), add `"--vm-service-uri=ws://127.0.0.1:PORT/TOKEN=/ws"` to args.
library;

export 'src/log_pilot_mcp_server.dart';
