import 'package:flutter/cupertino.dart';
var screenSize;

void getSize(BuildContext context) {
  screenSize = MediaQuery.of(context).size;

  if (MediaQuery.of(context).size.width <= MediaQuery.of(context).size.height) {
    screenSize = MediaQuery.of(context).size;
  } else {
    screenSize =Size(screenSize.width/2,screenSize.height);// MediaQuery.of(context).size.width / 2;
  }
}
