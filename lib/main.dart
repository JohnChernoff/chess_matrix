import 'dart:math';
import 'dart:ui';
import 'package:chess_matrix/board_widget.dart';
import 'package:chess_matrix/chess_sonifier.dart';
import 'package:chess_matrix/options.dart';
import 'package:chess_matrix/tests.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zug_utils/zug_utils.dart';
import 'client.dart';
import 'game_seek.dart';
import 'help_widget.dart';
import 'matrix_fields.dart';
import 'board_state.dart';
import 'midi_manager.dart';

/*

You can make blueprint of single game (cumulative board control)

TODO:
 piece motion animation
 settings cookies
 game chat, etc.
 selectable keys,
 animate sounds,
 ~board reloading weirdness,
 distance v. square pitches
 optimize board drawing and minimum resolution
  ~lichess ping,
 */

bool testing = false;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MatrixApp());
}

class MatrixApp extends StatelessWidget {

  static double fontSize = 20;
  static TextStyle getTextStyle(Color color) {
    return TextStyle(color: color, fontSize: fontSize);
  }

  const MatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MatrixClient("lichess.org"),
        child: MaterialApp(
            title: 'Chess Matrix 1.0',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            scrollBehavior: WebScrollBehavior(),
            home: const MatrixHomePage('Chess Matrix')));
  }

  static Future<void> menuBuilder(BuildContext context,Widget menuWidget) {
    return showDialog<void>(
        context: context,
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

class MatrixHomePage extends StatefulWidget {
  final String title;
  const MatrixHomePage(this.title,{super.key});

  @override
  State<StatefulWidget> createState() => _MatrixHomePageState();

}

class _MatrixHomePageState extends State<MatrixHomePage> {
  Color color1 = Colors.grey;
  Color color2 = Colors.white;
  Color color3 = Colors.black; //Colors.purple;
  int? newNumBoards;

  @override
  void initState() {
    super.initState();
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
            client.sonifier.midi.audioReady ? getAudioControls(client) : const SizedBox.shrink(),
            client.sonifier.midi.audioReady ? const SizedBox(height: 32) : const SizedBox.shrink(),
            Expanded(child: getMatrixView(client),
            )
          ]));
        })
    );
  }

  Widget getMatrixView(MatrixClient client, {double minBoardSize = 320}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double w = constraints.constrainWidth();
        double h = constraints.constrainHeight();
        int numBoards = client.activeBoards.length;
        double maxSize = max(ZugUtils.getMaxSizeOfSquaresInRect(w, h, numBoards) - 32, minBoardSize); //print("Max Size: $maxSize");
        int horizontalBoards = (w / maxSize).floor();
        int verticalBoards = (numBoards / horizontalBoards).ceil(); //may scroll down
        return Container(
          color: Colors.black,
          width: w,
          height: h,
          child: client.seeking ? Text("Seeking...",style: MatrixApp.getTextStyle(Colors.white)) :
          SingleChildScrollView(scrollDirection: Axis.vertical, child: Column(
            children: List.generate(verticalBoards, (row) {
              return Column(children: [
                Row(
                  mainAxisAlignment : MainAxisAlignment.center,
                  children: List.generate(horizontalBoards, (i) {
                    int index = (row * horizontalBoards) + i; //print("Index: $index");
                    if (index < numBoards) { //there's probably something more elegant than this
                      BoardState? state = client.activeBoards.elementAt(index); //print("Viewing: $state");
                      state.boardSize = maxSize.floor();
                      return ChangeNotifierProvider.value(
                          value: state,
                          child: SizedBox(width: maxSize, height: maxSize, child: BoardWidget(key: ObjectKey(state),index,maxSize,client)));
                    }
                    else {
                      return const SizedBox.shrink();
                    }
                  }),
                ),
                ((row * verticalBoards) < numBoards) ? const Divider(height: 20) : const SizedBox.shrink(),
              ]);
            }),
          )),
        );
      },
    );
  }

  Widget getGeneralControls(MatrixClient client) {
    int numBoards = (newNumBoards ?? client.viewBoards.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: constraints.copyWith(
              minWidth: constraints.maxWidth,
              maxWidth: double.infinity,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.shrink(), // Nothing to left-align
                Row( // Center-aligned widget (with multiple children)
                  children: [
                    IconButton(onPressed: () => MatrixApp.menuBuilder(context,const HelpWidget()), icon: const Icon(Icons.help)),
                    client.lichessToken == null ? IconButton(onPressed: () => client.lichessLogin(), icon: const Icon(Icons.login))
                        : Text(client.userInfo['username'],style: MatrixApp.getTextStyle(Colors.white)),
                    client.lichessToken == null ? const SizedBox.shrink() : client.playBoards.isEmpty && client.seeking ?
                    IconButton(onPressed: () => client.cancelSeek(), icon: const Icon(Icons.cancel)) :
                    IconButton(onPressed: () => MatrixApp.menuBuilder(context,SeekWidget(client)), icon: const Icon(Icons.send)),
                    IconButton(onPressed: () => MatrixApp.menuBuilder(context,
                        ChangeNotifierProvider.value(value: client,child: const OptionWidget())),
                        icon: const Icon(Icons.menu)),
                    Text("Boards: $numBoards",style: MatrixApp.getTextStyle(color2)),
                    Slider(value: numBoards as double, min: 1, max: 16,
                      onChanged: (double value) => setState(() { newNumBoards = value.floor(); }),
                      onChangeEnd: (double value) {
                        newNumBoards = null; client.loadTVGames(numBoards: value.floor()-1);
                      },
                    ),
                  ],
                ),
                Row( // Right-aligned widget (with multiple children)
                  children: [
                    IconButton(
                        onPressed: () => client.sonifier.toggleAudio(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        icon: Icon(client.sonifier.midi.muted ? Icons.audiotrack : Icons.volume_mute)),
                    const SizedBox(width: 20),
                    client.sonifier.midi.audioReady ? ElevatedButton(onPressed: () => client.sonifier.loadRandomEnsemble(),
                        child: Text("Randomize",style: MatrixApp.getTextStyle(color3))) : const SizedBox.shrink(),
                    const SizedBox(width: 20),
                    client.sonifier.midi.audioReady ? ElevatedButton(onPressed: () => client.sonifier.toggleDrums(),
                        child: Text("Toggle Drums",style: client.sonifier.midi.muteDrums ? MatrixApp.getTextStyle(color2) : MatrixApp.getTextStyle(color3)))
                        : const SizedBox.shrink(),
                    const SizedBox(width: 20),
                    client.sonifier.midi.audioReady ? ElevatedButton(onPressed: () => client.sonifier.keyChange(),
                        child: Text("New Key",style:MatrixApp.getTextStyle(color3)))
                        : const SizedBox.shrink(),
                    const SizedBox(width: 20),
                    testing ? ElevatedButton(onPressed: () => MatrixTest().rhythmTest(client), child: Text("Test",style: MatrixApp.getTextStyle(color3))) : const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getAudioControls(MatrixClient client) {
    return Center(child: SizedBox(height: 120, child:
    ListView(scrollDirection: Axis.horizontal, shrinkWrap: true,
        children: List.generate(MidiChessPlayer.values.length, (i) {
          MidiChessPlayer track = MidiChessPlayer.values.elementAt(i);
          Instrument? instrument = client.sonifier.midi.orchMap[track.name];
          return instrument != null ? Container(
              color: client.sonifier.midi.muted ? Colors.brown : MidiChessPlayer.values.elementAt(i).color,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: const BeveledRectangleBorder()),
                      onPressed: () => setState(() {
                        client.sonifier.midi.toggleSolo(instrument);
                      }),
                      child: Text("solo",style: TextStyle(backgroundColor: Colors.black, color: instrument.solo ? Colors.amberAccent : Colors.cyan))
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: const BeveledRectangleBorder()),
                      onPressed: () => setState(() {
                        client.sonifier.midi.toggleMute(instrument);
                      }),
                      child: Text("mute",style:TextStyle(backgroundColor: Colors.black, color: instrument.mute ? Colors.amberAccent : Colors.cyan))
                  ),
                ]
                ),
                Text(MidiChessPlayer.values.elementAt(i).name),
                DropdownButton<MidiInstrument>(value: client.sonifier.midi.orchMap[MidiChessPlayer.values.elementAt(i).name]?.iPatch, alignment: AlignmentDirectional.center,
                    items: List.generate(MidiInstrument.values.length, (index) {
                      MidiInstrument patch = MidiInstrument.values.elementAt(index);
                      return DropdownMenuItem(
                          alignment: AlignmentDirectional.center,
                          value: patch,
                          child: Text(patch.name));
                    }), onChanged: (value) => client.sonifier.loadInstrument(track.name,value!)) ,
              ],
              )) : const SizedBox.shrink();
        })
    )));
  }

}

class WebScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

Color rndCol() {
  return Colors.primaries[Random().nextInt(Colors.primaries.length)];
}
