import 'dart:io';

Future<void> replaceInFile(String path, oldString, newString) async {
  String? contents = await readFileAsString(path);
  if (contents == null) {
    print('ERROR:: file at $path not found');
    return;
  }
  contents = contents.replaceAll(oldString, newString);
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

Future<void> changePackageName(String filePath, oldPackage, newPackage) async {
  await replaceInFile(filePath, oldPackage, newPackage);
}

Future<void> changeAndroidAppName(String filePath, oldLabel, newLabel) async {
  await replaceInFile(filePath, oldLabel, newLabel);
}

Future<void> changeWebsiteSlug(String filePath, oldWebsite, newWebsite) async {
  await replaceInFile(filePath, oldWebsite, newWebsite);
}

Future<void> changeKeys(
    String filePath, String newPackageName, bool isDefaultKey) async {
  File data = File(filePath);
  List<String> dataLines = await data.readAsLines();
  String outputFileString = '';
  String unqiuePackage = newPackageName.split('.')[-1];
  int j = 0;
  for (var line in dataLines) {
    int breakpoint = line.indexOf('=') + 1;
    final newline;
    if (!isDefaultKey) {
      newline = line.replaceRange(
          breakpoint,
          null,
          j == 3
              ? '/home/ubuntu/app/keys/' + unqiuePackage + 'apps.keystore'
              : unqiuePackage);
    } else {
      newline = line.replaceRange(breakpoint, null,
          j == 3 ? '/home/ubuntu/app/keys/kohbeeapps.keystore' : 'kbapps');
    }
    outputFileString =
        outputFileString + (outputFileString.isEmpty ? '' : '\n') + newline;
    j++;
  }
  await writeFileFromString(filePath, outputFileString);
}

Future<void> readLineByLine(String filePath, List<String> removingLines) async {
  File data = File(filePath);
  List<String> dataLines = await data.readAsLines();
  String outputFileString = '';
  for (var line in dataLines) {
    bool foundLine = false;
    String foundLineValue = '';
    for (String removeLine in removingLines) {
      String tempLine = line;
      if (tempLine.trim().contains(removeLine)) {
        foundLine = true;
        foundLineValue = removeLine;
      }
    }
    if (!foundLine) {
      outputFileString =
          outputFileString + (outputFileString.isEmpty ? '' : '\n') + line;
    } else {
      print('removed $foundLineValue');
    }
  }
  await writeFileFromString(filePath, outputFileString);
}
