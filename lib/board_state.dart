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

  void initState(String id,String fen, Player whitePlayer,Player blackPlayer, MatrixColorScheme colorScheme, int maxControl) {
    this.id = id;
    this.whitePlayer = whitePlayer;
    this.blackPlayer = blackPlayer;
    updateBoard(fen, null, 0, 0, colorScheme,maxControl);
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
    notifyListeners();
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc, MatrixColorScheme colorScheme, int maxControl) { //print("Updating: $id");
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    board = BoardMatrix(fen,lastMove,MatrixClient.matrixWidth,MatrixClient.matrixHeight,colorScheme,() => updateWidget(),maxControl: maxControl);
    clockTimer = countDown();
    return board;
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

}