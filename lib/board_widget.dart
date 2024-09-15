import 'dart:async';
import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';

import 'board_sonifier.dart';

class BoardWidget extends StatefulWidget {
  final MatrixClient client;
  final int slot;
  const BoardWidget(this.client, this.slot, {super.key});

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "[$slot : ${client.boards[this]?.id}]";
  }

  @override
  State<StatefulWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  bool active = false;
  BoardMatrix? board;
  Timer? clockTimer;

  @override
  void initState() {
    super.initState();
    widget.client.updaters.putIfAbsent(widget, () => updateBoard);
  }

  BoardState? getBoardState() {
    return widget.client.boards[widget];
  }

  Timer countDown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        clockTimer?.cancel();
      }
      else {
        if (active) {
          BoardState? boardState = getBoardState();
          if (board?.turn == ChessColor.white) {
            setState(() {
              boardState?.whitePlayer.nextTick();
            });
          } else if (board?.turn == ChessColor.black) {
            setState(() {
              boardState?.blackPlayer.nextTick();
            });
          }
        }
      }
    });
  }

  BoardMatrix? updateBoard(String fen,Move? lastMove, int wc, int bc) { //print("FEN: $fen");
    clockTimer?.cancel();
    BoardState? boardState = getBoardState();
    boardState?.whitePlayer.clock = wc;
    boardState?.blackPlayer.clock = bc;
    board = BoardMatrix(fen,lastMove,widget.client.width,widget.client.height,() => refreshBoard(),colorStyle: widget.client.colorStyle);
    clockTimer = countDown();
    return board;
  }

  void refreshBoard() {
    if (mounted) {
      setState(() {
        active = true;
      });
    }
  }

  Text getPlayerBar(bool top) {
    BoardState? boardState = getBoardState();
    if (boardState != null) {
      if (boardState.blackPOV) top = !top;
      ChessColor playerColor = top ? ChessColor.black : ChessColor.white;
      Player player = playerColor == ChessColor.black ? boardState.blackPlayer : boardState.whitePlayer;
      return Text(player.toString(), style: TextStyle(
        color: board?.turn == playerColor ? Colors.yellowAccent : Colors.white
      ));
    }
    return const Text("?");
  }

  @override
  Widget build(BuildContext context) { //print("Board FEN: ${board?.fen}");
    return Column(
      children: [
        getPlayerBar(true),
        Expanded(child: AspectRatio(aspectRatio: 1, child: getBoard())),
        getPlayerBar(false),
    ]);
  }

  Widget getBoard() {
    return InkWell(
      onTap: () {
        widget.client.sonifier.playNote(InstrumentType.pawnMelody, 80, 8, .5);
        getBoardState()?.finished = true;
        widget.client.loadTVGames();
      },
      child: Container(
        color: Colors.black,
        child: board != null ? Stack(
          fit: StackFit.expand,
          children: [
            board!.image != null ? CustomPaint(
              painter: BoardPainter(widget.client,board!),
            ) : const SizedBox.shrink(),
            getBoardPieces(Colors.brown),
            widget.client.showControl ? getBoardControl() : const SizedBox.shrink(),
          ],
        ) : const SizedBox.shrink(),
      ),
    );
  }

  Widget getBoardPieces(Color borderColor) {
    return GridView.count(
      crossAxisCount: 8,
      children: List.generate(64, (index) {
        Coord squareCoord = Coord(index % 8, (index / 8).floor());
        Piece piece = board!.getSquare(squareCoord).piece;
        BlendMode? blendMode = piece.color == ChessColor.white ? null : BlendMode.modulate;
        Color? color = piece.color == ChessColor.white ? null : widget.client.blackPieceColor;
        return Container(
          decoration:
              BoxDecoration(border: Border.all(color: borderColor, width: 1)),
          child: (piece.type != PieceType.none)
              ? Image.asset("assets/images/pieces/${widget.client.pieceStyle.name}/${piece.toString(white: true)}.png",colorBlendMode: blendMode, color: color)
              : const SizedBox.shrink(),
        );
      }),
    );
  }

  Widget getBoardControl() {
    return GridView.count(
      crossAxisCount: 8,
      children: List.generate(64, (index) {
        Coord squareCoord = Coord(index % 8, (index / 8).floor());
        return SizedBox(
          child: Text(board!.getSquare(squareCoord).control.toString(),
          style: const TextStyle(color: Colors.yellowAccent))
        );
      }),
    );
  }
}

//TODO: draw last move
class BoardPainter extends CustomPainter {
  final MatrixClient client;
  final BoardMatrix board;

  const BoardPainter(this.client,this.board);

  @override
  void paint(Canvas canvas, Size size) { //print("Size: $size");
    if (board.image != null) {
      canvas.scale(
          size.width  / board.width,
          size.height / board.height
      );
      canvas.drawImage(board.image!,const Offset(0,0), Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is BoardPainter) {
      return oldDelegate.board.image != null && (oldDelegate.board.fen != board.fen || oldDelegate.board.colorStyle != board.colorStyle);
    }
    return false;
  }


}
