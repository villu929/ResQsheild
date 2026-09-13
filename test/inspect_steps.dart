import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\f2759be1-e74d-4886-a8f5-c9687af8d11f\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    if (line.contains('"step_index":11,')) {
      final obj = jsonDecode(line);
      print('Step 11 content: ${obj["content"]?.toString().substring(0, 300)}');
    }
    if (line.contains('"step_index":117,')) {
      final obj = jsonDecode(line);
      print('Step 117 tool_calls: ${jsonEncode(obj["tool_calls"])}');
    }
  }
}
