import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\f2759be1-e74d-4886-a8f5-c9687af8d11f\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
  int stepIdx = 0;
  await for (final line in lines) {
    if (line.contains('replace_file_content') && line.contains('field_responder_view.dart')) {
      final obj = jsonDecode(line);
      final calls = obj['tool_calls'] as List? ?? [];
      for (final c in calls) {
        if (c['name'] == 'replace_file_content') {
          final args = c['args'] as Map<String, dynamic>;
          print('=== STEP ${obj["step_index"]}: ${args["Description"]} ===');
          print('Start: ${args["StartLine"]} End: ${args["EndLine"]}');
          print('Target (${args["TargetContent"]?.toString().length} chars)');
          print('Replacement (${args["ReplacementContent"]?.toString().length} chars)');
        }
      }
    }
  }
}
