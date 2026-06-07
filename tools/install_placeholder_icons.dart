import 'dart:io';

void main() async {
  final src = File('assets/images/app_icon.png');
  if (!await src.exists()) {
    print('Source icon not found: ${src.path}');
    exit(2);
  }

  final androidRes = Directory('android/app/src/main/res');
  final mipmaps = [
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
  ];
  for (final m in mipmaps) {
    final dir = Directory('${androidRes.path}/$m');
    await dir.create(recursive: true);
    final dest = File('${dir.path}/ic_launcher.png');
    await dest.writeAsBytes(await src.readAsBytes());
    final destRound = File('${dir.path}/ic_launcher_round.png');
    await destRound.writeAsBytes(await src.readAsBytes());
    print('Wrote ${dest.path}');
  }

  // Minimal iOS AppIcon asset
  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  await iosDir.create(recursive: true);
  final contents = '''{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "AppIcon.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
''';
  await File('${iosDir.path}/Contents.json').writeAsString(contents);
  await File(
    '${iosDir.path}/AppIcon.png',
  ).writeAsBytes(await src.readAsBytes());
  print('Wrote iOS AppIcon set to ${iosDir.path}');
}
