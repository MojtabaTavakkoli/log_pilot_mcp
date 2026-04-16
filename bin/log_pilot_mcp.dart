import 'dart:async';
import 'dart:io' as io;

import 'package:dart_mcp/stdio.dart';
import 'package:log_pilot_mcp/log_pilot_mcp.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final uri = _parseArg(args, '--vm-service-uri=');
  final uriFile = _parseArg(args, '--vm-service-uri-file=');
  final projectRoot = _parseArg(args, '--project-root=');

  if (uri != null) {
    _startServer(uri, uriFile: uriFile);
    return;
  }

  final filePath = uriFile ?? _defaultUriFilePath(projectRoot: projectRoot);
  if (filePath != null) {
    io.stderr.writeln(
      '[log_pilot_mcp] Resolved URI file path: $filePath',
    );
    final file = io.File(filePath);
    if (file.existsSync()) {
      final discovered = file.readAsStringSync().trim();
      if (discovered.isNotEmpty) {
        io.stderr.writeln(
          '[log_pilot_mcp] Auto-discovered VM service URI from $filePath',
        );
        _startServer(discovered, uriFile: filePath);
        return;
      }
    }
  }

  final envUri = io.Platform.environment['LOG_PILOT_VM_SERVICE_URI']
      ?? io.Platform.environment['log_pilot_VM_SERVICE_URI'];
  if (envUri != null) {
    _startServer(envUri, uriFile: filePath);
    return;
  }

  if (filePath != null) {
    io.stderr.writeln(
      '[log_pilot_mcp] Waiting for VM service URI at $filePath...\n'
      '           Start your Flutter app in debug mode.\n'
      '           If you are running on Flutter Web, auto-discovery is\n'
      '           not supported — pass --vm-service-uri=ws://... directly.',
    );
    _waitForUriFile(filePath);
    return;
  }

  _printUsage();
  io.exitCode = 1;
}

void _printUsage() {
  io.stderr.writeln(
    'log_pilot_mcp — MCP server for log_pilot\n'
    '\n'
    'Usage: dart run log_pilot_mcp [options]\n'
    '\n'
    'The VM service URI is printed when you run:\n'
    '  flutter run --verbose\n'
    '\n'
    'Options:\n'
    '  --vm-service-uri=URI        Connect to this VM service URI directly.\n'
    '  --vm-service-uri-file=PATH  Read the URI from this file. The file\n'
    '                              is watched for changes, so the server\n'
    '                              reconnects automatically on app restart.\n'
    '  --project-root=PATH         Absolute path to the Flutter app\'s\n'
    '                              project root. Used to locate\n'
    '                              .dart_tool/log_pilot_vm_service_uri\n'
    '                              when auto-discovery from cwd fails\n'
    '                              (common on Windows).\n'
    '  -h, --help                  Show this help message.\n'
    '\n'
    'Auto-discovery: If no flags are given, the server looks for\n'
    '  .dart_tool/log_pilot_vm_service_uri (written by LogPilot on init()).\n'
    '\n'
    'You can also set the LOG_PILOT_VM_SERVICE_URI environment variable.',
  );
}

LogPilotMcpServer? _server;
StreamSubscription<io.FileSystemEvent>? _waitSubscription;

void _startServer(String uri, {String? uriFile}) {
  // Cancel the creation watcher — server is starting, no more duplicates.
  _waitSubscription?.cancel();
  _waitSubscription = null;

  if (_server != null) {
    _server!.updateVmServiceUri(uri);
    return;
  }

  _server = LogPilotMcpServer(
    stdioChannel(input: io.stdin, output: io.stdout),
    vmServiceUri: uri,
  );

  if (uriFile != null) {
    _watchUriFile(uriFile);
  }
}

/// Watch for the URI file to appear (creation) and then start the server.
void _waitForUriFile(String path) {
  final file = io.File(path);
  final dir = file.parent;
  if (!dir.existsSync()) {
    io.stderr.writeln(
      '[log_pilot_mcp] Parent directory ${dir.path} does not exist.\n'
      '           Run "flutter pub get" in your app first to create .dart_tool,\n'
      '           then restart the MCP server.',
    );
    return;
  }

  _waitSubscription = dir
      .watch(events: io.FileSystemEvent.create | io.FileSystemEvent.modify)
      .listen((event) {
    if (event.path.replaceAll('\\', '/') !=
        file.path.replaceAll('\\', '/')) {
      return;
    }
    try {
      final discovered = file.readAsStringSync().trim();
      if (discovered.isEmpty) return;
      io.stderr.writeln(
        '[log_pilot_mcp] Auto-discovered VM service URI from $path',
      );
      _startServer(discovered, uriFile: path);
    } catch (_) {}
  });
}

void _watchUriFile(String path) {
  final file = io.File(path);
  final dir = file.parent;
  if (!dir.existsSync()) return;

  dir.watch(events: io.FileSystemEvent.modify | io.FileSystemEvent.create)
      .listen((event) {
    if (event.path.replaceAll('\\', '/') !=
        file.path.replaceAll('\\', '/')) {
      return;
    }

    try {
      final newUri = file.readAsStringSync().trim();
      if (newUri.isEmpty) return;
      if (newUri == _server?.vmServiceUri) return;

      io.stderr.writeln(
        '[log_pilot_mcp] VM service URI changed in $path — reconnecting...',
      );
      _server?.updateVmServiceUri(newUri);
    } catch (_) {}
  });
}

String? _parseArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length);
    }
  }
  return null;
}

/// Locate the auto-written URI file. Checks (in order):
/// 1. The [projectRoot] directory (from `--project-root`), if provided.
/// 2. The current working directory and up to 5 parent directories.
///
/// Returns the path to `.dart_tool/log_pilot_vm_service_uri`, or `null` if
/// no `.dart_tool` directory can be found.
String? _defaultUriFilePath({String? projectRoot}) {
  if (projectRoot != null) {
    final explicit = io.File('$projectRoot/.dart_tool/log_pilot_vm_service_uri');
    final dartTool = io.Directory('$projectRoot/.dart_tool');
    if (explicit.existsSync()) return explicit.path;
    if (dartTool.existsSync()) return explicit.path;
    io.stderr.writeln(
      '[log_pilot_mcp] --project-root=$projectRoot does not contain '
      '.dart_tool — falling back to cwd detection.',
    );
  }

  var dir = io.Directory.current;
  io.stderr.writeln('[log_pilot_mcp] Searching for .dart_tool from cwd: ${dir.path}');
  for (var i = 0; i < 5; i++) {
    final candidate = io.File('${dir.path}/.dart_tool/log_pilot_vm_service_uri');
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  final dartTool = io.Directory('${io.Directory.current.path}/.dart_tool');
  if (dartTool.existsSync()) {
    return '${dartTool.path}/log_pilot_vm_service_uri';
  }

  io.stderr.writeln(
    '[log_pilot_mcp] Could not locate .dart_tool in cwd or parent '
    'directories.\n'
    '           Use --project-root=<APP_PATH> or --vm-service-uri=ws://...\n'
    '           On Flutter Web, auto-discovery is not available — you must\n'
    '           pass --vm-service-uri directly.',
  );
  return null;
}
