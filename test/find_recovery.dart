import 'dart:io';
import 'dart:convert';

void main() async {
  final dir = Directory(r'C:\Users\vishal\.gemini\antigravity-ide\brain');
  final matches = <Map<String, dynamic>>[];
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('transcript_full.jsonl')) {
      try {
        final lines = entity.openRead().transform(utf8.decoder).transform(const LineSplitter());
        await for (final line in lines) {
          if (line.contains('write_to_file') && line.contains('field_responder_view.dart')) {
            final obj = jsonDecode(line);
            for (final c in obj['tool_calls'] ?? []) {
              if (c['name'] == 'write_to_file' && c['args']['TargetFile']?.toString().contains('field_responder_view.dart') == true) {
                matches.add({
                  'path': entity.path,
                  'date': obj['created_at'] ?? '',
                  'len': (c['args']['CodeContent'] as String).length,
                  'content': c['args']['CodeContent'] as String,
                });
              }
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }
  print('Total matches: ${matches.length}');
  matches.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  for (final m in matches) {
    print('${m["date"]} - ${m["path"]} (${m["len"]} chars)');
  }
  if (matches.isNotEmpty) {
    final latest = matches.last;
    final out = File(r'c:\Users\vishal\Downloads\ResQsheild-main\ResQsheild-main\test\recovered_latest.dart');
    await out.writeAsString(latest['content']);
    print('Wrote latest to ${out.path} (${latest["date"]})');
  }
}
