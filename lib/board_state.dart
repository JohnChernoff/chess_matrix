//import 'package:chess/chess.dart' as dc;
import 'package:flutter/cupertino.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'dart:async';
import 'board_matrix.dart';
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
      board = BoardMatrix(bm.fen,bm.lastMove,client.matrixResolution,client.matrixResolution,client.colorScheme,client.mixStyle,() => updateWidget(),
          blackPOV: blackPOV, maxControl: client.maxControl);
    }
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc, MatrixClient client) { //print("Updating: $id");
    if (lastMove != null) moves = moves.add(MoveState(lastMove, wc, bc));
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    board = BoardMatrix(fen,lastMove,client.matrixResolution,client.matrixResolution,client.colorScheme,client.mixStyle,() => updateWidget(),
        blackPOV: blackPOV, maxControl: client.maxControl);
    clockTimer = countDown();
    controller.loadFen(fen);
    return board;
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

}

class MoveState {
  final Move move;
  final int whiteClock, blackClock;
  final bool isCheck, isCapture, isCastle, isEP, isProm;
  MoveState(this.move,this.whiteClock,this.blackClock,{this.isCheck = false, this.isCapture = false, this.isCastle = false, this.isEP = false, this.isProm = false});
}