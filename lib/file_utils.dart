import 'dart:io';

import 'package:yaml_modify/yaml_modify.dart';

Future<void> replaceInFile(String path, oldPackage, newPackage) async {
  String? contents = await readFileAsString(path);
  if (contents == null) {
    print('ERROR:: file at $path not found');
    return;
  }
  contents = contents.replaceAll(oldPackage, newPackage);
  await writeFileFromString(path, contents);
}

Future<String?> readFileAsString(String path) async {
  var file = File(path);
  String? contents;

  if (await file.exists()) {
    contents = await file.readAsString();
  }
  return contents;
}

Future<void> writeFileFromString(String path, String contents) async {
  var file = File(path);
  await file.writeAsString(contents);
}

Future<void> deleteOldDirectories(
    String lang, String oldPackage, String basePath) async {
  var dirList = oldPackage.split('.');
  var reversed = dirList.reversed.toList();

  for (int i = 0; i < reversed.length; i++) {
    String path = '$basePath$lang/' + dirList.join('/');

    if (Directory(path).listSync().toList().isEmpty) {
      Directory(path).deleteSync();
    }
    dirList.removeLast();
  }
}

Future<void> changeAndroidAppName(
    String androidManifestPath, oldLabel, newLabel) async {
  String? contents = await readFileAsString(androidManifestPath);
  if (contents == null) {
    print('ERROR:: file at $androidManifestPath not found');
    return;
  }
  contents = contents.replaceAll(oldLabel, newLabel);
  await writeFileFromString(androidManifestPath, contents);
  await modifyYaml(newLabel);
}

modifyYaml(newLabel) {
  File file = File("pubspec.yaml");
  final yaml = loadYaml(file.readAsStringSync());

  final modifiable = getModifiableNode(yaml);
  modifiable['name'] = newLabel;

  final strYaml = toYamlString(modifiable);
  File("pubspec.yaml").writeAsStringSync(strYaml);
  print(strYaml);
}
