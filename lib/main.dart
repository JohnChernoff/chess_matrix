import 'dart:math';
import 'dart:ui';
import 'package:chess_matrix/tests/tests.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'client.dart';
import 'dialogs.dart';
import 'home_page.dart';

/*
TODO:
 cluechess 2.0?
 last move move list bug
 version history/auto browser refresh?
 settings cookies,
 selectable keys,
 piece motion animation,
 animate sounds,
 distance v. square pitches
 game chat, etc.
  ~reconnection
  ~gameover notification/indication
  ~GIF generation
  ~logging
 ~board reloading weirdness,
 ~optimize board drawing and minimum resolution
  ~lichess ping,
  ?music/chess libraries
 */

var mainLogger = Logger(
  printer: PrettyPrinter(),
);

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  if (const String.fromEnvironment("GIFTEST") == "true") {
    MatrixTests.gifTest();
  }
  else {
    runApp(const MatrixApp());
  }
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
        create: (context) => MatrixClient("lichess.org",token: const String.fromEnvironment("TOKEN")),
        child: MaterialApp(
            navigatorKey: globalNavigatorKey,
            title: 'Chess Matrix 1.0',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            scrollBehavior: WebScrollBehavior(),
            home: const LoaderOverlay(child: MatrixHomePage('Chess Matrix'))));
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
