import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:chess_matrix/board_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'board_matrix.dart';

enum PieceStyle  {
  cburnett,
  merida,
  pirouetti,
  chessnut,
  chess7,
  alpha,
  reillycraig,
  companion,
  riohacha,
  kosal,
  leipzig,
  fantasy,
  spatial,
  celtic,
  california,
  caliente,
  pixel,
  maestro,
  fresca,
  cardinal,
  gioco,
  tatiana,
  staunty,
  governor,
  dubrovny,
  icpieces,
  libra,
  mpchess,
  shapes,
  kiwenSuwi,
  horsey,
  anarcandy,
  letter,
  disguised,
  symmetric;
}

enum GameStyle {
  bullet,blitz,rapid,classical
}

enum ColorStyle {
  redBlue,redGreen,greenBlue
}

class MatrixClient extends ChangeNotifier {
  final int maxStreams;
  final int width, height;
  final Map<BoardWidget?,BoardState?> boards = {};
  final Map<BoardWidget,dynamic> updaters = {};
  final Map<String,ui.Image> pieceImages = {};
  bool showControl = false;
  bool showMove = false;
  PieceStyle pieceStyle = PieceStyle.horsey;
  GameStyle gameStyle = GameStyle.blitz;
  ColorStyle colorStyle = ColorStyle.redBlue;
  Color blackPieceColor = const Color.fromARGB(255, 22, 108, 0);
  late ZugSock lichSock;

  MatrixClient(this.maxStreams,this.width,this.height) {
    for (int i = 0; i < maxStreams; i++) {
      boards.putIfAbsent(BoardWidget(this,i), () => null);
    }
    lichSock = ZugSock('wss://socket.lichess.org/api/socket', connected, handleMsg, disconnected);
  }

  void setColorStyle(ColorStyle style) {
    colorStyle = style;
    notifyListeners(); //TODO: call each updater
  }

  void setPieceStyle(PieceStyle style) {
    pieceStyle = style;
    notifyListeners();
  }

  void setGameStyle(GameStyle style) {
    gameStyle = style;
    for (var state in boards.values) {
      state?.finished = true;
    }
    loadTVGames();
  }

  void connected() {
    print("Connected");
    loadTVGames();
  }

  void handleMsg(String msg) { //print("Message: $msg");
    dynamic json = jsonDecode(msg);
    String type = json['t'];
    dynamic data = json['d'];
    String id = data['id'] ?? "";
    if (type == "fen") {
      int whiteClock = int.parse(data['wc'].toString());
      int blackClock = int.parse(data['bc'].toString());
      String lastMove = data['lm'];
      String fen = data['fen'];
      BoardWidget? w = getWidgetByID(id);
      if (w != null) {
        updaters[w](fen,lastMove,whiteClock,blackClock);
      }
    } else if (type == 'finish') {
      getBoardStateByID(id)?.finished = true;
      loadTVGames();
    }

  }

  void disconnected() {
    print("Disconnected");
  }

  void loadTVGames() async {
    List<dynamic> games = await Lichess.getTV(gameStyle.name);
    for (int i = 0; i < min(maxStreams,games.length); i++) {
      addBoard(games[i]);
    } //print(boards.keys);
    notifyListeners();
  }

  BoardWidget? getWidgetByID(String id) {
    return boards.keys.firstWhere((widget) => boards[widget]?.id == id, orElse: () => null);
  }

  BoardState? getBoardStateByID(String id) {
    return boards.values.firstWhere((state) => state?.id == id, orElse: () => null);
  }

  BoardWidget? getOpenBoard() {
    for (BoardWidget? widget in boards.keys) {
      if (boards[widget]?.finished ?? true) return widget;
    }
    return null;
  }

  void addBoard(dynamic game) {
    String id = game['id'];
    Player whitePlayer = Player(game['players']['white']);
    Player blackPlayer = Player(game['players']['black']);
    if (getBoardStateByID(id) == null) {
      BoardWidget? widget = getOpenBoard();
      if (widget != null) { //print("Adding: $game");
        boards.update(widget, (state) => BoardState(id,whitePlayer,blackPlayer));
        lichSock.send(
            jsonEncode({ 't': 'startWatching', 'd': id })
        );
      }
    }
  }
}

class Player {
  final String name;
  final int rating;
  int clock = 0;

  Player(dynamic data) : name = data['user']['name'], rating = int.parse(data['rating'].toString());

  void nextTick() {
    if (clock > 0) clock--;
  }

  String _formattedTime(int seconds) {
    final int hour = (seconds / 3600).floor();
    final int minute = ((seconds / 3600 - hour) * 60).floor();
    final int second = ((((seconds / 3600 - hour) * 60) - minute) * 60).floor();
    return [
      if (hour > 0) hour.toString().padLeft(2, "0"),
      minute.toString().padLeft(2, "0"),
      second.toString().padLeft(2, '0'),
    ].join(':');
  }

  @override
  String toString({bool showTime = true}) {
    String info = "$name ($rating)";
    return showTime ? "$info: ${_formattedTime(clock)}" : info;
  }
}