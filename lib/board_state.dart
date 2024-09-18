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
  final MatrixClient client;
  int slot;
  bool get visible => client.visibleBoards.contains(this);

  BoardState(this.client,this.slot) {
    print("Initializing: $slot");
  }

  void updateState(id,String fen,whitePlayer,blackPlayer) {
    this.id = id;
    this.whitePlayer = whitePlayer;
    this.blackPlayer = blackPlayer;
    updateBoard(fen, null, 0, 0);
  }

  Timer countDown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (visible) {
        if (board?.turn == ChessColor.white) {
          whitePlayer?.nextTick();
        } else if (board?.turn == ChessColor.black) {
          blackPlayer?.nextTick();
        }
        updateWidget();
      }
      else {
        clockTimer?.cancel();
      }
    });
  }

  void updateWidget() {
    if (visible) notifyListeners();
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
    return other.slot - slot;
  }

}