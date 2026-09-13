import 'dart:io';
import 'dart:convert';

void main() async {
  final dir = Directory(r'C:\Users\vishal\.gemini\antigravity-ide\brain');
  await for (final entity in dir.list()) {
    if (entity is Directory) {
      final log = File('${entity.path}/.system_generated/logs/transcript.jsonl');
      if (await log.exists()) {
        final line = await log.openRead().transform(utf8.decoder).transform(const LineSplitter()).firstWhere((_) => true, orElse: () => '');
        if (line.isNotEmpty) {
          try {
            final obj = jsonDecode(line);
            print('${entity.path.split(Platform.pathSeparator).last} : ${obj["created_at"]}');
          } catch (_) {}
        }
      }
    }
  }
}
