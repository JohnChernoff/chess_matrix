import 'dart:async';
import 'dart:collection';
import 'package:chess_matrix/chess_sonifier.dart';
import 'package:chess_matrix/game_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oauth/flutter_oauth.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:oauth2/oauth2.dart';
import 'package:zug_utils/zug_utils.dart';
import 'board_matrix.dart';
import 'board_state.dart';
import 'chess.dart';
import 'main.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:file_saver/file_saver.dart';
import 'package:chess/chess.dart' as dc;
import 'package:image/image.dart' as img;
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;

class MatrixClient extends ChangeNotifier {
  final Map<String,img.Image?> pieceImages = {};
  int initialBoardNum;
  int matrixResolution = 300;
  PieceStyle pieceStyle = PieceStyle.caliente;
  GameStyle gameStyle = GameStyle.blitz;
  bool showControl = false;
  bool showMove = true;
  MatrixColorScheme colorScheme = ColorStyle.heatmap.colorScheme;
  MixStyle mixStyle = MixStyle.pigment;
  int maxControl = 2;
  bool seeking = false;
  bool creatingGIF = false;
  bool authenticating = false;
  String? lichessToken;
  dynamic userInfo;
  final OauthClient oauthClient = OauthClient("lichess.org","chessMatrix");
  late final LichessClient lichessClient;
  late final ChessSonifier sonifier;
  late final GameHandler gameHandler;
  late IList<BoardState> viewBoards = IList(List.generate(initialBoardNum, (slot) => BoardState(slot)));
  IList<BoardState> playBoards = const IList.empty();
  IList<BoardState> get activeBoards => playBoards.isNotEmpty ? playBoards : viewBoards;

  MatrixClient(String host, {this.initialBoardNum = 1}) {
    sonifier = ChessSonifier(this);
    gameHandler = GameHandler(this,sonifier);
    lichessClient = LichessClient(host: host,web: true,onConnect: connected,onDisconnect: disconnected, onMsg: gameHandler.handleMsg);
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
      lichessClient.getEventStream(accessToken, gameHandler.followStream);
      updateView();
    }
  }

  int getRating(double minutes, int inc) {
    return getRatingByType(LichessClient.getRatingType(minutes, inc)?.name); //print("Rating type: $ratingType");
  }

  int getRatingByType(String? ratingType) {
    return (userInfo?['perfs']?[ratingType]?['rating']) ?? 1500;
  }



  void sendMove(String? id, String from, String to, String? prom) { //lichSock.send(jsonEncode({ 't': 'move', 'd':   { 'u': uci, }}));
    String? token = lichessToken; if (token == null) { return; }
    String uci = prom != null ? "$from$to$prom" : "$from$to"; mainLogger.f("Sending move: $uci");
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
          mainLogger.f("Seek Status: $statusCode");
          seeking = false;
        }, onError: (err) => mainLogger.w("Seek error: $err"));
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
          mainLogger.f("Challenge Status: $statusCode");
          seeking = false;
        }, onError: (err) => mainLogger.w("Challenge error: $err"));
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

  void setPieceStyle(PieceStyle style) { //setPieces();
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
    mainLogger.i("Connected");
    loadTVGames();
  }

  void disconnected() {
    mainLogger.i("Disconnected");
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
        board.replaceable = true;
      }
    }
    List<dynamic> games = await lichessClient.getTV(gameStyle.name,30);
    List<dynamic> availableGames = games.where((game) => viewBoards.where((b) => b.id == game['id']).isEmpty).toList(); //remove pre-existing games
    List<BoardState> openBoards = viewBoards.where((board) => board.isOpen).toList(); //openBoards.sort(); //probably unnecessary
    for (BoardState board in openBoards) {
      if (availableGames.isNotEmpty) {
        dynamic game = availableGames.removeAt(0);
        String id = game['id']; //print("Adding: $id");
        board.initState(id, getFen(game['moves']), Player.fromTV(game['players']['white']), Player.fromTV(game['players']['black']),this);
        lichessClient.addSockMsg({ 't': 'startWatching', 'd': id });
      } else {
        mainLogger.w("Error: no available game for slot: ${board.slot}");
        break;
      }
    } //boards = boards.sort();
    mainLogger.f("Loaded: $viewBoards");
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

  void createGifFile(BoardState state, int resolution) async {
    creatingGIF = true; updateView();
    generateGIF(state, resolution).then((bytes) {
      if (bytes?.isNotEmpty ?? false) {
        FileSaver.instance.saveFile(
          name: "zenchess.gif",
          bytes: bytes,
          mimeType: MimeType.gif,
        );
      }
    });
    creatingGIF = false;
    updateView();
  }

  Future<Uint8List?> generateGIF(BoardState state, int resolution) async {
    if (state.moves.isEmpty) return null;
    await setPieces();
    final encoder = img.GifEncoder();
    for (MoveState m in state.moves) {
      final matrix = BoardMatrix.fromFEN(m.afterFEN, width: resolution, height: resolution, colorScheme: colorScheme);
      final data = matrix.generateRawImage();
      img.Image image = img.Image.fromBytes(width: resolution, height: resolution, bytes: data.buffer, order: img.ChannelOrder.rgba, frameType: img.FrameType.animation);
      image = drawPieces(matrix,image);
      encoder.addFrame(image); updateView();
      //print("Adding frame: $image");
    }
    mainLogger.i("Writing GIF");
    return encoder.finish();
  }

  Future<void> setPieces() async {
    for (PieceType t in PieceType.values) {
      if (t != PieceType.none) {
        final wPath = "${pieceStyle.name}/w${t.fileLetter}.png";
        final bPath = "${pieceStyle.name}/b${t.fileLetter}.png";
        final wPieceImg = await ZugUtils.imageToImgPkg(cb.ChessBoard.getPieceImage(wPath));
        pieceImages.update(Piece(t,ChessColor.white).toString(), (i) => wPieceImg, ifAbsent: () => wPieceImg);
        final bPieceImg = await ZugUtils.imageToImgPkg(cb.ChessBoard.getPieceImage(bPath));
        pieceImages.update(Piece(t,ChessColor.black).toString(), (i) => bPieceImg, ifAbsent: () => bPieceImg);
      }
    }
    mainLogger.i("Loaded Pieces");
  }

  img.Image drawPieces(BoardMatrix matrix, img.Image boardImg) {
     double squareWidth = boardImg.width / files;
     double squareHeight = boardImg.height / ranks;
     for (int rank = 0; rank < ranks; rank++) {
        for (int file = 0; file < files; file++) {
          final ps = matrix.getSquare(Coord(file,rank)).piece.toString(); //print(ps);
          final p = pieceImages[ps]; //print(p);
          if (p != null) {
            boardImg = img.compositeImage(boardImg, p,
                dstX: (squareWidth * file).floor(), dstY: (squareHeight * rank).floor(), dstW: squareWidth.floor(), dstH: squareHeight.floor());
          }
        }
      }
     return boardImg;
  }

}



