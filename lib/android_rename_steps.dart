// ignore_for_file: unused_local_variable

import 'dart:io';

import './file_utils.dart';

class AndroidRenameSteps {
  final String newPackageName;
  final String newLabel;
  final String teacherId;
  final String defaultKey;
  final String allowSS;
  final String primaryColor;
  String? oldPackageName;
  String? oldLabel;

  static const String PATH_APP_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_BUILD_GRADLE = 'android/build.gradle';
  static const String PATH_KEY_PROPERTIES = 'android/key.properties';
  static const String PATH_MANIFEST =
      'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG =
      'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE =
      'android/app/src/profile/AndroidManifest.xml';
  static const String PATH_MAIN_WHITELABEL_DEV = 'lib/main_whitelabel_dev.dart';
  static const String PATH_MAIN_WHITELABEL_PROD =
      'lib/main_whitelabel_prod.dart';
  static const String PATH_GLOBALS = 'lib/common/globals.dart';
  static const String PATH_WEBSITE_LOGIN =
      'lib/ui/teacher/website_viewer/website_login.dart';
  static const String PATH_ACTIVITY = 'android/app/src/main/';

  AndroidRenameSteps(this.newPackageName, this.newLabel, this.teacherId,
      this.defaultKey, this.allowSS, this.primaryColor);

  Future<void> process() async {
    if (!await File(PATH_APP_BUILD_GRADLE).exists()) {
      print(
          'ERROR:: build.gradle file not found, Check if you have a correct android directory present in your project'
          '\n\nrun " flutter create . " to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_APP_BUILD_GRADLE);
    String? contentsManifest = await readFileAsString(PATH_MANIFEST);

    var regApplication =
        RegExp('applicationId "(.*)"', caseSensitive: true, multiLine: false);
    var regLable =
        RegExp('android:label="(.*?)"', caseSensitive: true, multiLine: false);

    var name = regApplication.firstMatch(contents!)!.group(1);
    oldPackageName = name;

    var label = regLable.firstMatch(contentsManifest!)!.group(1);
    oldLabel = label;

    print("Old Package Name: $oldPackageName");
    print("Old app label $oldLabel");

    print('Updating build.gradle File');
    await _replace(PATH_APP_BUILD_GRADLE);

    print('Updating Main Manifest file');
    await _replace(PATH_MANIFEST);

    print('Updating Debug Manifest file');
    await _replace(PATH_MANIFEST_DEBUG);

    print('Updating Profile Manifest file');
    await _replace(PATH_MANIFEST_PROFILE);

    await updateMainActivityAndApplication();

    await renameApp();

    await removePlayServices();

    await replaceWebsite();

    await replaceKeys();

    await updateConfig();

    await updateColors();
  }

  Future<void> updateMainActivityAndApplication() async {
    String oldPackagePath = oldPackageName!.replaceAll('.', '/');
    String javaPathMainActivity =
        PATH_ACTIVITY + 'java/$oldPackagePath/MainActivity.java';
    String kotlinPathMainActivity =
        PATH_ACTIVITY + 'kotlin/$oldPackagePath/MainActivity.kt';
    String javaPathApplication =
        PATH_ACTIVITY + 'java/$oldPackagePath/Application.java';
    String kotlinPathApplication =
        PATH_ACTIVITY + 'kotlin/$oldPackagePath/Application.kt';

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newJavaPathMainActivity =
        PATH_ACTIVITY + 'java/$newPackagePath/MainActivity.java';
    String newKotlinPathMainActivity =
        PATH_ACTIVITY + 'kotlin/$newPackagePath/MainActivity.kt';
    String newJavaPathApplication =
        PATH_ACTIVITY + 'java/$newPackagePath/Application.java';
    String newKotlinPathApplication =
        PATH_ACTIVITY + 'kotlin/$newPackagePath/Application.kt';

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
    String label = newLabel.replaceAll('+', ' ');
    label = label.replaceAll('^', '\'');
    String oldLabelManifestString = 'android:label="$oldLabel"';
    String newLabelManifestString = "android:label=\"$label\"";
    String oldLabelMainFileString = "title: 'Web App'";
    String newLabelMainFileString = "title: \"$label\"";
    print('Updating app name in manifest');
    await changeAndroidAppName(
        PATH_MANIFEST, oldLabelManifestString, newLabelManifestString);
    print('Updating app name in main whitelabel dev');
    await changeAndroidAppName(PATH_MAIN_WHITELABEL_DEV, oldLabelMainFileString,
        newLabelMainFileString);
    print('Updating app name in main whitelabel prod');
    await changeAndroidAppName(PATH_MAIN_WHITELABEL_PROD,
        oldLabelMainFileString, newLabelMainFileString);
  }

  Future<void> replaceWebsite() async {
    String oldWebsiteSlugString =
        'whitelabelTeacherId = "QTvuyamXm6WsoFgQ6UPzcEiSKFB2";';
    String newWebsiteSlugString = 'whitelabelTeacherId = "$teacherId";';
    print('replacing website slug in globals');
    await changeWebsiteSlug(
        PATH_GLOBALS, oldWebsiteSlugString, newWebsiteSlugString);
  }

  Future<void> updateConfig() async {
    bool allowScreenShot = allowSS == 'True' ? true : false;
    String oldConfigString = 'allowScreenShots = false;';
    String newConfigString = 'allowScreenShots = $allowScreenShot;';
    print('updating screenshot config');
    await changeScreenShotConfig(
        PATH_GLOBALS, oldConfigString, newConfigString);
  }

  Future<void> updateColors() async {
    if (primaryColor == 'none') {
      return;
    }
    String oldColorString = 'var selectedColor = primaryBlue;';
    String newColorString =
        'var selectedColor = HexColor.fromHex($primaryColor);';
    print('replacing primary color in learner login page');
    await changeWebsiteSlug(PATH_WEBSITE_LOGIN, oldColorString, newColorString);
  }

  Future<void> replaceKeys() async {
    bool isDefaultKey = defaultKey == 'True' ? true : false;
    await changeKeys(PATH_KEY_PROPERTIES, newPackageName, isDefaultKey);
  }

  Future<void> removePlayServices() async {
    List<String> googleServices = [
      'com.google.android.gms:play-services-ads-identifier',
      'com.google.gms.google-services',
      'com.google.firebase.crashlytics',
      'com.google.firebase:firebase-analytics',
      'com.google.firebase:firebase-appindexing',
      'com.google.firebase:firebase-messaging'
    ];
    List<String> googleDependencies = [
      'com.google.gms:google-services',
      'com.google.firebase:firebase-crashlytics-gradle'
    ];
    await readLineByLine(PATH_APP_BUILD_GRADLE, googleServices);
    await readLineByLine(PATH_BUILD_GRADLE, googleDependencies);
  }

  Future<void> _replace(String path) async {
    await changePackageName(path, oldPackageName, newPackageName);
  }
}
