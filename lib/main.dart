import 'dart:ui';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chess_matrix/board_sonifier.dart';
import 'package:chess_matrix/board_widget.dart';
import 'package:chess_matrix/tests.dart';
import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zug_utils/zug_utils.dart';
import 'client.dart';
import 'matrix_fields.dart';
import 'board_state.dart';

//TODO: lichess ping, pixel depth, color combinations, key changes

bool testing = false;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MatrixApp());
}

class MatrixApp extends StatelessWidget {

  const MatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MatrixClient('wss://socket.lichess.org/api/socket'),
        child: MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            scrollBehavior: WebScrollBehavior(),
            home: const MatrixHomePage('Chess Matrix')));
  }
}

class MatrixHomePage extends StatefulWidget {
  final String title;
  const MatrixHomePage(this.title,{super.key});

  @override
  State<StatefulWidget> createState() => _MatrixHomePageState();

}

class _MatrixHomePageState extends State<MatrixHomePage> {
  double fontSize = 20;
  Color color1 = Colors.grey;
  Color color2 = Colors.white;
  Color color3 = Colors.black; //Colors.purple;
  int numBoards = 8;

  @override
  void initState() {
    super.initState();
  }

  TextStyle getTextStyle(Color color) {
    return TextStyle(color: color, fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    MatrixClient client = context.watch<MatrixClient>(); //print("Building Board List: ${client.boards.keys}");

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          return Container(color: Colors.black, child: Column(children: [
            SizedBox(width: constraints.maxWidth, height: 40, child: getGeneralControls(client)),
            const SizedBox(height: 32),
            client.sonifier.audioReady ? getAudioControls(client) : const SizedBox.shrink(),
            client.sonifier.audioReady ? const SizedBox(height: 32) : const SizedBox.shrink(),
            Container(color: Colors.black, width: constraints.maxWidth, height: 40, child: Center(child: getMatrixMenus(client))),
            const SizedBox(height: 32),
            Expanded(child: getMatrixView(client),
            )
          ]));
        })
    );
  }

  Widget getMatrixView(MatrixClient client, {int minBoardSize = 200}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double maxSize = ZugUtils.getMaxSizeOfSquaresInRect(client.boards.length + 1, constraints.maxWidth, constraints.maxHeight);
        int horizonalBoards = (constraints.maxWidth / maxSize).floor();
        return Container(
          color: Colors.black,
          child: GridView.count(
            crossAxisCount: horizonalBoards,
            mainAxisSpacing: 16,
            crossAxisSpacing: 0,
            children: List.generate(
              client.boards.length, (index) {
              BoardState? state = client.boards.elementAt(
                  index); //print("Viewing: $state");
              return ChangeNotifierProvider.value(
                  value: state,
                  child: BoardWidget(key: ObjectKey(state), index));
            },
            ),
          ),
        );
      },
    );
  }

  Widget getGeneralControls(MatrixClient client) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
      children: [
        Text("Boards: $numBoards",style: getTextStyle(color2)),
        Slider(value: numBoards as double, min: 1, max: 30,
            onChanged: (double value) {
              setState(() {
                numBoards = value.round();
              });
            }),
        Text("Intensity",style: getTextStyle(color2)),
        Slider(value: (client.maxControl-6).abs() as double, min: 1, max: 5,
            onChanged: (double value) {
              client.setMaxControl((value.round() - 6).abs());
            }),
        ElevatedButton(onPressed: () => client.loadTVGames(numBoards: numBoards-1, reset: false), child: Text("Reload", style: getTextStyle(color3))),
        const SizedBox(width: 20),
        ElevatedButton(
            onPressed: () => client.toggleAudio(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text("Toggle Audio (currently: ${client.sonifier.muted ? 'off' : 'on'})",style: getTextStyle(color3))),
        const SizedBox(width: 20),
        client.sonifier.audioReady ? ElevatedButton(onPressed: () => client.loadRandomEnsemble(),
            child: Text("Randomize",style: getTextStyle(color3))) : const SizedBox.shrink(),
        const SizedBox(width: 20),
        client.sonifier.audioReady ? ElevatedButton(onPressed: () => client.toggleDrums(),
            child: Text("Toggle Drums",style: client.sonifier.muteDrums ? getTextStyle(color2) : getTextStyle(color3))) : const SizedBox.shrink(),
        const SizedBox(width: 20),
        testing ? ElevatedButton(onPressed: () => MatrixTest().rhythmTest(client), child: Text("Test",style: getTextStyle(color3))) : const SizedBox.shrink(),
      ],
    ));
  }

  Widget getAudioControls(MatrixClient client) {
    return Center(child: SizedBox(height: 120, child:
    ListView(scrollDirection: Axis.horizontal, shrinkWrap: true,
        children: List.generate(InstrumentType.values.length, (i) {
          InstrumentType track = InstrumentType.values.elementAt(i);
          Instrument? instrument = client.sonifier.orchMap[track];
          return instrument != null ? Container(
              color: client.sonifier.muted ? Colors.brown : InstrumentType.values.elementAt(i).color,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: const BeveledRectangleBorder()),
                      onPressed: () => client.sonifier.toggleSolo(instrument),
                      child: Text("solo",style: TextStyle(backgroundColor: Colors.black, color: instrument.solo ? Colors.amberAccent : Colors.cyan))
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: const BeveledRectangleBorder()),
                      onPressed: () => client.sonifier.toggleMute(instrument),
                      child: Text("mute",style:TextStyle(backgroundColor: Colors.black, color: instrument.mute ? Colors.amberAccent : Colors.cyan))
                  ),
                ]
                ),
                Text(InstrumentType.values.elementAt(i).name),
                DropdownButton(value: client.sonifier.orchMap[InstrumentType.values.elementAt(i)]?.iPatch, alignment: AlignmentDirectional.center,
                    items: List.generate(MidiInstrument.values.length, (index) {
                      MidiInstrument patch = MidiInstrument.values.elementAt(index);
                      return DropdownMenuItem(
                          alignment: AlignmentDirectional.center,
                          value: patch,
                          child: Text(patch.name));
                    }), onChanged: (value) => client.loadInstrument(track,value!)) ,
              ],
              )) : const SizedBox.shrink();
        })
    )));
  }

  Widget getMatrixMenus(MatrixClient client) {
    Decoration decoration = BoxDecoration(
      color: Colors.greenAccent,
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [client.colorScheme.whiteColor,client.colorScheme.blackColor],
      ), //borderRadius: BorderRadius.all(Radius.circular(40)),
    );
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(decoration: decoration, child:
            DropdownButton(value: MatrixClient.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
                DropdownMenuItem(value: GameStyle.values.elementAt(index), child: Text("Game Style: ${GameStyle.values.elementAt(index).name}",style: getTextStyle(Colors.black)))),
                onChanged: (GameStyle? value) => client.setGameStyle(value!))),
            const SizedBox(width: 24),
            ElevatedButton(onPressed: () => getColorDialog(client), child: Text("Colors",style: getTextStyle(color3))),
            const SizedBox(width: 24),
            DecoratedBox(decoration: decoration, child: DropdownButton(value: MatrixClient.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
                DropdownMenuItem(value: PieceStyle.values.elementAt(index), child: Text("Piece Style: ${PieceStyle.values.elementAt(index).name}",style: getTextStyle(Colors.black)))),
                onChanged: (PieceStyle? value) => client.setPieceStyle(value!))),
          ]),
    );
  }

  void getColorDialog(MatrixClient client) {
    AwesomeDialog(
      context: context,
      body: Container(color: Colors.green, child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text("White Color: ",style: getTextStyle(Colors.white)),
              ColorPicker(onColorSelected: (Color color) {
                client.setColorScheme(whiteColor: color);
              },
                selectedColor: client.colorScheme.whiteColor,
                config: const ColorPickerConfig(),
                onClose: () {},
              ),
            ],
          ),
          Column(
            children: [
              Text("Black Color: ",style: getTextStyle(Colors.black)),
              ColorPicker(onColorSelected: (Color color) {
                client.setColorScheme(blackColor: color);
              },
                selectedColor: client.colorScheme.blackColor,
                config: const ColorPickerConfig(),
                onClose: () {},
              ),
            ],
          ),
          Column(
            children: [
              Text("Void Color: ",style: getTextStyle(Colors.black)),
              ColorPicker(onColorSelected: (Color color) {
                client.setColorScheme(voidColor: color);
              },
                selectedColor: client.colorScheme.voidColor,
                config: const ColorPickerConfig(),
                onClose: () {},
              ),
            ],
          )
        ],
      )),
      dialogType: DialogType.info,
      borderSide: const BorderSide(
        color: Colors.green,
        width: 2,
      ),
      //width: 280,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: false,
      onDismissCallback: (type) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dismissed by $type'),
          ),

        );
      },
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: 'COLOR MENU',
      desc: 'This Dialog can be dismissed touching outside',
      showCloseIcon: true,
      btnCancelOnPress: () {},
      btnOkOnPress: () {},
    ).show();
  }

}

//class MatrixColorDialog extends St

class WebScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
