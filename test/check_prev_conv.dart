import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r'C:\Users\vishal\.gemini\antigravity-ide\brain\3eaf2ed0-e5e4-4313-8ca7-a2ed78c65a52\.system_generated\logs\transcript_full.jsonl');
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
  int lastStep = -1;
  String lastTool = '';
  Map<String, dynamic> lastArgs = {};
  await for (final line in lines) {
    if (line.contains('field_responder_view.dart')) {
      final obj = jsonDecode(line);
      final calls = obj['tool_calls'] as List? ?? [];
      for (final c in calls) {
        if (c['args']?['TargetFile']?.toString().contains('field_responder_view.dart') == true) {
          lastStep = obj['step_index'];
          lastTool = c['name'];
          lastArgs = c['args'];
          print('Step $lastStep tool $lastTool: ${lastArgs["Description"]}');
        }
      }
    }
  }
}
