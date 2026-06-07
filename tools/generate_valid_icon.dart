import 'dart:io';
import 'dart:convert';

void main() async {
  final base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
  final bytes = base64Decode(base64Png);
  final out = File('assets/images/app_icon.png');
  await out.create(recursive: true);
  await out.writeAsBytes(bytes);
  print('Wrote valid PNG (${bytes.length} bytes) to ${out.path}');
}
