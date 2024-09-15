import 'package:chess_matrix/board_sonifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client.dart';
import 'matrix_fields.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(MatrixClient(8,250,250)));
}

class MyApp extends StatelessWidget {
  final MatrixClient client;
  const MyApp(this.client,{super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => client,
        child: MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const MyHomePage('Chess Matrix')));
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage(this.title,{super.key});

  @override
  Widget build(BuildContext context) {  print("Building...");
    MatrixClient client = context.watch<MatrixClient>();
    print("Board List: ${client.boards.keys}");
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: Column(
          children: [
            TextButton(onPressed: () => client.initAudio(), child: const Text("Audio")),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(InstrumentType.values.length, (i) => DropdownButton(value: client.sonifier.orchMap[InstrumentType.values.elementAt(i).name],
                items: List.generate(MidiInstrument.values.length, (index) => DropdownMenuItem(value: MidiInstrument.values.elementAt(index),child: Text(MidiInstrument.values.elementAt(index).name))),
                onChanged: (value) => client.loadInstrument(InstrumentType.values.elementAt(i),value!)))
            ),
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
                children: [
              DropdownButton(value: client.colorStyle, items: List.generate(ColorStyle.values.length, (index) =>
                  DropdownMenuItem(value: ColorStyle.values.elementAt(index), child: Text(ColorStyle.values.elementAt(index).name))),
                  onChanged: (ColorStyle? value) => client.setColorStyle(value!)),
              DropdownButton(value: client.gameStyle, items: List.generate(GameStyle.values.length, (index) =>
                  DropdownMenuItem(value: GameStyle.values.elementAt(index), child: Text(GameStyle.values.elementAt(index).name))),
                  onChanged: (GameStyle? value) => client.setGameStyle(value!)),
              DropdownButton(value: client.pieceStyle, items: List.generate(PieceStyle.values.length, (index) =>
                DropdownMenuItem(value: PieceStyle.values.elementAt(index), child: Text(PieceStyle.values.elementAt(index).name))),
                onChanged: (PieceStyle? value) => client.setPieceStyle(value!)),
            ]),
            Expanded(child: Container(
              color: Colors.black,
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 0,
                children: List.generate(client.boards.keys.length,(index) => client.boards.keys.elementAt(index)!,
                ),
              ),
            ))
        ],)
    );
  }

}
