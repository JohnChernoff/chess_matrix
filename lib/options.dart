import 'package:chess_matrix/main.dart';
import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'client.dart';
import 'matrix_fields.dart';

class OptionWidget extends StatefulWidget {
  final MatrixClient client;
  const OptionWidget(this.client,{super.key});

  @override
  State<StatefulWidget> createState() => _OptionWidgetState();

}

class _OptionWidgetState extends State<OptionWidget> {
  @override
  Widget build(BuildContext context) {
    Axis axis = ZugUtils.getScreenDimensions(context).getMainAxis();
    return Container(color: Colors.grey, child: Flex(direction: Axis.vertical,
        children: [
          ElevatedButton(
              onPressed: () => MatrixApp.menuBuilder(context, getColorPickers(widget.client,axis)),
              child: Text("Colors",style: MatrixApp.getTextStyle(Colors.black)),
          ),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: MatrixClient.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
              DropdownMenuItem(value: GameStyle.values.elementAt(index),
                  child: Text("Game Style: ${GameStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (GameStyle? value) => setState(() {
                widget.client.setGameStyle(value!);
              })),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: MatrixClient.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
              DropdownMenuItem(value: PieceStyle.values.elementAt(index),
                  child: Text("Piece Style: ${PieceStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (PieceStyle? value) => setState(() {
                widget.client.setPieceStyle(value!);
              })),
          Row(
            children: [
              Text("Resolution: ${MatrixClient.matrixResolution}",style: MatrixApp.getTextStyle(Colors.black)),
              Slider(value: MatrixClient.matrixResolution as double, divisions: 50, min: 50, max: 550,
                  onChanged: (double value) {
                    setState(() {
                      MatrixClient.matrixResolution = value.round();
                    });
                  }),
            ],
          ),
          Row(
            children: [
              Text("Intensity",style: MatrixApp.getTextStyle(Colors.black)),
              Slider(value: (widget.client.maxControl-6).abs() as double, min: 1, max: 5,
                  onChanged: (double value) {
                    setState(() {
                      widget.client.setMaxControl((value.round() - 6).abs());
                    });
                  }),
            ],
          ),
          ElevatedButton(
            onPressed: () => widget.client.loadTVGames(reset: false),
            child: Text("Reload",style: MatrixApp.getTextStyle(Colors.black)),
          ),
        ],
    ));
  }

  Widget getColorPickers(MatrixClient client, Axis axis) {
    return Container(
        color: Colors.brown,
        width: double.maxFinite,
        height: double.maxFinite,
        child: ListView(
          scrollDirection: axis,
          children: [
            Column(
              children: [
                Text("White Color: ",
                    style: MatrixApp.getTextStyle(Colors.white)),
                ColorPicker(
                  onColorSelected: (Color color) {
                    client.setColorScheme(whiteColor: color);
                  },
                  selectedColor: client.colorScheme.whiteColor,
                  config: const ColorPickerConfig(),
                  darkMode: true,
                  onClose: () {},
                ),
              ],
            ),
            Column(
              children: [
                Text("Black Color: ",
                    style: MatrixApp.getTextStyle(Colors.black)),
                ColorPicker(
                  onColorSelected: (Color color) {
                    client.setColorScheme(blackColor: color);
                  },
                  selectedColor: client.colorScheme.blackColor,
                  config: const ColorPickerConfig(),
                  darkMode: true,
                  onClose: () {},
                ),
              ],
            ),
            Column(
              children: [
                Text("Void Color: ",
                    style: MatrixApp.getTextStyle(Colors.grey)),
                ColorPicker(
                  onColorSelected: (Color color) {
                    client.setColorScheme(voidColor: color);
                  },
                  selectedColor: client.colorScheme.voidColor,
                  config: const ColorPickerConfig(),
                  darkMode: true,
                  onClose: () {},
                ),
              ],
            )
          ],
        ));
  }
}


