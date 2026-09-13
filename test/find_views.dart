import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\f2759be1-e74d-4886-a8f5-c9687af8d11f\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());

  await for (final line in lines) {
    if (line.contains('view_file') && line.contains('field_responder_view.dart')) {
      final obj = jsonDecode(line);
      final c = obj['tool_calls']?[0];
      print('view_file in step ${obj["step_index"]}: ${c?["args"]}');
    }
  }
}
