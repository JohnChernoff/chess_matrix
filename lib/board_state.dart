import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'board_matrix.dart';
import 'chess.dart';
import 'client.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'main.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'dart:ui' as ui;

enum BoardStatus {
  whiteWon,blackWon,draw,abort,playing,none
}

class BoardState extends ChangeNotifier implements Comparable<BoardState> {
  final int slot;
  final String? id;
  final String initialFEN;
  final Player? whitePlayer,blackPlayer;
  final int? whiteStartTime, blackStartTime;
  final cb.ChessBoardController controller = cb.ChessBoardController();
  final ChessColor userSide;
  IList<MoveState> moves = IList<MoveState>();
  BoardStatus status = BoardStatus.none;
  bool replaceable = true;
  bool blackPOV = false;
  BoardMatrix? board;
  Timer? clockTimer;
  ui.Image? buffImg;
  int? boardSize;
  bool isFrozen = false;
  bool isAnimating = false;
  bool drawOffered = false, offeringDraw = false;
  bool get isLive => userSide != ChessColor.none;
  int get currentSize => boardSize ?? 0;
  bool get isOpen => !isAnimating && (replaceable || finished);
  bool get finished => (status != BoardStatus.playing);

  BoardState.empty(this.slot, { this.id, this.initialFEN = startFEN, this.whitePlayer, this.blackPlayer, this.whiteStartTime, this.blackStartTime, this.userSide = ChessColor.none} );
  BoardState.newGame(this.slot,this.id, this.whitePlayer, this.blackPlayer, MatrixClient client, { this.initialFEN = startFEN, this.userSide = ChessColor.none, this.blackPOV = false,
    this.whiteStartTime, this.blackStartTime, this.replaceable = false, this.status = BoardStatus.playing, Move? lastMove }) {
    updateBoard(initialFEN, lastMove, whiteStartTime ?? 0, blackStartTime ?? 0, client);
  }

  void setResult(bool whiteWin, bool blackWin) {
    if (whiteWin) {
      status = BoardStatus.whiteWon;
    } else if (blackWin) {
      status = BoardStatus.blackWon;
    }
    else {
      status =  BoardStatus.draw;
    }
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
    if (lastMove != null && board?.lastMove != lastMove) { //print("Adding move: $lastMove");
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
    int dim = min(client.matrixResolution,boardSize ?? 1000); //print("Dim: $dim");
    board = BoardMatrix(fen,lastMove,dim,dim,client.colorScheme,client.mixStyle,(img) => updateWidget(), blackPOV: blackPOV, maxControl: client.maxControl);
    clockTimer = countDown();
    controller.loadFen(fen);
    return board;
  }

  void generateCumulativeControlBoard() {
    final currentBoard = board;
    if (currentBoard != null) {
      BoardMatrix bm = BoardMatrix.fromSquares(moves.first.beforeFEN ?? initialFEN, BoardMatrix.createSquares());
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

}
