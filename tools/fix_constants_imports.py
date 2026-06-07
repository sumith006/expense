from pathlib import Path
root = Path('.').resolve()
for p in root.rglob('*.dart'):
    if p.parts[0] != 'lib':
        continue
    text = p.read_text(encoding='utf-8')
    new = text.replace("import '../utils/constants.dart';", "import 'package:expense/utils/constants.dart';")
    new = new.replace("import '../../utils/constants.dart';", "import 'package:expense/utils/constants.dart';")
    if new != text:
        p.write_text(new, encoding='utf-8')
        print('updated', p)
