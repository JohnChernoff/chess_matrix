import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_state.dart';
import 'board_sonifier.dart';

class BoardWidget extends StatelessWidget {
  final int slot;
  const BoardWidget(this.slot, {super.key});

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "[Widget: $slot]";
  }

  Text getPlayerBar(BoardState state, bool top) {
    if (state.blackPOV) top = !top;
    ChessColor playerColor = top ? ChessColor.black : ChessColor.white;
    Player? player = playerColor == ChessColor.black ? state.blackPlayer : state.whitePlayer;
    return Text(player.toString(), style: TextStyle(
        color: state.board?.turn == playerColor ? Colors.yellowAccent : Colors.white
    ));
  }

  @override
  Widget build(BuildContext context) {
    //BoardState state = context.watch<BoardState>();
    print("Building: $this");
    return Consumer<BoardState>(
        builder: (BuildContext context, BoardState state, Widget? child) {
          print(state);
          print(state.board);
      return state.board == null
          ? const SizedBox.shrink()
          : Column(children: [
              getPlayerBar(state, true),
              Expanded(
                  child: AspectRatio(
                      aspectRatio: 1, child: getBoard(context, state))),
              getPlayerBar(state, false),
            ]);
    });
  }

  Widget getBoard(BuildContext context,BoardState state) {
    //print("$slot -> Board FEN: ${state.board?.fen}");
    MatrixClient client = Provider.of(context,listen: false);
    return InkWell(
      onTap: () {
        client.sonifier.playNote(InstrumentType.pawnMelody, 80, 8, .5);
        state.replacable = true;
        client.loadTVGames();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            state.board?.image != null ? CustomPaint(
              painter: BoardPainter(client,state.board!),
            ) : const SizedBox.shrink(),
            getBoardPieces(state.board!,Colors.brown,client.blackPieceColor,MatrixClient.pieceStyle.name),
            client.showControl ? getBoardControl(state.board!) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget getBoardPieces(BoardMatrix board, Color borderColor, Color blackPieceColor, String pieceStyle) {
    return GridView.count(
      crossAxisCount: 8,
      children: List.generate(64, (index) {
        Coord squareCoord = Coord(index % 8, (index / 8).floor());
        Piece piece = board.getSquare(squareCoord).piece;
        BlendMode? blendMode = piece.color == ChessColor.white ? null : BlendMode.modulate;
        Color? color = piece.color == ChessColor.white ? null : blackPieceColor;
        return Container(
          decoration:
          BoxDecoration(border: Border.all(color: borderColor, width: 1)),
          child: (piece.type != PieceType.none)
              ? Image.asset("assets/images/pieces/$pieceStyle/${piece.toString(white: true)}.png",colorBlendMode: blendMode, color: color)
              : const SizedBox.shrink(),
        );
      }),
    );
  }

  Widget getBoardControl(BoardMatrix board) {
    return GridView.count(
      crossAxisCount: 8,
      children: List.generate(64, (index) {
        Coord squareCoord = Coord(index % 8, (index / 8).floor());
        return SizedBox(
            child: Text(board.getSquare(squareCoord).control.toString(),
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

