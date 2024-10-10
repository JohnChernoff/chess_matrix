import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:chess/chess.dart' as dc;
import 'package:chess_matrix/chess_sonifier.dart';
import 'package:chess_matrix/tv_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oauth/flutter_oauth.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:oauth2/oauth2.dart';
import 'board_state.dart';
import 'chess.dart';
import 'matrix_fields.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class MatrixClient extends ChangeNotifier {
  int initialBoardNum;
  int matrixResolution = 300;
  PieceStyle pieceStyle = PieceStyle.caliente;
  GameStyle gameStyle = GameStyle.blitz;
  bool showControl = false;
  bool showMove = true;
  MatrixColorScheme colorScheme = ColorStyle.heatmap.colorScheme;
  MixStyle mixStyle = MixStyle.pigment;
  int maxControl = 2;
  final Map<String,ui.Image> pieceImages = {};
  bool seeking = false;
  bool authenticating = false;
  String? lichessToken;
  dynamic userInfo;
  final OauthClient oauthClient = OauthClient("lichess.org","chessMatrix");
  late final LichessClient lichessClient;
  late final ChessSonifier sonifier;
  late final TVHandler tvHandler;
  late IList<BoardState> viewBoards = IList(List.generate(initialBoardNum, (slot) => BoardState(slot)));
  IList<BoardState> playBoards = const IList.empty();
  IList<BoardState> get activeBoards => playBoards.isNotEmpty ? playBoards : viewBoards;

  MatrixClient(String host, {this.initialBoardNum = 1}) {
    sonifier = ChessSonifier(this);
    tvHandler = TVHandler(this,sonifier);
    lichessClient = LichessClient(host: host,web: true,onConnect: connected,onDisconnect: disconnected, onMsg: tvHandler.handleMsg);
    oauthClient.checkRedirect(getClient);
  }

  void lichessLogin() {
    authenticating = true;
    oauthClient.authenticate(getClient,scopes: ["board:play"]);
  }

  void getClient(Client? client) {
    setToken(client?.credentials.accessToken);
    authenticating = false;
  }

  Future<void> setToken(String? accessToken) async {
    if (accessToken != null) { //print("Access Token: $accessToken");
      lichessToken = accessToken;
      userInfo = await lichessClient.getAccount(accessToken);
      lichessClient.getEventStream(accessToken, followStream);
      updateView();
    }
  }

  int getRating(double minutes, int inc) {
    return getRatingByType(LichessClient.getRatingType(minutes, inc)?.name); //print("Rating type: $ratingType");
  }

  int getRatingByType(String? ratingType) {
    return (userInfo?['perfs']?[ratingType]?['rating']) ?? 1500;
  }

  void followStream(Stream<String> eventStream) { print("Event: $eventStream");
    String? token = lichessToken; if (token == null) { return; }
    eventStream.listen((data) {
      if (data.trim().isNotEmpty) { print('Event Chunk: $data');
        dynamic json = jsonDecode(data);
        String type = json["type"];
        if (type == "gameStart") {
          dynamic game = json['game']; String id = game['gameId'];
          dynamic whitePlayer = game['color'] == 'white' ? {'id' : userInfo['username'], 'rating' : getRatingByType(game['speed'])} : game['opponent'];
          dynamic blackPlayer = game['color'] == 'black' ? {'id' : userInfo['username'], 'rating' : getRatingByType(game['speed'])} : game['opponent'];
          BoardState state = BoardState(playBoards.length,playing: game['color'] == 'white' ? ChessColor.white : ChessColor.black, blackPOV : (game['color'] == 'black'));
          state.initState(id,startFEN,Player.fromSeek(whitePlayer),Player.fromSeek(blackPlayer),this);
          playBoards = playBoards.add(state);
          lichessClient.followGame(id,token,followGame);
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

  void followGame(String gid, Stream<String> gameStream) { print("Following Game: $gid");
    gameStream.listen((data) {
      if (data.trim().isNotEmpty) { //print('Game Chunk: $data');
        for (String chunk in data.split("\n")) {
          if (chunk.isNotEmpty) {
            dynamic json = jsonDecode(chunk.trim()); //print('JSON Chunk: $json');
            String? lastMove = json['lm'];
            BoardState? board = playBoards.where((state) => state.id == gid).firstOrNull;
            if (board != null) {
              String type = json['type']; //print("Game Event Type: $type : $json");

              if (type == 'chatLine') {
                  //board.drawOffered = true;
              }
              else {
                bool? wdraw = json['wdraw'], bdraw = json['bdraw'];
                if (wdraw ?? false) {
                  if (board.playing == ChessColor.black) {
                    board.drawOffered = true; //!board.drawOffered;
                  } else {
                    board.offeringDraw = true;
                  }
                }
                else if (bdraw ?? false) {
                  if (board.playing == ChessColor.white) {
                    board.drawOffered = true; //!board.drawOffered;
                  } else {
                    board.offeringDraw = true;
                  }
                }
                else {
                  board.offeringDraw = false; board.drawOffered = false;
                }
                //board.drawOffered = false;
                dynamic state = type == 'gameState' ? json : type == 'gameFull' ? json['state'] : null;
                if (state != null) { //print("State: $state");
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
                  }
                  //updateView();
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
    lichessClient.makeMove(uci, id ?? "", token);
  }

  void seekGame(int minutes, { inc = 0, int? min, int? max, rated = false } ) {  //lichSock.send(jsonEncode({ 't': 'poolIn', 'd': '3' }));
    String? token = lichessToken; if (token == null) { return; }
    if (playBoards.isEmpty) {
      if (seeking) {
        cancelSeek();
      }
      else {
        seeking = true;  //print("Seeking: $minutes,$inc"); //Lichess.createSeek(LichessVariant.standard, minutes, inc, rated, token, minRating: 2299, maxRating: 2301).then((statusCode) {
        lichessClient.createSeek(LichessVariant.standard, minutes, inc, rated, token, minRating: min, maxRating: max).then((statusCode) {
          print("Seek Status: $statusCode");
          seeking = false;
        }, onError: (err) => print("Seek error: $err"));
      }
      updateView();
    }
  }

  void cancelSeek() {
    lichessClient.removeSeek();
    notifyListeners();
  }

  void createChallenge(String player, int seconds, int inc, bool rated) {
    String? token = lichessToken; if (token == null) { return; }
    if (playBoards.isEmpty) {
      if (seeking) {
        cancelSeek();
      }
      else {
        seeking = true;  //print("Seeking: $minutes,$inc"); //Lichess.createSeek(LichessVariant.standard, minutes, inc, rated, token, minRating: 2299, maxRating: 2301).then((statusCode) {
        lichessClient.createChallenge(player,LichessVariant.standard,seconds,inc,rated,token).then((statusCode) {
          print("Challenge Status: $statusCode");
          seeking = false;
        }, onError: (err) => print("Challenge error: $err"));
      }
      updateView();
    }
  }

  void cancelChallenge() {
    lichessClient.removeChallenge();
    notifyListeners();
  }

  void resign(BoardState state) {
    lichessClient.boardAction(BoardAction.resign, state.id ?? "", lichessToken ?? "");
  }

  void offerDraw(BoardState state) {
    lichessClient.boardAction(BoardAction.drawYes, state.id ?? "", lichessToken ?? "");
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

  void setColorScheme({Color? whiteControl, Color? blackControl, Color? voidColor, Color? whiteBlend, Color? blackBlend, Color? grid, MatrixColorScheme? scheme}) {
    colorScheme = scheme ?? MatrixColorScheme(
        whiteControl ?? colorScheme.whiteColor,
        blackControl ?? colorScheme.blackColor,
        voidColor ?? colorScheme.voidColor,
        whitePieceBlendColor: whiteBlend ?? colorScheme.whitePieceBlendColor,
        blackPieceBlendColor: blackBlend ?? colorScheme.blackPieceBlendColor,
        gridColor: grid ?? colorScheme.gridColor,
    );
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
      viewBoards = viewBoards.addAll(List.generate(diff, (i) => BoardState(prevBoards + i)));
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
    List<dynamic> games = await lichessClient.getTV(gameStyle.name,30);
    List<dynamic> availableGames = games.where((game) => viewBoards.where((b) => b.id == game['id']).isEmpty).toList(); //remove pre-existing games
    List<BoardState> openBoards = viewBoards.where((board) => board.replacable || board.finished).toList(); //openBoards.sort(); //probably unnecessary
    for (BoardState board in openBoards) {
      if (availableGames.isNotEmpty) {
        dynamic game = availableGames.removeAt(0);
        String id = game['id']; //print("Adding: $id");
        board.initState(id, getFen(game['moves']), Player.fromTV(game['players']['white']), Player.fromTV(game['players']['black']),this);
        lichessClient.addSockMsg({ 't': 'startWatching', 'd': id });
      } else {
        print("Error: no available game for slot: ${board.slot}");
        break;
      }
    } //boards = boards.sort();
    print("Loaded: $viewBoards");
    updateView();
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



