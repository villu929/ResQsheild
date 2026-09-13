import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\f2759be1-e74d-4886-a8f5-c9687af8d11f\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
  int idx = 0;
  await for (final line in lines) {
    idx++;
    if (line.contains('field_responder_view.dart') && (line.contains('write_to_file') || line.contains('replace_file_content') || line.contains('multi_replace_file_content'))) {
      try {
        final obj = jsonDecode(line);
        final calls = obj['tool_calls'] as List? ?? [];
        for (final c in calls) {
          print('Line $idx step ${obj["step_index"]} tool: ${c["name"]} args: ${c["args"]}');
        }
      } catch (e) {
        // ignore
      }
    }
  }
}
