library change_app_package_name;

import './android_rename_steps.dart';

class ChangeAppPackageName {
  static void start(List<String> arguments) {
    if (arguments.isEmpty) {
      print('New package name is missing in paraments. please try again.');
    } else if (arguments.length > 5) {
      print('Wrong arguments, this package accepts new package name [str], new label [str], teacherId [str], default key [bool], allow ss [bool');
    } else {
      AndroidRenameSteps(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5]).process();
    }
  }
}
