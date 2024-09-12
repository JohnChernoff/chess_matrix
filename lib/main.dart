import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_widget.dart';
import 'client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(MatrixClient("bullet",250,250)));
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
    var client = context.watch<MatrixClient>();
    List<BoardWidget> boardList = client.boards.values.toList();
    boardList.sort((a,b) => a.slot - b.slot);
    print("Board List: $boardList");
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(boardList.length,(index) => boardList[index]),
        ),
    );
  }
}

Color rndCol() {
  return Colors.primaries[Random().nextInt(Colors.primaries.length)];
}

