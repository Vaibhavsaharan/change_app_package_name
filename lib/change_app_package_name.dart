library change_app_package_name;

import './android_rename_steps.dart';

class ChangeAppPackageName {
  static void start(List<String> arguments) {
    if (arguments.isEmpty) {
      print('New package name is missing in paraments. please try again.');
    } else if (arguments.length > 2) {
      print('Wrong arguments, this package accepts new package name and new label');
    } else {
      AndroidRenameSteps(arguments[0], arguments[1]).process();
    }
  }
}
