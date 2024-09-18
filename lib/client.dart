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
  final int maxBoards = 30;
  int numBoards = 8;
  bool showControl = false;
  bool showMove = false;
  final Map<String,ui.Image> pieceImages = {};
  late IList<BoardState> boards = IList(List.generate(maxBoards, (slot) => BoardState(this,slot)));
  Iterable<BoardState> get visibleBoards => boards.where((board) => board.slot < numBoards);
  Iterable<BoardState> get invisibleBoards => boards.where((board) => board.slot >= numBoards);
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
    numBoards = n;
    //for (var board in visibleBoards) { board.notifyListeners(); }
    notifyListeners();
  }

  void loadTVGames({reset = false}) async {
    if (reset) {
      for (var board in boards) {
        board.replacable = true;
      }
    }
    List<dynamic> games = await Lichess.getTV(gameStyle.name,numBoards);
    Iterable<dynamic> newGames = games.where((game) => visibleBoards.where((vb) => vb.id == game['id']).isEmpty);
    List<BoardState> openBoards = visibleBoards.where((board) => board.replacable).toList();
    openBoards.sort(); //probably unnecessary
    for (BoardState board in openBoards) {
      for (dynamic game in newGames) {
        String id = game['id'];
        BoardState? swappableBoard = invisibleBoards.where((board) => board.id == id).firstOrNull;
        if (swappableBoard != null) {
            int slot = board.slot;
            board.slot = swappableBoard.slot;
            swappableBoard.slot = slot;
        }
        else {
          newBoard(board, game);
        }
      }
    }
    boards = boards.sort();
    //for (int i = 0; i < min(numBoards,games.length); i++) {  addBoard(games[i]); }
    notifyListeners();
  }

  void newBoard(BoardState board,dynamic game) {
    String id = game['id'];
    Player whitePlayer = Player(game['players']['white']);
    Player blackPlayer = Player(game['players']['black']);
    board.updateState(id,getFen(game['moves']),whitePlayer,blackPlayer);
    lichSock.send(
        jsonEncode({ 't': 'startWatching', 'd': id })
    );
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
    return visibleBoards.where((state) => state.id == id).firstOrNull;
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