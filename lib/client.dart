import 'dart:math';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:chess/chess.dart' as dc;
import 'package:chess_matrix/board_sonifier.dart';
import 'package:flutter/material.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'board_state.dart';
import 'board_matrix.dart';
import 'matrix_fields.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class MatrixClient extends ChangeNotifier {
  int initialBoardNum;
  static int matrixResolution = 250; //slider?
  static PieceStyle pieceStyle = PieceStyle.horsey;
  static GameStyle gameStyle = GameStyle.blitz;
  bool showControl = false;
  bool showMove = false;
  bool realTime = false;
  final Map<String,ui.Image> pieceImages = {};
  Color blackPieceColor = const Color.fromARGB(255, 22, 108, 0);
  MatrixColorScheme colorScheme = MatrixColorScheme(Colors.blue, Colors.red, Colors.black);
  int maxControl = 2;
  late IList<BoardState> boards = IList(List.generate(initialBoardNum, (slot) => BoardState(slot)));
  late final BoardSonifier sonifier;
  late final ZugSock lichSock;

  MatrixClient(String matrixURL, {this.initialBoardNum = 1}) {
    sonifier = BoardSonifier(this);
    lichSock = ZugSock(matrixURL, connected, handleMsg, disconnected);
  }

  void setMaxControl(int control) {
    maxControl = control;
    notifyListeners();
  }

  void setColorScheme({Color? whiteColor, Color? blackColor, Color? voidColor}) {
    colorScheme = MatrixColorScheme(
        whiteColor ?? colorScheme.whiteColor,
        blackColor ?? colorScheme.blackColor,
        voidColor ?? colorScheme.voidColor);
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

  void toggleDrums() {
    sonifier.muteDrums = !sonifier.muteDrums;
    notifyListeners();
  }

  Future<void> initAudio() async {
    print("Loading audio");
    await sonifier.init(0);
    sonifier.loopTrack(sonifier.masterTrack);
    notifyListeners();
  }

  void loadInstrument(InstrumentType type, MidiInstrument patch) async {
    await sonifier.loadInstrument(type, Instrument(iPatch: patch)); //TODO: levels
    notifyListeners(); //todo: avoid redundancy when calling via initAudio?
  }

  Future<void> loadRandomEnsemble() async {
    await sonifier.loadEnsemble(sonifier.randomEnsemble());
    notifyListeners();
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
    int diff = n - (boards.length - 1);
    if (diff > 0) { //print("Adding $diff extra boards...");
      boards = boards.addAll(List.generate(diff, (i) => BoardState(prevBoards + i)));
    }
  }

  void loadTVGames({reset = false, int? numBoards}) async {
    if (numBoards != null) {
      setNumGames(numBoards);
    }
    if (reset) {
      for (var board in boards) {
        board.replacable = true;
      }
    }
    List<dynamic> games = await Lichess.getTV(gameStyle.name,boards.length);
    List<dynamic> availableGames = games.where((game) => boards.where((b) => b.id == game['id']).isEmpty).toList(); //remove pre-existing games
    boards.where((board) => games.where((game) => game['id'] == board.id && !board.finished).isNotEmpty).forEach((board) => board.replacable = false); //preserve existing boards
    List<BoardState> openBoards = boards.where((board) => board.replacable).toList();
    openBoards.sort(); //probably unnecessary
    for (BoardState board in openBoards) {
      if (availableGames.isNotEmpty) {
        dynamic game = availableGames.removeAt(0);
        String id = game['id']; //print("Adding: $id");
        board.initState(id, getFen(game['moves']), Player(game['players']['white']), Player(game['players']['black']),colorScheme,maxControl);
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
    BoardState? board = getBoardByID(id);
    if (board != null) {
      if (type == "fen") {
        int whiteClock = int.parse(data['wc'].toString());
        int blackClock = int.parse(data['bc'].toString());
        Move lastMove = Move(data['lm']);
        String fen = data['fen'];
        BoardMatrix? matrix = board.updateBoard(fen, lastMove, whiteClock, blackClock, colorScheme, maxControl);
        if (matrix != null) {
          Piece piece = matrix.getSquare(lastMove.to).piece; //print("LastMove: ${lastMove.from}-${lastMove.to}, piece: ${piece.type}");
          if (piece.type == PieceType.none) {  //print("castling?!");
            keyChange();
          }
          else {
            generatePieceNotes(piece,calcMoveDistance(lastMove).round(),piece.color == ChessColor.black ? lastMove.to.y : ranks - (lastMove.to.y));
            if (piece.type == PieceType.pawn) {
              generatePawnRhythms(matrix,false,piece.color);
            }
          }
        }
      } else if (type == 'finish') {
        print("Finished: $id");
        board.finished = true;
        board.replacable = true;
        loadTVGames();
      }
    }
  }

  void keyChange() { print("Key change!");
    sonifier.currentChord = KeyChord(
        BoardSonifier.getNewNote(sonifier.currentChord.key),
        BoardSonifier.getNewScale(sonifier.currentChord.scale));
    notifyListeners();
  }

  InstrumentType? getPieceInstrument(Piece piece) {
    return switch(piece.type) {
      PieceType.none => null, //shouldn't occur
      PieceType.pawn => InstrumentType.pawnMelody,
      PieceType.knight => InstrumentType.knightMelody,
      PieceType.bishop => InstrumentType.bishopMelody,
      PieceType.rook => InstrumentType.rookMelody,
      PieceType.queen => InstrumentType.queenMelody,
      PieceType.king => InstrumentType.kingMelody,
    };
  }

  void generatePieceNotes(Piece piece, int distance, int yDist) {
    Instrument? pieceInstrument = sonifier.orchMap[getPieceInstrument(piece)];
    Instrument? mainInstrument = sonifier.orchMap[InstrumentType.mainMelody];
    if (pieceInstrument != null && mainInstrument != null) {
      double dur = (yDist+1)/4;
      int newPitch = sonifier.getNextPitch(pieceInstrument.currentPitch, piece.color == ChessColor.black ? -distance : distance, sonifier.currentChord);

      sonifier.masterTrack.addNoteEvent(sonifier.masterTrack.createNoteEvent(pieceInstrument,newPitch,dur,.5),MusicalElement.harmony);
      newPitch = sonifier.getNextPitch(mainInstrument.currentPitch, piece.color == ChessColor.black ? -distance : distance, sonifier.currentChord);
      sonifier.masterTrack.addNoteEvent(sonifier.masterTrack.createNoteEvent(mainInstrument,newPitch,dur,.5),MusicalElement.harmony);
    }
  }

  void generatePawnRhythms(BoardMatrix board, bool realTime, ChessColor color, {drumVol = .25, compVol = .33, crossRhythm=false}) { //print("Generating pawn rhythm map...");
    Instrument? i = sonifier.orchMap[InstrumentType.mainRhythm];
    if (i != null) {
      sonifier.masterTrack.newRhythmMap.clear();
      double duration = sonifier.masterTrack.maxLength ?? 2;
      double halfDuration = duration / 2;
      double dur = duration / ranks;
      for (int beat = 0; beat < files; beat++) {
        for (int steps = 0; steps < ranks; steps++) {
          Piece compPiece = crossRhythm ? board.getSquare(Coord(steps,beat)).piece : board.getSquare(Coord(beat,steps)).piece;
          Piece drumPiece = crossRhythm ? board.getSquare(Coord(beat,steps)).piece : board.getSquare(Coord(steps,beat)).piece;
          if (compPiece.type == PieceType.pawn) { // && p.color == color) {
            double t = (beat/files) * duration;
            int pitch = sonifier.getNextPitch(sonifier.currentChord.key.index + (octave * 4), steps, sonifier.currentChord);
            sonifier.masterTrack.newRhythmMap.add(sonifier.masterTrack.createNoteEvent(i, pitch, dur, compVol, offset: t));
          }
          if (drumPiece.type == PieceType.pawn) {
            double t = (beat/files) * halfDuration;
            int pitch = 60;
            if (steps < sonifier.drumMap.values.length) {
              sonifier.masterTrack.newRhythmMap.add(sonifier.masterTrack.createNoteEvent(sonifier.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: t));
              sonifier.masterTrack.newRhythmMap.add(sonifier.masterTrack.createNoteEvent(sonifier.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: halfDuration + t));
            }
          }
        }
      }
    }
  }

  void handleMidiComplete() {
    print("Track finished"); //sonifier.playAllTracks();
  }

  double calcMoveDistance(Move move) {
    return sqrt(pow((move.from.x - move.to.x),2) + pow((move.from.y - move.to.y),2));
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

class MatrixColorScheme {
  Color whiteColor = Colors.blue;
  Color blackColor = Colors.red;
  Color voidColor = Colors.black;
  MatrixColorScheme(this.whiteColor,this.blackColor,this.voidColor);
}