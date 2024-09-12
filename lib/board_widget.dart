import 'dart:async';
import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';

class BoardWidget extends StatefulWidget {
  final int width, height;
  final MatrixClient client;
  final String id;
  final int slot;

  const BoardWidget(this.client,this.id, this.slot, this.width, this.height, {super.key});

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "[$id]";
  }

  @override
  State<StatefulWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  bool active = false;
  BoardMatrix? board;

  @override
  void initState() {
    super.initState();
    widget.client.callbacks.putIfAbsent(widget.id, () => updateBoard);
  }

  void updateBoard(String fen) {
    board = BoardMatrix(widget.width,widget.height,fen,() => refreshBoard());
  }

  void refreshBoard() {
    if (mounted) {
      setState(() {
        active = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      width: (board?.width ?? 0) as double,
      height: (board?.height ?? 0) as double,
      child: board != null ? CustomPaint(
        painter: BoardPainter(widget.client,board!),
      ) : const SizedBox.shrink(),
    );
  }

}

class BoardPainter extends CustomPainter {
  final MatrixClient client;
  final BoardMatrix board;

  const BoardPainter(this.client,this.board);

  @override
  void paint(Canvas canvas, Size size) {
    if (board.image != null) {
      canvas.drawImage(board.image!,const Offset(0,0), Paint());
      paintPieces(canvas, size);
    }
  }

  void paintPieces(Canvas canvas, Size size) {
    double squareWidth = board.width / 8;
    double squareHeight = board.height / 8;
    //double pieceWidth = squareWidth/2; double pieceHeight = squareHeight/2;
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        double squareX = file * squareWidth;
        double squareY = rank * squareHeight;
        Piece p = board.getSquare(Coord(rank, file)).piece;
        if (p.type != PieceType.none &&
            client.pieceImages.containsKey(p.toString())) {
          double dx = squareX + squareHeight / 4,
              dy = squareY + squareHeight / 4;
          canvas.drawImage(
              client.pieceImages[p.toString()]!, Offset(dx, dy), Paint());
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is BoardPainter) {
      return oldDelegate.board.fen != board.fen;
    }
    return false;
  }


}
