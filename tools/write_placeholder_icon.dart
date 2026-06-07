import 'dart:convert';
import 'dart:io';

void main() async {
  // 1x1 transparent PNG (small placeholder). Replace with your artwork later.
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII=';
  final bytes = base64Decode(base64Png);

  final out = File('assets/images/app_icon.png');
  await out.create(recursive: true);
  await out.writeAsBytes(bytes);
  print('Wrote placeholder icon to ${out.path} (${bytes.length} bytes)');
}
