import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'main.dart';

class HelpWidget extends StatelessWidget {
  const HelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dim = ZugUtils.getScreenDimensions(context);
    return Container(color: Colors.grey,height: dim.height/2, child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
      Align(alignment: Alignment.centerLeft, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text("TV Mode", style: MatrixApp.getTextStyle(Colors.black)),
          const Divider(color: Colors.black),
          Text("Click: focus on selected board",
              style: MatrixApp.getTextStyle(Colors.black)),
          Text("Double Click: flip board",
              style: MatrixApp.getTextStyle(Colors.black)),
          Text("Long Click: load new TV game on selected board",
              style: MatrixApp.getTextStyle(Colors.black)),
        ])),
        //Expanded(child: Container(color: Colors.green,)),
        Align(alignment: Alignment.centerLeft, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text("Play Mode", style: MatrixApp.getTextStyle(Colors.black)),
          const Divider(color: Colors.black),
          Text("Click: return to TV Mode",
              style: MatrixApp.getTextStyle(Colors.black)),
          Text("Double Click: flip board",
              style: MatrixApp.getTextStyle(Colors.black)),
          Text("Long Click: undefined",
              style: MatrixApp.getTextStyle(Colors.black)),
        ])),
      ],
    ));
  }
}