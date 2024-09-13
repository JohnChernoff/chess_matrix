import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(MatrixClient("rapid",8,250,250)));
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
        body: Container(
          color: Colors.black,
          child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(client.boards.keys.length,(index) => client.boards.keys.elementAt(index)!,
              ),
        ),
    )
    );
  }
}
