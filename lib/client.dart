import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:chess_matrix/board_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'board_matrix.dart';

class MatrixClient extends ChangeNotifier {
  final int maxStreams;
  final int width, height;
  final Map<BoardWidget?,BoardState?> boards = {};
  final Map<BoardWidget,dynamic> updaters = {};
  final Map<String,ui.Image> pieceImages = {};
  String gameType;
  late ZugSock lichSock;

  MatrixClient(this.gameType,this.maxStreams,this.width,this.height) {
    loadPieces();
    for (int i = 0; i < maxStreams; i++) {
      boards.putIfAbsent(BoardWidget(this,i), () => null);
    }
    lichSock = ZugSock('wss://socket.lichess.org/api/socket', connected, handleMsg, disconnected);
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

  Future<void> loadPieces() async {
    for (ChessColor c in ChessColor.values) {
      for (PieceType t in PieceType.values) {
        String p = Piece(t, c).toString(); //print("Loading: $p.png...");
        ui.Image img = await loadImage("assets/images/$p.png");
        pieceImages.putIfAbsent(p, () => img);
      }
    }
  }

  void loadTVGames({String? type}) async {
    List<dynamic> games = await Lichess.getTV(type ?? gameType);
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

  Future<ui.Image> loadImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: (height / 10).round(),
      targetWidth: (width / 10).round(),
    );
    var frame = await codec.getNextFrame();
    return frame.image;
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