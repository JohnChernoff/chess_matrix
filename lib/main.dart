import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client.dart';
import 'home_page.dart';

/*

You can make blueprint of single game (cumulative board control)

TODO:
 piece motion animation
 settings cookies
 selectable keys,
 animate sounds,
 distance v. square pitches
 game chat, etc.
 ~board reloading weirdness,
 ~optimize board drawing and minimum resolution
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
