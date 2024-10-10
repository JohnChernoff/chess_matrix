import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'dart:async';
import 'board_matrix.dart';
import 'chess.dart';
import 'client.dart';
import 'dart:ui' as ui;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class BoardState extends ChangeNotifier implements Comparable<BoardState> {
  String? id;
  String? initialFEN;
  Player? whitePlayer,blackPlayer;
  bool finished = false;
  bool replacable = true;
  bool blackPOV = false;
  BoardMatrix? board;
  Timer? clockTimer;
  int slot;
  bool live;
  ui.Image? buffImg;
  IList<MoveState> moves = IList<MoveState>();
  cb.ChessBoardController controller = cb.ChessBoardController();
  int? boardSize;

  BoardState(this.slot, this.live);

  void initState(String id,String fen, Player whitePlayer,Player blackPlayer, MatrixClient client) {
    replacable = false;
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
      return "$slot: $id, fin: $finished, rep: $replacable";
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

  void refreshBoard(MatrixClient client) {
    BoardMatrix? bm = board;
    if (bm != null) {
      int dim = min(client.matrixResolution,boardSize ?? 1000);
      board = BoardMatrix(bm.fen,bm.lastMove,dim,dim,client.colorScheme,client.mixStyle,() => updateWidget(),
          blackPOV: blackPOV, maxControl: client.maxControl);
    }
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc, MatrixClient client) { //print("Updating: $id");
    if (lastMove != null) moves = moves.add(MoveState(lastMove, wc, bc, board?.fen, fen));
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    int dim = min(client.matrixResolution,boardSize ?? 1000); //print("Dim: $dim");
    board = BoardMatrix(fen,lastMove,dim,dim,client.colorScheme,client.mixStyle,() => updateWidget(), blackPOV: blackPOV, maxControl: client.maxControl);
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
        imgCall: () => updateWidget(),
      );
      print("Cumulative Board: $board");
    }
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

}

