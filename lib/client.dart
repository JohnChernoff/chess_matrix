import 'dart:math';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:chess/chess.dart' as dc;
import 'package:chess_matrix/board_sonifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oauth/flutter_oauth.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'package:oauth2/oauth2.dart';
import 'board_state.dart';
import 'board_matrix.dart';
import 'matrix_fields.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class MatrixClient extends ChangeNotifier {
  int initialBoardNum;
  int matrixResolution = 250;
  PieceStyle pieceStyle = PieceStyle.horsey;
  GameStyle gameStyle = GameStyle.blitz;
  bool showControl = false;
  bool showMove = false;
  bool realTime = false;
  Color blackPieceColor = const Color.fromARGB(255, 22, 108, 0);
  MatrixColorScheme colorScheme = ColorStyle.blueRed.colorScheme;
  MixStyle mixStyle = MixStyle.pigment;
  int maxControl = 2;
  final Map<String,ui.Image> pieceImages = {};
  late final BoardSonifier sonifier;
  late final ZugSock lichSock;
  late IList<BoardState> viewBoards = IList(List.generate(initialBoardNum, (slot) => BoardState(slot,false)));
  IList<BoardState> playBoards = const IList.empty();
  IList<BoardState> get activeBoards => playBoards.isNotEmpty ? playBoards : viewBoards;
  bool seeking = false;
  bool authenticating = false;
  String? lichessToken;
  String userName = "?";
  OauthClient oauthClient = OauthClient("lichess.org","chessMatrix");

  MatrixClient(String matrixURL, {this.initialBoardNum = 1}) {
    sonifier = BoardSonifier(this);
    lichSock = ZugSock(matrixURL, connected, handleMsg, disconnected);
    oauthClient.checkRedirect(getClient);
  }

  void lichessLogin() {
    authenticating = true;
    oauthClient.authenticate(getClient,scopes: ["board:play"]); //,(client) => setToken(client?.credentials.accessToken));
  }

  void getClient(Client? client) {
    setToken(client?.credentials.accessToken);
    authenticating = false;
  }

  void setToken(String? accessToken) {
    print("Access Token: $accessToken");
    lichessToken = accessToken;
    if (lichessToken != null) {
      Lichess.getEventStream(lichessToken!, followStream, web: kIsWeb);
    }
    updateView();
  }

  void followStream(Stream<String> eventStream) { print("Event: $eventStream");
    String? token = lichessToken; if (token == null) { return; }
    eventStream.listen((data) {
      if (data.trim().isNotEmpty) {
        print('Event Chunk: $data');
        dynamic json = jsonDecode(data);
        String type = json["type"];
        if (type == "gameStart") {
          dynamic game = json['game']; String id = game['gameId'];
          BoardState state = BoardState(playBoards.length,true);
          dynamic whitePlayer = game['color'] == 'white' ? {'id' : userName, 'rating' : 2000} : game['opponent'];
          dynamic blackPlayer = game['color'] == 'black' ? {'id' : userName, 'rating' : 2000} : game['opponent'];
          state.initState(id,startFEN,Player.fromSeek(whitePlayer),Player.fromSeek(blackPlayer),this);
          playBoards = playBoards.add(state);
          Lichess.followGame(id,token,followGame, web: kIsWeb);
          updateView();
        }
        else if (type == 'gameFinish') {
          dynamic game = json['game']; String id = game['gameId'];
          BoardState? state = playBoards.where((state) => state.id == id).firstOrNull;
          state?.finished = true;
        }
      }
    });
  }

  void followGame(String gid, Stream<String> gameStream) { print("Game: $gid");
    gameStream.listen((data) {
      if (data.trim().isNotEmpty) { //print('Game Chunk: $data');
        for (String chunk in data.split("\n")) {
          if (chunk.isNotEmpty) {
            dynamic json = jsonDecode(chunk.trim()); //print('JSON Chunk: $json');
            String? lastMove = json['lm'];
            BoardState? board = playBoards.where((state) => state.id == gid).firstOrNull;
            if (board != null) {
              String type = json['type'];
              dynamic state = type == 'gameState' ? json : type == 'gameFull' ? json['state'] : null;
              if (state != null) { print("State: $state");
                String moves = state['moves'].trim();
                if (moves.length > 1) {
                  dc.Chess chess = dc.Chess.fromFEN(startFEN);
                  for (String m in moves.split(" ")) {
                    if (m.length == 4) {
                      chess.move({'from': m.substring(0,2), 'to': m.substring(2,4)});
                    }
                    else if (m.length == 5) {
                      chess.move({'from': m.substring(0,2), 'to': m.substring(2,4), 'promotion': m[4]});
                    }
                  }
                  board.updateBoard(chess.fen, lastMove != null ? Move(lastMove) : null, ((state['wtime'] ?? 0)/1000).floor(), ((state['btime'] ?? 0)/1000).floor(),this);
                  updateView();
                }
              }
            }
          }
        }
      }
    });
  }

  void sendMove(String? id, String from, String to, String? prom) { //lichSock.send(jsonEncode({ 't': 'move', 'd':   { 'u': uci, }}));
    String? token = lichessToken; if (token == null) { return; }
    String uci = prom != null ? "$from$to$prom" : "$from$to"; print("Sending move: $uci");
    Lichess.makeMove(uci, id ?? "", token);
  }

  void seekGame(int minutes, int inc, bool rated ) {  //lichSock.send(jsonEncode({ 't': 'poolIn', 'd': '3' }));
    String? token = lichessToken; if (token == null) { return; }
    if (playBoards.isEmpty) {
      if (seeking) {
        cancelSeek();
      }
      else {
        seeking = true;
        Lichess.createSeek(LichessVariant.standard, minutes, inc, rated, token).then((statusCode) { //, minRating: 2299, maxRating: 2301, color:"black"
          print("Seek Status: $statusCode");
          seeking = false;
        }, onError: (oops) => print("Oops: $oops"));
      }
      updateView();
    }
  }

  void cancelSeek() {
    Lichess.removeSeek();
    notifyListeners();
  }

  void updateView({updateBoards = false}) {
    if (updateBoards) {
      for (BoardState board in activeBoards) {
        board.refreshBoard(this);
      }
    }
    notifyListeners();
  }

  void setMaxControl(int control) {
    maxControl = control;
    updateView(updateBoards: true);
  }

  void setColorScheme({Color? whiteColor, Color? blackColor, Color? voidColor}) {
    colorScheme = MatrixColorScheme(
        whiteColor ?? colorScheme.whiteColor,
        blackColor ?? colorScheme.blackColor,
        voidColor ?? colorScheme.voidColor);
    updateView(updateBoards: true);
  }

  void setPieceStyle(PieceStyle style) {
    pieceStyle = style;
    updateView();
  }

  void setGameStyle(GameStyle style) {
    gameStyle = style;
    loadTVGames(reset: true);
  }

  void setMixStyle(MixStyle style) {
    mixStyle = style;
    updateView(updateBoards: true);
  }

  void setResolution(int resolution) {
    matrixResolution = resolution;
    updateView(updateBoards: true);
  }

  void toggleAudio() {
    sonifier.muted = !sonifier.muted;
    if (!sonifier.muted && !sonifier.audioReady) {
      initAudio();
    } else {
      updateView();
    }
  }

  void toggleDrums() {
    sonifier.muteDrums = !sonifier.muteDrums;
    updateView();
  }

  Future<void> initAudio() async {
    print("Loading audio");
    await sonifier.init(0);
    sonifier.loopTrack(sonifier.masterTrack);
    updateView();
  }

  void loadInstrument(InstrumentType type, MidiInstrument patch) async {
    await sonifier.loadInstrument(type, Instrument(iPatch: patch)); //TODO: levels
    updateView(); //todo: avoid redundancy when calling via initAudio?
  }

  Future<void> loadRandomEnsemble() async {
    await sonifier.loadEnsemble(sonifier.randomEnsemble());
    updateView();
  }

  void connected() {
    print("Connected");
    loadTVGames();
  }

  void disconnected() {
    print("Disconnected");
  }

  void closeLiveGame(BoardState state) {
    playBoards = playBoards.remove(state);
    updateView(updateBoards: true);
  }

  void setNumGames(int n) {
    int prevBoards = viewBoards.length;
    viewBoards = viewBoards.removeWhere((board) => board.slot > n);
    int diff = n - (viewBoards.length - 1);
    if (diff > 0) { //print("Adding $diff extra boards...");
      viewBoards = viewBoards.addAll(List.generate(diff, (i) => BoardState(prevBoards + i,false)));
    }
  }

  void setSingleState(BoardState state) {
    viewBoards = viewBoards.clear();
    viewBoards = viewBoards.add(state);
    updateView();
  }

  void loadTVGames({reset = false, int? numBoards}) async {
    if (numBoards != null) {
      setNumGames(numBoards);
    }
    if (reset) {
      for (var board in viewBoards) {
        board.replacable = true;
      }
    }
    List<dynamic> games = await Lichess.getTV(gameStyle.name,30);
    List<dynamic> availableGames = games.where((game) => viewBoards.where((b) => b.id == game['id']).isEmpty).toList(); //remove pre-existing games
    List<BoardState> openBoards = viewBoards.where((board) => board.replacable || board.finished).toList(); //openBoards.sort(); //probably unnecessary
    for (BoardState board in openBoards) {
      if (availableGames.isNotEmpty) {
        dynamic game = availableGames.removeAt(0);
        String id = game['id']; //print("Adding: $id");
        board.initState(id, getFen(game['moves']), Player.fromTV(game['players']['white']), Player.fromTV(game['players']['black']),this);
        lichSock.send(
            jsonEncode({ 't': 'startWatching', 'd': id })
        );
      } else {
        print("Error: no available game for slot: ${board.slot}");
        break;
      }
    } //boards = boards.sort();
    print("Loaded: $viewBoards");
    updateView();
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
        String fen = data['fen']; //print("FEN: $fen");
        String fullFEN = "$fen - - 0 1"; //print("Full FEN: $fullFEN");
        BoardMatrix? matrix = board.updateBoard(fullFEN, lastMove, whiteClock, blackClock, this);
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
        loadTVGames();
      }
    }
  }

  void keyChange() { //print("Key change!");
    sonifier.currentChord = KeyChord(
        BoardSonifier.getNewNote(sonifier.currentChord.key),
        BoardSonifier.getNewScale(sonifier.currentChord.scale));
    updateView();
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
    return activeBoards.where((state) => state.id == id).firstOrNull;
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

  Player.fromTV(dynamic data) : name = data['user']['name'], rating = int.parse(data['rating'].toString());
  Player.fromSeek(dynamic data) : name = data['id'], rating = data['rating'];

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
  final Color whiteColor;
  final Color blackColor;
  final Color voidColor;
  const MatrixColorScheme(this.whiteColor,this.blackColor,this.voidColor);
}