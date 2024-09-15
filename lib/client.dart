import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:chess/chess.dart' as dc;
import 'package:chess_matrix/board_sonifier.dart';
import 'package:chess_matrix/board_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'board_matrix.dart';
import 'matrix_fields.dart';

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
  late final BoardSonifier sonifier;
  late final ZugSock lichSock;

  MatrixClient(this.maxStreams,this.width,this.height) {
    sonifier = BoardSonifier(this);
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

  void toggleAudio() {
    sonifier.muted = !sonifier.muted;
    if (!sonifier.muted && !sonifier.audioReady) {
      initAudio();
    } else {
      notifyListeners();
    }
  }

  Future<void> initAudio() async {
    print("Loading audio");
    await sonifier.init(0);
    notifyListeners();
  }

  void loadInstrument(InstrumentType type, MidiInstrument patch) async {
    await sonifier.loadInstrument(type, Instrument(patch)); //TODO: levels
    notifyListeners(); //todo: avoid redundancy when calling via initAudio?
  }

  void connected() {
    print("Connected");
    loadTVGames();
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

  void handleMsg(String msg) { //print("Message: $msg");
    dynamic json = jsonDecode(msg);
    String type = json['t'];
    dynamic data = json['d'];
    String id = data['id'] ?? "";
    if (type == "fen") {
      int whiteClock = int.parse(data['wc'].toString());
      int blackClock = int.parse(data['bc'].toString());
      Move lastMove = Move(data['lm']);
      String fen = data['fen'];
      BoardMatrix? matrix = updateBoardWidget(id, fen, lastMove, whiteClock, blackClock);
      Piece? piece = matrix?.getSquare(lastMove.to).piece;
      InstrumentType? instType = switch(piece?.type) {
        null => null,
        PieceType.none => null,
        PieceType.pawn => InstrumentType.pawnMelody,
        PieceType.knight => InstrumentType.knightMelody,
        PieceType.bishop => InstrumentType.bishopMelody,
        PieceType.rook => InstrumentType.rookMelody,
        PieceType.queen => InstrumentType.queenMelody,
        PieceType.king => InstrumentType.kingMelody,
      };
      int toPitch = (lastMove.to.y * 8) + lastMove.to.x;
      if (matrix?.turn == ChessColor.black) toPitch = 64 - toPitch;
      sonifier.playMelody(instType, minPitch + toPitch, sonifier.orchMap[instType?.name]?.level ?? .5);
    } else if (type == 'finish') {
      getBoardStateByID(id)?.finished = true;
      loadTVGames();
    }
  }

  BoardMatrix? updateBoardWidget(String id, String fen, Move? lastMove, int whiteClock, int blackClock) {
    BoardWidget? w = getWidgetByID(id);
    if (w != null) {
      return updaters[w](fen,lastMove,whiteClock,blackClock);
    }
    return null;
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

  String getFen(String moves) {
    dc.Chess chess = dc.Chess();
    chess.load_pgn(moves);
    return chess.fen;
  }

  void addBoard(dynamic game) {
    String id = game['id'];
    Player whitePlayer = Player(game['players']['white']);
    Player blackPlayer = Player(game['players']['black']);
    if (getBoardStateByID(id) == null) {
      BoardWidget? widget = getOpenBoard();
      if (widget != null) { //print("Adding: $game");
        boards.update(widget, (state) => BoardState(id,whitePlayer,blackPlayer));
        updateBoardWidget(id, getFen(game['moves']), null, 0, 0);
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

  //TODO: improve?
  String _formattedTime(int seconds) {
    final int hour = (seconds / 3600).floor();
    final int minute = ((seconds / 3600 - hour) * 60).floor();
    final int second = ((((seconds / 3600 - hour) * 60) - minute) * 60).round();
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