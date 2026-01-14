import 'dart:developer' as dev;

void logInfo(String tag, String msg) => printFunc('[INFO][$tag] $msg');

void logError(String tag, String msg) => printFunc('[ERROR][$tag] $msg');

void printFunc(var str) {
  // if(isTesting)
  // print(str.toString());
  dev.log(str.toString());
  // debugPrint(str.toString());
}
