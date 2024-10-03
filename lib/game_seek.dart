import 'package:flutter/material.dart';
import 'client.dart';
import 'main.dart';

class SeekWidget extends StatefulWidget {
  final MatrixClient client;
  const SeekWidget(this.client,{super.key});

  @override
  State<StatefulWidget> createState() => _SeekWidgetState();

}

class _SeekWidgetState extends State<SeekWidget> {
  int minutes = 8, inc = 0;
  bool rated = false;

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey, height: 360, child: Center(child: Column(children: [
      Row(
        children: [
          Text("Minutes: $minutes",style: MatrixApp.getTextStyle(Colors.black)),
          Slider(value: minutes as double, min: 8, max: 60, divisions: 52,
              onChanged: (v) => setState(() {
                minutes = v.floor();
              })),
        ],
      ),
      Row(
        children: [
          Text("Inc: $inc",style: MatrixApp.getTextStyle(Colors.black)),
          Slider(value: inc as double, min: 0, max: 12, divisions: 13,
              onChanged: (v) => setState(() {
                inc = v.floor();
              })),
        ],
      ),
      Row(
        children: [
          Text("Rated",style: MatrixApp.getTextStyle(Colors.black)),
          Checkbox(value: rated, onChanged: (b) => setState(() {
            rated = b ?? false;
          })),
        ],
      ),
      TextButton(onPressed: () {
        widget.client.seekGame(minutes,inc,rated);
        Navigator.of(context).pop();
      } , child: Text("Seek",style: MatrixApp.getTextStyle(Colors.black))),
    ],
    )));
  }

}