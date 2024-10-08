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

  const BoardWidget(this.slot, this.size, this.client, {super.key});

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
                    onLongPress: () {
                      if (!state.live) {
                        state.replacable = true;
                        client.loadTVGames();
                      }
                    },
                    onDoubleTap: () {
                      state.blackPOV = !state.blackPOV;
                      client.updateView(updateBoards: true);
                    },
                    onTap: () {
                      if (state.live && state.finished) {
                        client.closeLiveGame(state);
                      } else {
                        client.setSingleState(state);
                      }
                    },
                      child: getBoard(context, state, showMove: client.showMove),
                  )
              ),
              getPlayerBar(state, false),
              (state.live) ? Row(children: [
                IconButton(onPressed: () => client.resign(state), icon: const Icon(Icons.flag)),
                IconButton(onPressed: () => client.offerDraw(state), icon: const Icon(Icons.health_and_safety))
              ]) : const SizedBox.shrink()
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

  Widget getBoard(BuildContext context, BoardState state, {showMove = false, showControl = false}) { //print("$slot -> Board FEN: ${state.board?.fen}");
    MatrixClient client = Provider.of(context, listen: false);
    String? from =  state.board?.lastMove?.moveStr.substring(0,2);
    String? to =  state.board?.lastMove?.moveStr.substring(2,4);
    final arrow = (showMove && from != null && to != null) ? chessboard.BoardArrow(from: from, to: to, color: const Color(0x55ffffff)) : null;
    final board = chessboard.ChessBoard(
      boardOrientation: state.blackPOV ? chessboard.PlayerColor.black : chessboard.PlayerColor.white,
      controller: state.controller,
      size: size,
      blackPieceColor: client.colorScheme.blackPieceBlendColor,
      whitePieceColor: client.colorScheme.whitePieceBlendColor,
      gridColor: client.colorScheme.gridColor,
      pieceSet: client.pieceStyle.name,
      dummyBoard: true,
      arrows: arrow != null ? [arrow] : [],
      backgroundImage: state.finished ? null : state.board?.image ?? state.buffImg, //TODO: hide when null
      onMove: (from, to, prom) =>
          client.sendMove(state.id, from, to, prom),
    );
    if (showControl) {
      return Stack(fit: StackFit.expand, children: [board, getBoardControl(state.board!)]);
    }
    else {
      return board;
    }
  }

  Widget getBoardControl(BoardMatrix board) {
    return GridView.count(
      crossAxisCount: 8,
      children: List.generate(64, (index) {
        Coord squareCoord = Coord(index % 8, (index / 8).floor());
        Square square = board.getSquare(squareCoord);
        return SizedBox(
            child: Text("${square.control.toString()}:${square.piece.toString()}",
                style: const TextStyle(color: Colors.yellowAccent))
        );
      }),
    );
  }

}


