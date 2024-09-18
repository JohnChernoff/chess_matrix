import 'dart:math';
import 'dart:ui';
import 'package:chess_matrix/board_sonifier.dart';
import 'package:chess_matrix/board_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zug_utils/zug_utils.dart';
import 'client.dart';
import 'matrix_fields.dart';
import 'board_state.dart';

enum MediaBreakpoint {mobile,tablet,laptop,desktop}
Map<MediaBreakpoint,List<int>> gridMap = {
  MediaBreakpoint.mobile: [1,1,2,2],
  MediaBreakpoint.tablet: [2,2,4,4],
  MediaBreakpoint.laptop: [3,3,4,6],
  MediaBreakpoint.desktop: [4,4,6,8]
};
Map<ColorStyle,List<Color>> colorStyleList = {
  ColorStyle.redBlue : [Colors.red,Colors.blue],
  ColorStyle.redGreen : [Colors.red,Colors.green],
  ColorStyle.greenBlue : [Colors.green,Colors.blue],
};

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
    ScreenDim dim = ZugUtils.getScreenDimensions(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Container(color: Colors.black, child: Column(children: [
          SizedBox(width: dim.width, height: 40, child: getGeneralControls(client)),
          const SizedBox(height: 32),
          client.sonifier.audioReady ? getAudioControls(client) : const SizedBox.shrink(),
          Container(color: Colors.black, width: dim.width, height: 40, child: Center(child: getMatrixControls(client))),
          const SizedBox(height: 32),
          Expanded(child: getMatrixView(client,dim),
          )
        ]))
    );
  }

  Widget getMatrixView(MatrixClient client, ScreenDim screenDimensions, {int minBoardSize = 200}) {
    int i = max(min(3, ((client.boards.length / 4) - 1).floor()),0);
    int horizonalBoards = 1;
    int n = client.boards.length + 1;
    for (int i=n; i>0; i--) {
      if (min(screenDimensions.width / i,screenDimensions.height / i).floor() > minBoardSize) {
        horizonalBoards = i;
        break;
      }
    }
    return Container(
      color: Colors.black,
      child: GridView.count(
        crossAxisCount: horizonalBoards,
        mainAxisSpacing: 16,
        crossAxisSpacing: 0,
        children: List.generate(
          client.boards.length, (index) {
            BoardState? state = client.boards.elementAt(index); //print("Viewing: $state");
            return ChangeNotifierProvider.value(
                value: state, child: BoardWidget(key: ObjectKey(state), index));
          },
        ),
      ),
    );
  }

  Widget getGeneralControls(MatrixClient client) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
      children: [
        Text("Boards: $numBoards",style: getTextStyle(color2)),
        Slider(
            value: numBoards as double,
            min: 1,
            max: 30,
            onChanged: (double value) {
              setState(() {
                numBoards = value.round();
              });
            }),
        ElevatedButton(onPressed: () => client.loadTVGames(numBoards: numBoards-1, reset: false), child: Text("Reload", style: getTextStyle(color3))),
        const SizedBox(width: 20),
        ElevatedButton(
            onPressed: () => client.toggleAudio(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text("Toggle Audio (currently: ${client.sonifier.muted ? 'off' : 'on'})",style: getTextStyle(color3))),
      ],
    ));
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
    Decoration decoration = BoxDecoration(
      color: Colors.greenAccent,
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: colorStyleList[MatrixClient.colorStyle] ?? [],
      ), //borderRadius: BorderRadius.all(Radius.circular(40)),
    );
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(decoration: decoration, child:
            DropdownButton(value: MatrixClient.colorStyle, items: List.generate(ColorStyle.values.length, (index) =>
                DropdownMenuItem(value: ColorStyle.values.elementAt(index), child: Text("Color Style: ${ColorStyle.values.elementAt(index).name}",style: getTextStyle(Colors.black)))),
                onChanged: (ColorStyle? value) => client.setColorStyle(value!))),
            const SizedBox(width: 24),
            DecoratedBox(decoration: decoration, child:
            DropdownButton(value: MatrixClient.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
                DropdownMenuItem(value: GameStyle.values.elementAt(index), child: Text("Game Style: ${GameStyle.values.elementAt(index).name}",style: getTextStyle(Colors.black)))),
                onChanged: (GameStyle? value) => client.setGameStyle(value!))),
            const SizedBox(width: 24),
            DecoratedBox(decoration: decoration, child: DropdownButton(value: MatrixClient.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
                DropdownMenuItem(value: PieceStyle.values.elementAt(index), child: Text("Piece Style: ${PieceStyle.values.elementAt(index).name}",style: getTextStyle(Colors.black)))),
                onChanged: (PieceStyle? value) => client.setPieceStyle(value!))),
          ]),
    );
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
