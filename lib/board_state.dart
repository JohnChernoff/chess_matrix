import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'board_matrix.dart';
import 'client.dart';

class BoardState extends ChangeNotifier implements Comparable<BoardState> {
  String? id;
  Player? whitePlayer,blackPlayer;
  bool finished = false;
  bool replacable = true;
  bool blackPOV = false;
  BoardMatrix? board;
  Timer? clockTimer;
  int slot;

  BoardState(this.slot);
  BoardState.fromTV(this.slot,this.id,String fen,this.whitePlayer,this.blackPlayer) {
    updateBoard(fen, null, 0, 0);
  }

  @override
  String toString() {
      return "$slot: $id";
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
    //print("Updating: $id");
    //print("Has listeners: $hasListeners");
    notifyListeners();
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc) { //print("Updating: $id");
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    board = BoardMatrix(fen,lastMove,MatrixClient.matrixWidth,MatrixClient.matrixHeight,() => updateWidget(),colorStyle: MatrixClient.colorStyle);
    clockTimer = countDown();
    return board;
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

}