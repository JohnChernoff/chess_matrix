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
  static int matrixWidth = 250, matrixHeight = 250;
  static PieceStyle pieceStyle = PieceStyle.horsey;
  static GameStyle gameStyle = GameStyle.blitz;
  bool showControl = false;
  bool showMove = false;
  bool realTime = false;
  final Map<String,ui.Image> pieceImages = {};
  late IList<BoardState> boards = IList(List.generate(8, (slot) => BoardState(slot)));
  Color blackPieceColor = const Color.fromARGB(255, 22, 108, 0);
  MatrixColorScheme colorScheme = MatrixColorScheme(Colors.blue, Colors.red, Colors.black);
  int maxControl = 5;
  late final BoardSonifier sonifier;
  late final ZugSock lichSock;

  MatrixClient(String matrixURL) {
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

  Future<void> initAudio() async {
    print("Loading audio");
    await sonifier.init(1);
    sonifier.looper(sonifier.rhythmTrack);
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
        if (matrix == null) return;
        Piece? piece = matrix.getSquare(lastMove.to).piece;
        InstrumentType? instType = switch(piece?.type) {
          null => null,
          PieceType.none => null, //castling?
          PieceType.pawn => InstrumentType.pawnMelody,
          PieceType.knight => InstrumentType.knightMelody,
          PieceType.bishop => InstrumentType.bishopMelody,
          PieceType.rook => InstrumentType.rookMelody,
          PieceType.queen => InstrumentType.queenMelody,
          PieceType.king => InstrumentType.kingMelody,
        };
        Instrument? i = sonifier.orchMap[instType];
        if (i != null) {
          if (realTime && !sonifier.playing) {
            int toPitch = (lastMove.to.y * 8) + lastMove.to.x;
            if (matrix.turn == ChessColor.black) toPitch = 64 - toPitch;
            sonifier.playMelody(i, minPitch + toPitch, i.level);
          }
          MidiTrack? rhythmTrack = sonifier.tracks[sonifier.rhythm];
          MidiTrack? leadTrack = sonifier.tracks[sonifier.lead];
          if (rhythmTrack != null && leadTrack != null) {
            int lastPitch = leadTrack.currentPitch ?? 60; //int lastPitch = sonifier.tracks[instType]?.currentPitch ?? 60;
            int distance = calcMoveDistance(lastMove).round();
            //int newPitch = piece?.color == ChessColor.black ? lastPitch - distance : lastPitch + distance;
            int newPitch = sonifier.getNextPitch(lastPitch, piece.color == ChessColor.black ? -distance : distance, sonifier.currentChord);
            int yDist = piece.color == ChessColor.black ? lastMove.to.y : ranks - (lastMove.to.y);
            double dur = (yDist+1)/8; //rhythmMap[yDist]; double dur2 = (lastMove.to.x+1)/8;
            if (instType == sonifier.rhythm) {
              //rhythmTrack.addNoteEvent(i,newPitch,dur,.2);
              //double lag = leadTrack.currentTime - rhythmTrack.currentTime;
              //if (lag > 0) rhythmTrack.addRest(i,lag);
              generatePawnRhythm(sonifier.orchMap[sonifier.rhythm]!,matrix,2,false);
            }
            Instrument? lead = sonifier.orchMap[sonifier.lead];
            if (lead != null) sonifier.tracks[InstrumentType.mainMelody]?.addNoteEvent(lead,newPitch,dur,.5);
          }
        }
        //sonifier.tracks[instType]?.addNoteEvent(newPitch,1, .2); //print("${lastMove.to}, $instType: $lastPitch -> $newPitch, rhythm: $dur");
        //sonifier.tracks[instType]?.addNoteEvent(newPitch,dur * 4, .2); //print("${lastMove.to}, $instType: $lastPitch -> $newPitch, rhythm: $dur");
        //sonifier.tracks[InstrumentType.mainMelody]?.addNoteEvent(newPitch,dur, .5);
      } else if (type == 'finish') {
        print("Finished: $id");
        board.finished = true;
        board.replacable = true;
        loadTVGames();
      }
    }
  }

  void generatePawnRhythm(Instrument i, BoardMatrix board, double duration, bool realTime) {
    print("Generating pawn rhythm map...");
    sonifier.rhythmTrack.clearTrack();
    double dur = duration / ranks;
    for (int beat = 0; beat < files; beat++) {
      List<int> chord = [];
      for (int steps = 0; steps < ranks; steps++) {
        if (board.getSquare(Coord(beat,steps)).piece.type == PieceType.pawn) {
        //if (board.getSquare(Coord(steps,beat)).piece.type == PieceType.pawn) {
          int pitch = sonifier.getNextPitch(sonifier.currentChord.key.index + (octave * 4), steps, sonifier.currentChord);
          chord.add(pitch); //print("Adding pitch: $pitch");
        }
        if (steps == ranks - 1) {
          if (realTime) {
            sonifier.playChord(i, beat * dur, chord, dur, .25);
          }
          else {
            if (chord.isEmpty) {
              sonifier.rhythmTrack.addRest(i,dur);
            } else {
              sonifier.rhythmTrack.addChordEvent(i, chord, dur, .25);
            }
            print("Adding chord: $chord");
          }
        }
      }
    }
  }

  void handleMidiComplete() {
    print("Track finished");
    //sonifier.playAllTracks();
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

  void playDrums() {
    for (BoardState state in boards) {
      if (state.board != null) {
        sonifier.playDrumTrack(state.board!,offset: state.slot);
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

class MatrixColorScheme {
  Color whiteColor = Colors.blue;
  Color blackColor = Colors.red;
  Color voidColor = Colors.black;
  MatrixColorScheme(this.whiteColor,this.blackColor,this.voidColor);
}