import 'dart:developer' as dev;

import 'package:dfi_seekr/core/constants/constants.dart';

void logInfo(String tag, String msg) => printFunc('[INFO][$tag] $msg');

void logError(String tag, String msg) => printFunc('[ERROR][$tag] $msg');

void printFunc(var str) {
  // if (AppConst.testing)
  // print(str.toString());
  dev.log(str.toString());
  // debugPrint(str.toString());
}
