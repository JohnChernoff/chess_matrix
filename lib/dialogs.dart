import 'dart:async';

import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zug_utils/zug_utils.dart';
import 'board_state.dart';
import 'client.dart';
import 'img_utils.dart';
import 'main.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

class MenuDialog {
  final BuildContext ctx;
  final Widget menuWidget;

  MenuDialog(this.ctx, this.menuWidget);

  Future<void> raise() {
    return showDialog<void>(
        context: ctx,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey,
            content: menuWidget,
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Return'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}

class ColorDialog extends StatelessWidget {
  const ColorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    MatrixClient client = context.watch<MatrixClient>();
    final dims = ZugUtils.getScreenDimensions(context); //Axis axis = dims.getMainAxis();
    return Container(
        color: Colors.brown,
        width: dims.width /2,
        height: dims.height / 3,
        child: GridView.extent(
          scrollDirection: Axis.vertical, //axis,
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          padding: const EdgeInsets.all(8.0),
          children: [
            getColorPicker(client, "White Control ", client.colorScheme.whiteColor, (color) => client.setColorScheme(whiteControl: color)),
            getColorPicker(client, "Black Control ", client.colorScheme.blackColor, (color) => client.setColorScheme(blackControl: color)),
            getColorPicker(client, "Void: ", client.colorScheme.voidColor, (color) => client.setColorScheme(voidColor: color)),
            getColorPicker(client, "Grid: ", client.colorScheme.gridColor, (color) => client.setColorScheme(grid: color)),
            getColorPicker(client, "White Blend ", client.colorScheme.whitePieceBlendColor, (color) => client.setColorScheme(whiteBlend: color)),
            getColorPicker(client, "Black Blend ", client.colorScheme.blackPieceBlendColor, (color) => client.setColorScheme(blackBlend: color)),
          ],
        ));
  }

  Widget getColorPicker(MatrixClient client, String title, Color colorProvider, dynamic onSelect) {
    return Column(
      children: [
        Text(title, style: MatrixApp.getTextStyle(colorProvider)),
        ColorButton(
          size: 100,
          boxShape: BoxShape.rectangle,
          color: colorProvider,
          onColorChanged: (Color color) => onSelect(color),
          config: const ColorPickerConfig(enableLibrary: false, enableEyePicker: false),
          darkMode: true,
        ),
      ],
    );
  }
}

class GifDialog {
  final BuildContext ctx;
  final MatrixClient client;
  final BoardState state;

  const GifDialog(this.ctx,this.client,this.state);

  Future<void> raise() {
    return showDialog<void>(
        context: ctx,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                  onPressed: () {
                    ImgUtils.createGifFile(state, 500, ctx: context);
                    Navigator.pop(context);
                  },
                  child: const Text('Create GIF (could take awhile)')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel')),
            ],
          );
        });
  }
}

class ChallengeDialog {
  final BuildContext ctx;
  final MatrixClient client;
  final int seconds, inc;
  final bool rated;

  const ChallengeDialog(this.ctx, this.client, this.seconds, this.inc, this.rated);

  Future<bool?> raise() {
    return showDialog<bool>(
        context: ctx,
        builder: (BuildContext context) {
          String? player;
          return AlertDialog(
            title: Text("Challenge to ${seconds/60} : $inc ${rated ? '' : 'un'}rated"),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return SizedBox(height: 480, child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      icon: Icon(Icons.person), //hintText: 'player to challenge',
                      labelText: 'Player',
                    ),
                    onChanged: (String? value) {
                      setState(() => player = value);
                    },
                  ),
                  SimpleDialogOption(
                      onPressed: () {
                        if (player != null) {
                          client.createChallenge(player!,seconds,inc,false);
                          Navigator.pop(context,true);
                        }
                      },
                      child: const Text('Create Challenge')),
                  SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context,false);
                      },
                      child: const Text('Cancel')),
                ],
              ));
            }),
          );
        });
  }
}

class InfoDialog {
  final BuildContext ctx;
  final String msg;

  InfoDialog(this.ctx, this.msg);

  Future<void> raise() {
    return showDialog<void>(
        context: ctx,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              Text(msg),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK')),
            ],
          );
        });
  }
}
