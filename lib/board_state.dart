import 'dart:math';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'board_matrix.dart';
import 'chess.dart';
import 'client.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'main.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
//import 'package:universal_html/html.dart' as html;

class BoardState extends ChangeNotifier implements Comparable<BoardState> {
  String? id;
  String? initialFEN;
  Player? whitePlayer,blackPlayer;
  bool finished = false;
  bool replaceable = true;
  bool blackPOV;
  BoardMatrix? board;
  Timer? clockTimer;
  int slot;
  ChessColor playing;
  ui.Image? buffImg;
  IList<MoveState> moves = IList<MoveState>();
  cb.ChessBoardController controller = cb.ChessBoardController();
  int? boardSize;
  bool isFrozen = false;
  bool isAnimating = false;
  bool drawOffered = false, offeringDraw = false;
  bool get isLive => playing != ChessColor.none;
  int get currentSize => boardSize ?? 0;
  bool get isOpen => !isAnimating && (replaceable || finished);

  BoardState(this.slot, { this.playing = ChessColor.none, this.blackPOV = false } );

  void initState(String id,String fen, Player whitePlayer,Player blackPlayer, MatrixClient client) {
    replaceable = false;
    finished = false;
    this.id = id;
    this.whitePlayer = whitePlayer;
    this.blackPlayer = blackPlayer;
    updateBoard(fen, null, 0, 0, client);
    moves = moves.clear();
    initialFEN = fen;
  }

  @override
  String toString() {
      return "$slot: $id, fin: $finished, rep: $replaceable";
  }

  Timer countDown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (hasListeners) {
        if (board?.turn == ChessColor.white) {
          whitePlayer?.nextTick();
        } else if (board?.turn == ChessColor.black) {
          blackPlayer?.nextTick();
        }
        updateWidget();
      }
      else {
        clockTimer?.cancel();
        //dispose();
      }
    });
  }

  void updateWidget() {
    buffImg = board?.image;
    notifyListeners();
  }

  void refreshBoard(MatrixClient client) { //todo: check when needed (if ever)
    BoardMatrix? bm = board;
    if (bm != null) {
      int dim = min(client.matrixResolution,boardSize ?? 1000);
      board = BoardMatrix(bm.fen,bm.lastMove,dim,dim,client.colorScheme,client.mixStyle,(img) => updateWidget(),
          blackPOV: blackPOV, maxControl: client.maxControl);
    }
  }

  BoardMatrix? updateBoardToLatestPosition(MatrixClient client, {bool? freeze}) {
    if (moves.isNotEmpty) return updateBoard(moves.last.afterFEN,null,moves.last.whiteClock,moves.last.blackClock, client, freeze: freeze);
    return null;
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc, MatrixClient client, {bool? freeze}) { //print("Updating: $id");
    if (lastMove != null && board?.lastMove != lastMove) moves = moves.add(MoveState(lastMove, wc, bc, board?.fen, fen));
    if (freeze != null) {
      isFrozen = freeze;
    } else if (isFrozen) {
      return board;
    }
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    int dim = min(client.matrixResolution,boardSize ?? 1000); //print("Dim: $dim");
    board = BoardMatrix(fen,lastMove,dim,dim,client.colorScheme,client.mixStyle,(img) => updateWidget(), blackPOV: blackPOV, maxControl: client.maxControl);
    clockTimer = countDown();
    controller.loadFen(fen);
    return board;
  }

  void generateCumulativeControlBoard() {
    final currentBoard = board;
    if (currentBoard != null) {
      BoardMatrix bm = BoardMatrix.fromSquares(moves.first.beforeFEN ?? initialFEN ?? startFEN, BoardMatrix.createSquares());
      for (MoveState m in moves) {
        bm = BoardMatrix.fromSquares(m.afterFEN, bm.squares);
      }
      board = BoardMatrix.fromSquares(bm.fen, bm.squares,
        width: currentBoard.width, height: currentBoard.height, colorScheme: currentBoard.colorScheme,mixStyle: currentBoard.mixStyle, lastMove: currentBoard.lastMove,
        imgCall: (img) => updateWidget(),
      );
      mainLogger.f("Cumulative Board: $board");
    }
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

  Future<Uint8List?> generateGIF(MatrixClient client, int resolution) async {
      if (moves.isEmpty) return null;
      final encoder = img.GifEncoder();
      for (MoveState m in moves) {
        Completer completer = Completer();
        final bm = BoardMatrix(m.afterFEN,null,resolution,resolution,client.colorScheme,client.mixStyle,(boardImg) async {
          final bytes = await boardImg.toByteData();
          encoder.addFrame(img.Image.fromBytes(width: resolution, height: resolution, bytes: bytes!.buffer));
          completer.complete();
        });
        await completer.future; //print("Added Image: ${bm.image}");
      }
      return encoder.finish();
  }

  Future<void> createGifFile(MatrixClient client, int resolution) async {
    final data = await generateGIF(client, resolution);

    await FileSaver.instance.saveFile(
      name: "zenchess.gif",
      bytes: data,
      mimeType: MimeType.gif,
    );
  }

}

/*

    final blob = html.Blob([data],"image/gif");
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'zenchess.gif';
    html.document.body?.children.add(anchor);
    // download
    anchor.click();
    // cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
 */
