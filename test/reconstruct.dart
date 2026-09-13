import 'dart:io';
import 'dart:convert';

void main() async {
  var content = await File(r'c:\Users\vishal\Downloads\ResQsheild-main\ResQsheild-main\test\restored_turn0.dart').readAsString();
  print('Initial length: ${content.length}');

  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\f2759be1-e74d-4886-a8f5-c9687af8d11f\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());

  content = content.replaceAll('\r\n', '\n');

  await for (final line in lines) {
    if (line.contains('replace_file_content') && line.contains('field_responder_view.dart')) {
      final obj = jsonDecode(line);
      final calls = obj['tool_calls'] as List? ?? [];
      for (final c in calls) {
        if (c['name'] == 'replace_file_content') {
          final args = c['args'] as Map<String, dynamic>;
          final target = (args['TargetContent'] as String).replaceAll('\r\n', '\n');
          final replacement = (args['ReplacementContent'] as String).replaceAll('\r\n', '\n');
          final desc = args['Description'];

          if (content.contains(target)) {
            content = content.replaceFirst(target, replacement);
            print('Applied step ${obj["step_index"]}: $desc');
          } else {
            final tLines = target.split('\n');
            final cLines = content.split('\n');
            final sIdx = cLines.indexWhere((l) => l.trim() == tLines.first.trim());
            if (sIdx != -1) {
              final actualTarget = cLines.sublist(sIdx, sIdx + tLines.length).join('\n');
              content = content.replaceFirst(actualTarget, replacement);
              print('Applied step ${obj["step_index"]} via line index: $desc');
            } else {
              print('FAILED step ${obj["step_index"]}: $desc (target not found, len ${target.length})');
            }
          }
        }
      }
    }
  }

  print('Final length: ${content.length}');
  final out = File(r'c:\Users\vishal\Downloads\ResQsheild-main\ResQsheild-main\test\reconstructed_field_responder.dart');
  await out.writeAsString(content);
  print('Wrote to ${out.path}');
}
