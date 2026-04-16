import 'dart:convert';

import 'package:log_pilot_mcp/log_pilot_mcp.dart';
import 'package:test/test.dart';

void main() {
  group('LogPilotMcpServer', () {
    test('exports the server class', () {
      expect(LogPilotMcpServer, isNotNull);
    });
  });

  group('deduplicateRecords', () {
    test('returns empty list for empty input', () {
      final result = LogPilotMcpServer.deduplicateRecords([]);
      expect(result, isEmpty);
    });

    test('single record has no count field', () {
      final records = [
        {'level': 'info', 'message': 'hello', 'caller': 'a.dart:1'},
      ];
      final result = LogPilotMcpServer.deduplicateRecords(records);
      expect(result, hasLength(1));
      expect(result.first.containsKey('count'), isFalse);
    });

    test('consecutive identical entries collapse into one with count', () {
      final records = [
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
      ];
      final result = LogPilotMcpServer.deduplicateRecords(records);
      expect(result, hasLength(1));
      expect(result.first['count'], 3);
    });

    test('different callers are kept separate', () {
      final records = [
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
        {'level': 'info', 'message': 'ping', 'caller': 'b.dart:2'},
      ];
      final result = LogPilotMcpServer.deduplicateRecords(records);
      expect(result, hasLength(2));
      expect(result[0].containsKey('count'), isFalse);
      expect(result[1].containsKey('count'), isFalse);
    });

    test('different messages are kept separate', () {
      final records = [
        {'level': 'info', 'message': 'alpha', 'caller': 'a.dart:1'},
        {'level': 'info', 'message': 'beta', 'caller': 'a.dart:1'},
      ];
      final result = LogPilotMcpServer.deduplicateRecords(records);
      expect(result, hasLength(2));
    });

    test('mixed duplicates and unique entries', () {
      final records = [
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
        {'level': 'error', 'message': 'fail', 'caller': 'b.dart:5'},
        {'level': 'info', 'message': 'ping', 'caller': 'a.dart:1'},
      ];
      final result = LogPilotMcpServer.deduplicateRecords(records);
      expect(result, hasLength(3));
      expect(result[0]['count'], 2);
      expect(result[1].containsKey('count'), isFalse);
      expect(result[2].containsKey('count'), isFalse);
    });
  });

  group('levelIndex', () {
    test('maps known levels to ascending indices', () {
      expect(LogPilotMcpServer.levelIndex('verbose'), 0);
      expect(LogPilotMcpServer.levelIndex('debug'), 1);
      expect(LogPilotMcpServer.levelIndex('info'), 2);
      expect(LogPilotMcpServer.levelIndex('warning'), 3);
      expect(LogPilotMcpServer.levelIndex('error'), 4);
      expect(LogPilotMcpServer.levelIndex('fatal'), 5);
    });

    test('is case-insensitive', () {
      expect(LogPilotMcpServer.levelIndex('INFO'), 2);
      expect(LogPilotMcpServer.levelIndex('Warning'), 3);
    });

    test('unknown level returns -1', () {
      expect(LogPilotMcpServer.levelIndex('unknown'), -1);
      expect(LogPilotMcpServer.levelIndex(''), -1);
    });
  });

  group('parseEntries', () {
    test('parses JSON string entries', () {
      final raw = [
        jsonEncode({'level': 'info', 'message': 'hello'}),
        jsonEncode({'level': 'error', 'message': 'fail'}),
      ];
      final result = LogPilotMcpServer.parseEntries(raw);
      expect(result, hasLength(2));
      expect(result[0]['message'], 'hello');
      expect(result[1]['level'], 'error');
    });

    test('parses map entries', () {
      final raw = [
        {'level': 'info', 'message': 'hello'},
      ];
      final result = LogPilotMcpServer.parseEntries(raw);
      expect(result, hasLength(1));
      expect(result[0]['message'], 'hello');
    });

    test('returns empty list for empty input', () {
      expect(LogPilotMcpServer.parseEntries([]), isEmpty);
    });
  });

  group('lastEntryId', () {
    test('combines timestamp, message, and level', () {
      final entry = {
        'timestamp': '2026-01-01T00:00:00',
        'message': 'test',
        'level': 'info',
      };
      expect(
        LogPilotMcpServer.lastEntryId(entry),
        '2026-01-01T00:00:00|test|info',
      );
    });

    test('handles null fields gracefully', () {
      final entry = <String, dynamic>{};
      expect(LogPilotMcpServer.lastEntryId(entry), 'null|null|null');
    });
  });
}
