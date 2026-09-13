import 'dart:io';
import 'dart:convert';

void main() async {
  final content = (await File(r'c:\Users\vishal\Downloads\ResQsheild-main\ResQsheild-main\test\restored_turn0.dart').readAsString()).replaceAll('\r\n', '\n');

  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\f2759be1-e74d-4886-a8f5-c9687af8d11f\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());

  await for (final line in lines) {
    if (line.contains('"step_index":149,')) {
      final obj = jsonDecode(line);
      final c = obj['tool_calls'][0];
      final target = (c['args']['TargetContent'] as String).replaceAll('\r\n', '\n');
      final targetLines = target.split('\n');
      final contentLines = content.split('\n');
      final startIdx = contentLines.indexWhere((l) => l.trim() == targetLines.first.trim());
      print('startIdx: $startIdx, total target lines: ${targetLines.length}');
      for (int i = 0; i < targetLines.length; i++) {
        if (contentLines[startIdx + i] != targetLines[i]) {
          print('Line $i: Content: "${contentLines[startIdx + i]}" (len ${contentLines[startIdx + i].length}) vs Target: "${targetLines[i]}" (len ${targetLines[i].length})');
        }
      }
    }
  }
}
