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
                      child: chessboard.ChessBoard(controller: state.controller,size: size,
                          dummyBoard: true,
                          backgroundImage: state.board?.image,
                          onMove: (from, to, prom) => client.sendMove(state.id ?? "", from, to, prom),
                      ),
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

  Widget getBoard(BuildContext context,BoardState state) { //print("$slot -> Board FEN: ${state.board?.fen}");
    MatrixClient client = Provider.of(context,listen: false);
    return InkWell(
      onDoubleTap: () {
        state.replacable = true;
        client.loadTVGames();
      },
      onTap: () {
        client.setSingleState(state);
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            state.board?.image != null ? CustomPaint(
              painter: BoardPainter(client,state),
            ) : const SizedBox.shrink(),
            getBoardPieces(state.board!,Colors.brown,client.blackPieceColor,client.pieceStyle.name),
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
  final BoardState state;

  const BoardPainter(this.client,this.state);

  @override
  void paint(Canvas canvas, Size size) { //print("Size: $size");
    BoardMatrix? board = state.board;
    if (board != null && board.image != null) {
      canvas.scale(
          size.width  / board.width,
          size.height / board.height
      );
      canvas.drawImage(board.image!,const Offset(0,0), Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

}

