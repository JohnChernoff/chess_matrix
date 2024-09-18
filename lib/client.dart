import 'dart:convert';
import 'dart:ui' as ui;
import 'package:chess/chess.dart' as dc;
import 'package:chess_matrix/board_sonifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'board_state.dart';
import 'board_matrix.dart';
import 'matrix_fields.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class MatrixClient extends ChangeNotifier {
  static int matrixWidth = 250, matrixHeight = 250;
  static ColorStyle colorStyle = ColorStyle.redBlue;
  static PieceStyle pieceStyle = PieceStyle.horsey;
  static GameStyle gameStyle = GameStyle.blitz;
  bool showControl = false;
  bool showMove = false;
  final Map<String,ui.Image> pieceImages = {};
  late IList<BoardState> boards = IList(List.generate(8, (slot) => BoardState(slot)));
  Color blackPieceColor = const Color.fromARGB(255, 22, 108, 0);
  late final BoardSonifier sonifier;
  late final ZugSock lichSock;

  MatrixClient(String matrixURL) {
    sonifier = BoardSonifier(this);
    lichSock = ZugSock(matrixURL, connected, handleMsg, disconnected);
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
    loadTVGames(reset: true);
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

  void setNumGames(int n) {
    int prevBoards = boards.length;
    boards = boards.removeWhere((board) => board.slot > n);
    int diff = n - boards.length;
    if (diff > 0) {
      print("Adding $diff extra boards...");
      boards = boards.addAll(List.generate(diff, (i) => BoardState(prevBoards + i)));
    }
  }

  void loadTVGames({reset = false, int? numBoards}) async {
    if (numBoards != null) {
      setNumGames(numBoards-1);
    }
    if (reset) {
      for (var board in boards) {
        board.replacable = true;
      }
    }
    List<dynamic> games = await Lichess.getTV(gameStyle.name,boards.length);
    List<dynamic> availableGames = games.where((game) => boards.where((b) => b.id == game['id']).isEmpty).toList(); //remove pre-existing games
    boards.where((board) => games.where((game) => game['id'] == board.id).isNotEmpty).forEach((board) => board.replacable = false); //preserve existing boards
    List<BoardState> openBoards = boards.where((board) => board.replacable).toList();
    openBoards.sort(); //probably unnecessary
    for (BoardState board in openBoards) {
      if (availableGames.isNotEmpty) {
        dynamic game = availableGames.removeAt(0);
        String id = game['id']; //print("Adding: $id");
        board.initState(id, getFen(game['moves']), Player(game['players']['white']), Player(game['players']['black']));
        lichSock.send(
            jsonEncode({ 't': 'startWatching', 'd': id })
        );
      } else {
        print("Error: no available game for slot: ${board.slot}");
        break;
      }
    }
    boards = boards.sort();
    print("Loaded: $boards");
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
      BoardMatrix? matrix = getBoardByID(id)?.updateBoard(fen, lastMove, whiteClock, blackClock);
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
      getBoardByID(id)?.finished = true;
      loadTVGames();
    }
  }

  BoardState? getBoardByID(String id) {
    return boards.where((state) => state.id == id).firstOrNull;
  }

  String getFen(String moves) {
    dc.Chess chess = dc.Chess();
    chess.load_pgn(moves);
    return chess.fen;
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