import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as chessboard;
import 'package:provider/provider.dart';
import 'board_state.dart';

class BoardWidget extends StatelessWidget {
  final int slot;
  final textStyle = const TextStyle(color: Colors.white);
  final bool showID = false; //true;
  final MatrixClient client;
  final double size;

  const BoardWidget(this.slot, this.size, this.client,{super.key});

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "[Widget: $slot]";
  }

  @override
  Widget build(BuildContext context) {
    BoardState state = context.watch<BoardState>(); //print(state); print(state.board); print("Building: $this");
    return state.board == null
          ? const SizedBox.shrink()
          : Column(children: [
              showID ? Text("$slot: ${state.toString()}",style: textStyle) : const SizedBox.shrink(),
              getPlayerBar(state, true),
              Expanded(
                  child: InkWell(
                    onDoubleTap: () {
                      if (!state.live) {
                        state.replacable = true;
                        client.loadTVGames();
                      }
                    },
                    onTap: () {
                      if (state.live && state.finished) {
                        client.closeLiveGame(state);
                      } else {
                        client.setSingleState(state);
                      }
                    },
                      child: getBoard(context, state),
                  )
              ),
              getPlayerBar(state, false),
            ]);
  }

  Text getPlayerBar(BoardState state, bool top) {
    if (state.blackPOV) top = !top;
    ChessColor playerColor = top ? ChessColor.black : ChessColor.white;
    Player? player = playerColor == ChessColor.black ? state.blackPlayer : state.whitePlayer;
    return Text(player.toString(), style: TextStyle(
        color: state.board?.turn == playerColor ? Colors.yellowAccent : Colors.white
    ));
  }

  Widget getBoard(BuildContext context, BoardState state) { //print("$slot -> Board FEN: ${state.board?.fen}");
    MatrixClient client = Provider.of(context, listen: false);
    return chessboard.ChessBoard(
      controller: state.controller,
      size: size,
      blackPieceColor: Colors.green,
      pieceSet: client.pieceStyle.name,
      dummyBoard: true,
      backgroundImage: state.finished ? null : state.board?.image, //TODO: hide when null
      onMove: (from, to, prom) =>
          client.sendMove(state.id, from, to, prom),
    );
  }

}


