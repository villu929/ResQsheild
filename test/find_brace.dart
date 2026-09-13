import 'dart:io';

void main() async {
  final lines = await File(r'lib\screens\field_responder_view.dart').readAsLines();
  int depth = 0;
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (i + 1 == 202) {
      depth = 0;
    }
    if (i + 1 >= 202 && i + 1 < 6393) {
      for (final char in line.runes) {
        if (char == 123) depth++; // {
        if (char == 125) { // }
          depth--;
          if (depth == 0) {
            print('Class _FieldResponderViewState CLOSED at line ${i + 1}: "$line"');
          }
        }
      }
    }
  }
  print('Final depth at line 6392: $depth');
}
