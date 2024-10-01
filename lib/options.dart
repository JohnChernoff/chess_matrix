import 'package:chess_matrix/main.dart';
import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'board_matrix.dart';
import 'client.dart';
import 'matrix_fields.dart';

class OptionWidget extends StatefulWidget {
  final MatrixClient client;
  const OptionWidget(this.client,{super.key});

  @override
  State<StatefulWidget> createState() => _OptionWidgetState();

}

class _OptionWidgetState extends State<OptionWidget> {
  double? resolution;
  double? intensity;
  ColorStyle? colorStyle;

  @override
  Widget build(BuildContext context) {
    Axis axis = ZugUtils.getScreenDimensions(context).getMainAxis();
    return Container(color: Colors.grey, height: 500, child: Flex(direction: Axis.vertical,
        children: [
          DropdownButton(value: colorStyle, items: List.generate(ColorStyle.values.length, (index) =>
              DropdownMenuItem(value: ColorStyle.values.elementAt(index),
                  child: Text("Color Style: ${ColorStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (ColorStyle? style) => widget.client.setColorScheme(
                whiteColor: style?.colorScheme.whiteColor,
                blackColor: style?.colorScheme.blackColor,
                voidColor: style?.colorScheme.voidColor,
              )),
          ElevatedButton(
              onPressed: () => MatrixApp.menuBuilder(context, getColorPickers(widget.client,axis)),
              child: Text("Colors",style: MatrixApp.getTextStyle(Colors.black)),
          ),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: widget.client.mixStyle, items: List.generate(MixStyle.values.length, (index) =>
              DropdownMenuItem(value: MixStyle.values.elementAt(index),
                  child: Text("Mix Style: ${MixStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (MixStyle? value) => setState(() {
                widget.client.setMixStyle(value!);
              })),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: widget.client.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
              DropdownMenuItem(value: GameStyle.values.elementAt(index),
                  child: Text("Game Style: ${GameStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (GameStyle? value) => setState(() {
                widget.client.setGameStyle(value!);
              })),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: widget.client.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
              DropdownMenuItem(value: PieceStyle.values.elementAt(index),
                  child: Text("Piece Style: ${PieceStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (PieceStyle? value) => setState(() {
                widget.client.setPieceStyle(value!);
              })),
          Row(
            children: [
              Text("Resolution: ${resolution?.floor() ?? widget.client.matrixResolution.floor()}",style: MatrixApp.getTextStyle(Colors.black)),
                Slider(
                  value: resolution ?? widget.client.matrixResolution as double, divisions: 9, min: 50, max: 500,
                  onChanged: (double value) => setState(() {
                    resolution = value;
                  }),
                  onChangeEnd: (double value) => widget.client.setResolution(value.floor()),
                ),
              ],
          ),
          Row(
            children: [
              Text("Intensity",style: MatrixApp.getTextStyle(Colors.black)),
              Slider(value: intensity ?? (widget.client.maxControl-6).abs() as double, divisions: 5, min: 1, max: 5,
                  onChanged: (double value) => setState(() {
                    intensity = value;
                  }),
                  onChangeEnd: (double value) => widget.client.setMaxControl((value.round() - 6).abs()),
                ),
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
            ),
            Column(
              children: List.generate(ColorStyle.values.length, (int index) =>
                  ElevatedButton(
                      onPressed: () => widget.client.setColorScheme(
                        whiteColor: ColorStyle.values.elementAt(index).colorScheme.whiteColor,
                        blackColor: ColorStyle.values.elementAt(index).colorScheme.blackColor,
                        voidColor: ColorStyle.values.elementAt(index).colorScheme.voidColor,
                      ),
                      child: Text(ColorStyle.values.elementAt(index).name)
                  )
              ),
            ),
          ],
        ));
  }
}


