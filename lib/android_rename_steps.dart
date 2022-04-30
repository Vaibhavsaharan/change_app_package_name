import 'dart:io';

import './file_utils.dart';

class AndroidRenameSteps {
  final String newPackageName;
  final String newLabel;
  String? oldPackageName;
  String? oldLabel;

  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_MANIFEST =
      'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG =
      'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE =
      'android/app/src/profile/AndroidManifest.xml';

  static const String PATH_ACTIVITY = 'android/app/src/main/';

  AndroidRenameSteps(this.newPackageName, this.newLabel);

  Future<void> process() async {
    if (!await File(PATH_BUILD_GRADLE).exists()) {
      print(
          'ERROR:: build.gradle file not found, Check if you have a correct android directory present in your project'
          '\n\nrun " flutter create . " to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_BUILD_GRADLE);
    String? contentsManifest = await readFileAsString(PATH_MANIFEST);

    var regApplication =
        RegExp('applicationId "(.*)"', caseSensitive: true, multiLine: false);
    var regLable =
        RegExp('android:label="(.*)"', caseSensitive: true, multiLine: false);

    var name = regApplication.firstMatch(contents!)!.group(1);
    oldPackageName = name;

    var label = regLable.firstMatch(contentsManifest!)!.group(1);
    oldLabel = label;

    print("Old Package Name: $oldPackageName");

    print('Updating build.gradle File');
    await _replace(PATH_BUILD_GRADLE);

    print('Updating Main Manifest file');
    await _replace(PATH_MANIFEST);

    print('Updating Debug Manifest file');
    await _replace(PATH_MANIFEST_DEBUG);

    print('Updating Profile Manifest file');
    await _replace(PATH_MANIFEST_PROFILE);

    await updateMainActivityAndApplication();

    await renameApp();
  }

  Future<void> updateMainActivityAndApplication() async {
    String oldPackagePath = oldPackageName!.replaceAll('.', '/');
    String javaPathMainActivity =
        PATH_ACTIVITY + 'java/$oldPackagePath/MainActivity.java';
    String kotlinPathMainActivity =
        PATH_ACTIVITY + 'kotlin/$oldPackagePath/MainActivity.kt';
    String javaPathApplication =
        PATH_ACTIVITY + 'java/$oldPackagePath/MainActivity.java';
    String kotlinPathApplication =
        PATH_ACTIVITY + 'kotlin/$oldPackagePath/MainActivity.kt';

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newJavaPathMainActivity =
        PATH_ACTIVITY + 'java/$newPackagePath/MainActivity.java';
    String newKotlinPathMainActivity =
        PATH_ACTIVITY + 'kotlin/$newPackagePath/MainActivity.kt';
    String newJavaPathApplication =
        PATH_ACTIVITY + 'java/$newPackagePath/MainActivity.java';
    String newKotlinPathApplication =
        PATH_ACTIVITY + 'kotlin/$newPackagePath/MainActivity.kt';

    if (await File(javaPathMainActivity).exists()) {
      print('Project is using Java');
      print('Updating MainActivity.java');
      print('Updating Applicatio.java');
      await _replace(javaPathMainActivity);
      await _replace(javaPathApplication);

      print('Creating New Directory Structure');
      await Directory(PATH_ACTIVITY + 'java/$newPackagePath')
          .create(recursive: true);
      await File(javaPathMainActivity).rename(newJavaPathMainActivity);
      await File(javaPathApplication).rename(newJavaPathApplication);

      print('Deleting old directories');
      await deleteOldDirectories('java', oldPackageName!, PATH_ACTIVITY);
    } else if (await File(kotlinPathMainActivity).exists()) {
      print('Project is using kotlin');
      print('Updating MainActivity.kt');
      await _replace(kotlinPathMainActivity);

      print('Creating New Directory Structure');
      await Directory(PATH_ACTIVITY + 'kotlin/$newPackagePath')
          .create(recursive: true);
      await File(kotlinPathMainActivity).rename(newKotlinPathMainActivity);

      print('Deleting old directories');
      await deleteOldDirectories('kotlin', oldPackageName!, PATH_ACTIVITY);
    } else {
      print(
          'ERROR:: Unknown Directory structure, both java & kotlin files not found.');
    }
  }

  Future<void> renameApp() async {
    print('Updating app name');
    await changeAndroidAppName(PATH_MANIFEST, oldLabel, newLabel);
  }

  Future<void> _replace(String path) async {
    await replaceInFile(path, oldPackageName, newPackageName);
  }
}
