import 'package:chess_matrix/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zug_chess/zug_chess.dart';
import 'client.dart';
import 'dialogs.dart';

class OptionWidget extends StatefulWidget {
  const OptionWidget({super.key});

  @override
  State<StatefulWidget> createState() => _OptionWidgetState();
}

class _OptionWidgetState extends State<OptionWidget> {
  double? resolution;
  double? intensity;
  ColorStyle? colorStyle;

  get imageQuality => (num resolution) => switch (resolution) {
    >= 500 => "Ultra",
    >= 400 => "High",
    >= 300 => "Good",
    >= 200 => "Medium",
    >= 100 => "Low",
    _ => "Crap"};

  @override
  Widget build(BuildContext context) {
    MatrixClient client = Provider.of(context, listen: false);
    return Container(color: Colors.grey, height: 500, child: Flex(direction: Axis.vertical,
        children: [
          Row(
            children: [
              Text("Show Move Arrow: ",style: MatrixApp.getTextStyle(Colors.black)),
              Checkbox(value: client.showMove, onChanged: (b) => setState(() {
                client.showMove = b ?? false;
              })),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Text("Color Presets: ",style: MatrixApp.getTextStyle(Colors.black)),
              DropdownButton(value: colorStyle, items: List.generate(ColorStyle.values.length, (index) =>
                  DropdownMenuItem(value: ColorStyle.values.elementAt(index),
                      child: Text("Color Style: ${ColorStyle.values.elementAt(index).name}",
                          style: MatrixApp.getTextStyle(Colors.black)))),
                  onChanged: (ColorStyle? style) => client.setColorScheme(scheme: style?.colorScheme)
              ),
            ],
          ),
          const SizedBox(width: 24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => MenuDialog(context, ChangeNotifierProvider.value(value: client, child: const ColorDialog())).raise(),
                child: Text("Set Colors",style: MatrixApp.getTextStyle(Colors.black)),
              ),
              ElevatedButton(
                onPressed: () => client.setColorScheme(
                  whiteControl: rndCol(),blackControl: rndCol(),voidColor: rndCol(),whiteBlend: rndCol(),blackBlend: rndCol()//,grid: rndCol()
                ),
                child: Text("Random Colors",style: MatrixApp.getTextStyle(Colors.black)),
              ),
            ],
          ),
          const Divider(height: 24),
          DropdownButton(value: client.mixStyle, items: List.generate(MixStyle.values.length, (index) =>
              DropdownMenuItem(value: MixStyle.values.elementAt(index),
                  child: Text("Mix Style: ${MixStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (MixStyle? value) => setState(() {
                client.setMixStyle(value!);
              })),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: client.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
              DropdownMenuItem(value: GameStyle.values.elementAt(index),
                  child: Text("Game Style: ${GameStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (GameStyle? value) => setState(() {
                client.setGameStyle(value!);
              })),
          const SizedBox(width: 24, height: 24),
          DropdownButton(value: client.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
              DropdownMenuItem(value: PieceStyle.values.elementAt(index),
                  child: Text("Piece Style: ${PieceStyle.values.elementAt(index).name}",
                      style: MatrixApp.getTextStyle(Colors.black)))),
              onChanged: (PieceStyle? value) => setState(() {
                client.setPieceStyle(value!);
              })),
          const Divider(height: 24),
          Row(
            children: [
              Text("Resolution: ${imageQuality(resolution ?? client.matrixResolution)}",
                  style: MatrixApp.getTextStyle(Colors.black)),
                Slider(
                  value: resolution ?? (client.matrixResolution as double), divisions: 4, min: 100, max: 500,
                  onChanged: (double value) => setState(() {
                    resolution = value;
                  }),
                  onChangeEnd: (double value) => client.setResolution(value.round()),
                ),
              ],
          ),
          Row(
            children: [
              Text("Intensity",style: MatrixApp.getTextStyle(Colors.black)),
              Slider(value: intensity ?? (client.maxControl-6).abs() as double, divisions: 5, min: 1, max: 5,
                  onChanged: (double value) => setState(() {
                    intensity = value;
                  }),
                  onChangeEnd: (double value) => client.setMaxControl((value.round() - 6).abs()),
                ),
              ],
          ),
        ],
    ));
  }
}
