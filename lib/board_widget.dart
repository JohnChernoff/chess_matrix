import 'dart:math';
import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:chess_matrix/move_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_state.dart';
import 'chess.dart';
import 'dialogs.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;

class BoardWidget extends StatefulWidget {
  final MatrixClient client;
  final double width,height;
  final bool singleBoard;

  const BoardWidget(this.client, this.width, this.height, {this.singleBoard = false, super.key});

  @override
  State<StatefulWidget> createState() => _BoardWidgetState();

}

class _BoardWidgetState extends State<BoardWidget> {
  TextStyle textStyle = const TextStyle(color: Colors.white);
  bool showID = false; //true;
  bool hidePieces = false;
  bool creatingGIF = false;
  double playerBarPercent = .05;

  @override
  Widget build(BuildContext context) {
    BoardState state = context.watch<BoardState>(); //print(state); print(state.board); print("Building: $this");
    Axis flexDirection = widget.width > widget.height ? Axis.horizontal : Axis.vertical;
    Axis listDirection = widget.height > widget.width ? Axis.horizontal : Axis.vertical;
    double span = listDirection == Axis.horizontal ? min(128,widget.height - state.currentSize) : min(128,widget.width - state.currentSize);
    return state.board == null ? const SizedBox.shrink() : widget.singleBoard ?
    SizedBox(width: widget.width, height: widget.height, child:
      Flex(direction: flexDirection, mainAxisAlignment: MainAxisAlignment.center,children: [
        MoveListWidget(state.moves, orientation: listDirection, span: span,
            onTap: (m) => state.updateBoard(m.afterFEN,null,m.whiteClock,m.blackClock,widget.client,freeze: false),
            onDoubleTap: (m) => state.updateBoard(m.afterFEN,null,m.whiteClock,m.blackClock,widget.client,freeze: true)),
        getBoardBox(state),
      ])) : getBoardBox(state);
  }

  void animatePlayback(BoardState state, {int speed = 50, int endPause = 1000}) async {
    state.isAnimating = true;
    int ply = 0;
    MoveState? m;
    while (state.moves.isNotEmpty && state.isAnimating) {
      await Future.delayed(Duration(milliseconds: speed));
      m = state.moves[ply]; //print("Updating board: $ply");
      state.updateBoard(m.afterFEN, null, m.whiteClock, m.blackClock, widget.client, freeze: true);
      if (++ply >= state.moves.length) {
        await Future.delayed(Duration(milliseconds: endPause));
        ply = 0;
      }
    }
    state.isAnimating = false;
    state.updateBoardToLatestPosition(widget.client, freeze: false);
  }

  Widget getBoardBox(BoardState state) {
    return SizedBox(width: state.currentSize as double, height: state.currentSize as double, child: Row(
      children: [
        Expanded(child: Column(children: [
          showID ? Text("${state.slot}: ${state.toString()}",style: textStyle) : const SizedBox.shrink(),
          getPlayerBar(state, true),
          Expanded(
              child: InkWell(
                onLongPress: () {
                  if (!state.isLive) {
                    state.replaceable = true; widget.client.loadTVGames();
                  }
                },
                onDoubleTap: () {
                  state.blackPOV = !state.blackPOV;
                  widget.client.updateView(updateBoards: true);
                },
                onTap: () {
                  if (state.isLive && state.finished) {
                    widget.client.closeLiveFinishedGames();
                  } else {
                    widget.client.setSingleState(state);
                  }
                },
                child: getBoard(state, showMove: widget.client.showMove),
              )
          ),
          getPlayerBar(state, false),
        ])),
        widget.singleBoard ? getBoardControls(state) : const SizedBox.shrink(),
      ],
    ));
  }

  Widget getBoardControls(BoardState state) {
    ChessColor playerColor = state.blackPOV ? ChessColor.black : ChessColor.white;
    return Column(children: [
      IconButton(color: Colors.white, icon: state.isAnimating ? const Icon(Icons.stop) : const Icon(Icons.cyclone),
          onPressed: () {
            if (state.isAnimating) {
              state.isAnimating = false;
            } else {
              animatePlayback(state);
            }
          }),
      IconButton(color: Colors.white, icon: Icon(hidePieces ? Icons.add_location : Icons.hide_image_outlined),
          onPressed: () => setState(() {
            hidePieces = !hidePieces;
          })),
      IconButton(color: Colors.white, icon: Icon(creatingGIF ? Icons.run_circle_outlined : Icons.gif),
          onPressed: () => GifDialog(context,widget.client,state).raise(),
          ),
      (state.userSide == playerColor) ? getResignButton(state) : const SizedBox.shrink(),
      (state.userSide == playerColor) ? getDrawButton(state) : const SizedBox.shrink(),
    ]);
  }

  Widget getPlayerBar(BoardState state, bool top) {
    if (state.blackPOV) top = !top;
    ChessColor playerColor = top ? ChessColor.black : ChessColor.white;
    Player? player = playerColor == ChessColor.black ? state.blackPlayer : state.whitePlayer;
    return Container(
        color: Colors.black,
        height: state.currentSize * playerBarPercent,
        child: FittedBox(child: Row(children: [
          Text(player.toString(), style: TextStyle(
              color: state.board?.turn == playerColor ? Colors.yellowAccent : Colors.white
          )),
        ],
        )
        ));
  }

  Widget getResignButton(BoardState state) {
    return IconButton(color: Colors.white, onPressed: () => widget.client.resign(state), icon: const Icon(Icons.flag));
  }

  Widget getDrawButton(BoardState state) {
    return IconButton(color: state.drawOffered ? Colors.lightGreenAccent : state.offeringDraw ? Colors.blue : Colors.grey,
        onPressed: () => widget.client.offerDraw(state), icon: const Icon(Icons.health_and_safety));
  }

  Widget getBoard(BoardState state, {showMove = false, showControl = false}) { //print("$slot -> Board FEN: ${state.board?.fen}");
    if (state.board?.fen == state.latestFEN && state.finalImage != null) {
      return state.finalImage!;
    }
    else {
      final client = Provider.of<MatrixClient>(context, listen: false);
      final lastMoveFrom = state.board?.lastMove?.moveStr.substring(0,2);
      final lastMoveTo = state.board?.lastMove?.moveStr.substring(2,4);
      final arrow = (showMove && lastMoveFrom != null && lastMoveTo != null) ?
        cb.BoardArrow(from: lastMoveFrom, to: lastMoveTo, color: const Color(0x55ffffff)) : null;
      final boardImg = state.board?.image ?? state.buffImg;
      final size = state.currentSize - (state.currentSize * playerBarPercent * 2);
      final board = cb.ChessBoard(
        boardOrientation: state.blackPOV ? cb.PlayerColor.black : cb.PlayerColor.white,
        controller: state.controller,
        size: size,
        blackPieceColor: client.colorScheme.blackPieceBlendColor,
        whitePieceColor: client.colorScheme.whitePieceBlendColor,
        gridColor: client.colorScheme.gridColor,
        pieceSet: client.pieceStyle.name,
        dummyBoard: true,
        arrows: arrow != null ? [arrow] : [],
        backgroundImage: boardImg,
        hidePieces: hidePieces,
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


