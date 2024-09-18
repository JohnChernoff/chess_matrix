import 'dart:ui';
import 'package:chess_matrix/board_sonifier.dart';
import 'package:chess_matrix/board_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client.dart';
import 'matrix_fields.dart';
import 'board_state.dart';

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
  TextStyle textStyle = const TextStyle(color: Colors.grey, fontSize: 20); //deepPurpleAccent
  TextStyle buttonTextStyle = const TextStyle(color: Colors.purple, fontSize: 20); //deepPurpleAccent
  int numBoards = 8;

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
        body: Container(color: Colors.black, child: Column(children: [
          Row(
            children: [
              Text("Boards: $numBoards",style: textStyle),
              Slider(
                  value: numBoards as double,
                  min: 1,
                  max: 30,
                  label: "Boards",
                  onChanged: (double value) {
                    setState(() {
                      numBoards = value.round();
                    });
                  }),
              ElevatedButton(onPressed: () => client.loadTVGames(numBoards: numBoards, reset: false), child: Text("Reload", style: buttonTextStyle)),
              const SizedBox(width: 20),
              ElevatedButton(
                  onPressed: () => client.toggleAudio(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text("Toggle Audio (currently: ${client.sonifier.muted ? 'off' : 'on'})",style: buttonTextStyle)),
            ],
          ),
          //const SizedBox(height: 32),

          const SizedBox(height: 32),
          client.sonifier.audioReady ? getAudioControls(client) : const SizedBox.shrink(),
          getMatrixControls(client),
          const SizedBox(height: 32),
          Expanded(child: getMatrixView(client),
          )
        ]))
    );
  }

  Widget getMatrixView(MatrixClient client) {
    return Container(
      color: Colors.black,
      child: GridView.count(
        crossAxisCount: 4, //TODO: adjust for mobile
        mainAxisSpacing: 16,
        crossAxisSpacing: 0,
        children: List.generate(client.boards.length,(index) {
          BoardState? state = client.boards.elementAt(index); //print("Viewing: $state");
          return ChangeNotifierProvider.value(value: state,
              child: BoardWidget(key: ObjectKey(state), index));
        },
        ),
      ),
    );
  }

  Widget getAudioControls(MatrixClient client) {
    return Center(child: SizedBox(height: 120, child:
    ListView(scrollDirection: Axis.horizontal, shrinkWrap: true,
        children: List.generate(InstrumentType.values.length, (i) {
          InstrumentType track = InstrumentType.values.elementAt(i);
          Instrument? instrument = client.sonifier.orchMap[track.name];
          return instrument != null ? Container(
              color: client.sonifier.muted ? Colors.brown : InstrumentType.values.elementAt(i).color,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: const BeveledRectangleBorder()),
                      onPressed: () => client.sonifier.toggleSolo(track),
                      child: Text("solo",style: TextStyle(backgroundColor: Colors.black, color: instrument.solo ? Colors.amberAccent : Colors.cyan))
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, shape: const BeveledRectangleBorder()),
                      onPressed: () => client.sonifier.toggleMute(track),
                      child: Text("mute",style:TextStyle(backgroundColor: Colors.black, color: instrument.mute ? Colors.amberAccent : Colors.cyan))
                  ),
                ]
                ),
                Text(InstrumentType.values.elementAt(i).name),
                DropdownButton(value: client.sonifier.orchMap[InstrumentType.values.elementAt(i).name]?.patch, alignment: AlignmentDirectional.center,
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

  Widget getMatrixControls(MatrixClient client) {
    return Column(children: [

      Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            DropdownButton(value: MatrixClient.colorStyle, items: List.generate(ColorStyle.values.length, (index) =>
                DropdownMenuItem(value: ColorStyle.values.elementAt(index), child: Text("Color Style: ${ColorStyle.values.elementAt(index).name}",style: textStyle))),
                onChanged: (ColorStyle? value) => client.setColorStyle(value!)),
            DropdownButton(value: MatrixClient.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
                DropdownMenuItem(value: GameStyle.values.elementAt(index), child: Text("Game Style: ${GameStyle.values.elementAt(index).name}",style: textStyle))),
                onChanged: (GameStyle? value) => client.setGameStyle(value!)),
            DropdownButton(value: MatrixClient.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
                DropdownMenuItem(value: PieceStyle.values.elementAt(index), child: Text("Piece Style: ${PieceStyle.values.elementAt(index).name}",style: textStyle))),
                onChanged: (PieceStyle? value) => client.setPieceStyle(value!)),
          ]),
    ]);

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
