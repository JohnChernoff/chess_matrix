import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:zug_chess/board_matrix.dart';
import 'package:zug_chess/zug_chess.dart';
import 'package:zug_utils/zug_utils.dart';
import 'dart:async';
import 'client.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'img_utils.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'dart:ui' as ui;
import 'package:image/image.dart' as img_pkg;

enum BoardStatus {
  whiteWon,blackWon,draw,abort,playing,none
}

class BoardState extends ChangeNotifier implements Comparable<BoardState> {
  int slot;
  final String? id;
  final String initialFEN;
  final Player? whitePlayer,blackPlayer;
  final int? whiteStartTime, blackStartTime;
  final cb.ChessBoardController controller = cb.ChessBoardController();
  final ChessColor userSide;
  IList<MoveState> moves = IList<MoveState>();
  BoardStatus _status = BoardStatus.none;
  bool replaceable = true;
  bool blackPOV = false;
  BoardMatrix? board;
  Timer? clockTimer;
  ui.Image? buffImg;
  int? boardSize;
  bool isFrozen = false;
  bool isAnimating = false;
  bool drawOffered = false, offeringDraw = false;
  Image? finalImage;
  ChessColor? get turn =>  moves.isNotEmpty ? moves.last.turn : null;
  Move? get latestMove => moves.isNotEmpty ? moves.last.move : null;
  String get latestFEN => moves.isNotEmpty ? moves.last.afterFEN : initialFEN;
  bool get isLive => userSide != ChessColor.none;
  int get currentSize => boardSize ?? 0;
  bool get isOpen => !isAnimating && (replaceable || finished);
  bool get finished => (status != BoardStatus.playing);
  BoardStatus get status => _status;

  BoardState.empty(this.slot, { this.id, this.initialFEN = startFEN, this.whitePlayer, this.blackPlayer, this.whiteStartTime, this.blackStartTime, this.userSide = ChessColor.none} );
  BoardState.newGame(this.slot,this.id, this.whitePlayer, this.blackPlayer, MatrixClient client, { this.initialFEN = startFEN, this.userSide = ChessColor.none, this.blackPOV = false,
    this.whiteStartTime, this.blackStartTime, this.replaceable = false, Move? lastMove }) {
    _status = BoardStatus.playing;
    updateBoard(initialFEN, lastMove, whiteStartTime ?? 0, blackStartTime ?? 0, client);
  }

  Future<void> setStatus(BoardStatus s, MatrixClient client) async {
    _status = s;
    refreshBoard(client);
  }

  void setResult(bool whiteWin, bool blackWin, MatrixClient client) {
    if (whiteWin) {
      setStatus(BoardStatus.whiteWon,client);
    } else if (blackWin) {
      setStatus(BoardStatus.blackWon,client);
    }
    else {
      setStatus(BoardStatus.draw,client);
    }
  }

  @override
  String toString() {
      return "$slot: $id, fin: $finished, rep: $replaceable";
  }

  Timer countDown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (hasListeners && !finished) {
        if (turn == ChessColor.white) {
          whitePlayer?.nextTick();
        } else if (turn == ChessColor.black) {
          blackPlayer?.nextTick();
        }
        notifyListeners(); //updateWidget();
      }
      else {
        clockTimer?.cancel(); //dispose();
      }
    });
  }

  Future<void> updateWidget(ui.Image img) async {
    buffImg = img;
    if (finalImage == null && finished && board != null && boardSize != null) {
      final finImg = await ZugUtils.uImageToImgPkg(img);
      finalImage = Image.memory(img_pkg.encodePng(ImgUtils.drawPieces(board!, img_pkg.copyResize(finImg,width: boardSize,height: boardSize),status: _status)));
    }
    notifyListeners();
  }

  void refreshBoard(MatrixClient client) { //todo: check when needed (if ever)
    BoardMatrix? bm = board;
    if (bm != null) {
      int dim = min(client.matrixResolution,boardSize ?? 1000);
      board = BoardMatrix(fen: bm.fen, width: dim, height: dim, colorScheme: client.colorScheme, mixStyle: client.mixStyle,
              imageCallback: (img) => updateWidget(img),
          blackPOV: blackPOV, maxControl: client.maxControl);
    }
  }

  BoardMatrix? updateBoardToLatestPosition(MatrixClient client, {bool? freeze}) {
    return updateBoard(latestFEN,null,moves.last.whiteClock,moves.last.blackClock, client, freeze: freeze);
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc, MatrixClient client, {bool? freeze}) { //print("Updating: $id");
    if (lastMove != null && latestMove?.moveStr != lastMove.moveStr) { //print("Adding move: $lastMove");
      moves = moves.add(MoveState(lastMove, wc, bc, board?.fen, fen));
    }
    if (freeze != null) {
      isFrozen = freeze;
    } else if (isFrozen) {
      return board;
    }
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    int dim = min(client.matrixResolution,boardSize ?? 1024); //print("Dim: $dim");
    board = BoardMatrix(fen: fen,width: dim, height: dim, colorScheme: client.colorScheme, mixStyle: client.mixStyle,
        imageCallback: (img) => updateWidget(img), blackPOV: blackPOV, maxControl: client.maxControl);
    clockTimer = countDown();
    controller.loadFen(fen);
    return board;
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

}
