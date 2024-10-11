import 'dart:math';

import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:chess_matrix/move_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:provider/provider.dart';
import 'board_state.dart';
import 'chess.dart';

class BoardWidget extends StatelessWidget {
  final textStyle = const TextStyle(color: Colors.white);
  final bool showID = false; //true;
  final MatrixClient client;
  final double playerBarPercent = .05;
  final double width,height;
  final bool singleBoard;

  const BoardWidget(this.client, this.width, this.height, {this.singleBoard = false, super.key});

  @override
  Widget build(BuildContext context) {
    BoardState state = context.watch<BoardState>(); //print(state); print(state.board); print("Building: $this");
    Axis flexDirection = width > height ? Axis.horizontal : Axis.vertical;
    Axis listDirection = height > width ? Axis.horizontal : Axis.vertical;
    double span = listDirection == Axis.horizontal ? min(128,height - state.currentSize) : min(128,width - state.currentSize);
    return state.board == null ? const SizedBox.shrink() : singleBoard ?
      SizedBox(width: width, height: height, child:
      Flex(direction: flexDirection, mainAxisAlignment: MainAxisAlignment.center,children: [
            MoveListWidget(state.moves, orientation: listDirection, span: span,
                onTap: (m) => state.updateBoard(m.afterFEN,null,m.whiteClock,m.blackClock,client,freeze: false),
                onDoubleTap: (m) => state.updateBoard(m.afterFEN,null,m.whiteClock,m.blackClock,client,freeze: true)),
            getBoardBox(context, state), //getBoardBox(context, state),
          ]))
     : getBoardBox(context, state);
  }

  void animatePlayback(BoardState state, {int speed = 50, int endPause = 1000}) async {
    state.isAnimating = true;
    int ply = 0;
    MoveState? m;
    while (state.moves.isNotEmpty && state.isAnimating) {
      await Future.delayed(Duration(milliseconds: speed));
      m = state.moves[ply]; //print("Updating board: $ply");
      state.updateBoard(m.afterFEN, null, m.whiteClock, m.blackClock, client, freeze: true);
      if (++ply >= state.moves.length) {
        await Future.delayed(Duration(milliseconds: endPause));
        ply = 0;
      }
    }
    state.isAnimating = false;
    state.updateBoardToLatestPosition(client, freeze: false);
  }

  Widget getBoardBox(BuildContext context, BoardState state) {
    return SizedBox(width: state.currentSize as double, height: state.currentSize as double, child: Column(children: [
      showID ? Text("${state.slot}: ${state.toString()}",style: textStyle) : const SizedBox.shrink(),
      getPlayerBar(state, true),
      Expanded(
          child: InkWell(
            onLongPress: () {
              if (!state.isLive) {
                animatePlayback(state); //state.replaceable = true; client.loadTVGames();
              }
            },
            onDoubleTap: () {
              state.blackPOV = !state.blackPOV;
              client.updateView(updateBoards: true);
            },
            onTap: () {
              if (state.isAnimating) {
                state.isAnimating = false;
              }
              else if (state.isLive && state.finished) {
                client.closeLiveGame(state);
              } else {
                client.setSingleState(state);
              }
            },
            child: getBoard(context, state, showMove: client.showMove),
          )
      ),
      getPlayerBar(state, false),
    ]));
  }

  Widget getPlayerBar(BoardState state, bool top) {
    if (state.blackPOV) top = !top;
    ChessColor playerColor = top ? ChessColor.black : ChessColor.white;
    Player? player = playerColor == ChessColor.black ? state.blackPlayer : state.whitePlayer;
    return Container(
        color: Colors.black,
        height: state.currentSize * playerBarPercent,
        child: FittedBox(child: Row(children: [
              (state.playing == playerColor) ? getResignButton(state) : const SizedBox.shrink(),
              (state.playing == playerColor) ? getDrawButton(state) : const SizedBox.shrink(),
              Text(player.toString(), style: TextStyle(
                color: state.board?.turn == playerColor ? Colors.yellowAccent : Colors.white
            )),
          ],
        )
    ));
  }

  Widget getResignButton(BoardState state) {
    return IconButton(color: Colors.white, onPressed: () => client.resign(state), icon: const Icon(Icons.flag));
  }

  Widget getDrawButton(BoardState state) {
    return IconButton(color: state.drawOffered ? Colors.lightGreenAccent : state.offeringDraw ? Colors.blue : Colors.grey,
        onPressed: () => client.offerDraw(state), icon: const Icon(Icons.health_and_safety));
  }

  Widget getBoard(BuildContext context, BoardState state, {showMove = false, showControl = false}) { //print("$slot -> Board FEN: ${state.board?.fen}");
    MatrixClient client = Provider.of(context, listen: false);
    String? from =  state.board?.lastMove?.moveStr.substring(0,2);
    String? to =  state.board?.lastMove?.moveStr.substring(2,4);
    final arrow = (showMove && from != null && to != null) ? cb.BoardArrow(from: from, to: to, color: const Color(0x55ffffff)) : null;
    final board = cb.ChessBoard(
      boardOrientation: state.blackPOV ? cb.PlayerColor.black : cb.PlayerColor.white,
      controller: state.controller,
      size: state.currentSize - (state.currentSize * playerBarPercent * 2),
      blackPieceColor: client.colorScheme.blackPieceBlendColor,
      whitePieceColor: client.colorScheme.whitePieceBlendColor,
      gridColor: client.colorScheme.gridColor,
      pieceSet: client.pieceStyle.name,
      dummyBoard: true,
      arrows: arrow != null ? [arrow] : [],
      backgroundImage: state.board?.image ?? state.buffImg, //TODO: hide when null
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


