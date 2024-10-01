import 'package:flutter/cupertino.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
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
  cb.ChessBoardController controller = cb.ChessBoardController();

  BoardState(this.slot);

  void initState(String id,String fen, Player whitePlayer,Player blackPlayer, MatrixClient client) {
    replacable = false;
    finished = false;
    this.id = id;
    this.whitePlayer = whitePlayer;
    this.blackPlayer = blackPlayer;
    updateBoard(fen, null, 0, 0, client);
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
    notifyListeners();
  }

  void refreshBoard(MatrixClient client) {
    BoardMatrix? bm = board;
    if (bm != null) {
      board = BoardMatrix(bm.fen,bm.lastMove,client.matrixResolution,client.matrixResolution,client.colorScheme,client.mixStyle,() => updateWidget(),maxControl: client.maxControl);
    }
  }

  BoardMatrix? updateBoard(final String fen, final Move? lastMove, final int wc, final int bc, MatrixClient client) { //print("Updating: $id");
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    board = BoardMatrix(fen,lastMove,client.matrixResolution,client.matrixResolution,client.colorScheme,client.mixStyle,() => updateWidget(),maxControl: client.maxControl);
    clockTimer = countDown();
    String longFEN = "$fen KQkq - 0 1"; //print("Long FEN: $longFEN");
    controller.loadFen(longFEN);
    return board;
  }

  @override
  int compareTo(BoardState other) {
    return  slot - other.slot;
  }

}