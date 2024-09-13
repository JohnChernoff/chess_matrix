import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';

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
  String? lastMove;
  int? whiteClock;
  int? blackClock;

  @override
  void initState() {
    super.initState();
    widget.client.updaters.putIfAbsent(widget, () => updateBoard);
  }

  void updateBoard(String fen, String lm, int wc, int bc) { //print("FEN: $fen");
    whiteClock = wc; blackClock = bc; lastMove = lm;
    board = BoardMatrix(fen,widget.client.width,widget.client.height,() => refreshBoard());
  }

  void refreshBoard() {
    if (mounted) {
      setState(() {
        active = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) { //print("Board FEN: ${board?.fen}");
    BoardState? state = widget.client.boards[widget];
    TextStyle textStyle = const TextStyle(color: Colors.white);
    return Column(
      children: [
        Text(state?.whitePlayer.toString() ?? "?", style: textStyle),
        Expanded(child: AspectRatio(aspectRatio: 1, child: getBoard(state))),
        Text(state?.blackPlayer.toString() ?? "?", style: textStyle),
    ]);
  }

  Widget getBoard(BoardState? state) {
    return InkWell(
      onTap: () {
        state?.finished = true;
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
            GridView.count(
              crossAxisCount: 8,
              children: List.generate(64,(index) {
                Piece piece = board!.getSquare(
                    Coord((index / 8).floor(),index % 8)).piece;
                return Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 1)
                  ),
                  child: (piece.type != PieceType.none) ? Image.asset("assets/images/${piece.toString()}.png") : const SizedBox.shrink(),
                );
              }
              ),
            )
          ],
        ) : const SizedBox.shrink(),
      ),
    );
  }
}

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
      return oldDelegate.board.image != null && oldDelegate.board.fen != board.fen;
    }
    return false;
  }


}
