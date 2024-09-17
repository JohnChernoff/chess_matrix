import 'dart:async';
import 'package:chess_matrix/board_matrix.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board_sonifier.dart';

class BoardWidget extends StatelessWidget {
  final MatrixClient client;
  final int slot;
  final BoardState state;
  const BoardWidget(this.client, this.state, this.slot, {super.key});

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "[$slot : ${state.id}]";
  }

  Text getPlayerBar(bool top) {
    if (state.blackPOV) top = !top;
    ChessColor playerColor = top ? ChessColor.black : ChessColor.white;
    Player? player = playerColor == ChessColor.black ? state.blackPlayer : state.whitePlayer;
    return Text(player.toString(), style: TextStyle(
        color: state.board?.turn == playerColor ? Colors.yellowAccent : Colors.white
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!context.mounted) return const SizedBox.shrink();
    context.watch<BoardState>();
    print("Board FEN: ${state.board?.fen}");
    return state.board == null || state.finished || !state.active
        ? const SizedBox.shrink()
        : Column(children: [
            getPlayerBar(true),
            Expanded(
                child: AspectRatio(aspectRatio: 1, child: getBoard(state.board!))),
            getPlayerBar(false),
          ]);
  }

  Widget getBoard(BoardMatrix board) {
    return InkWell(
      onTap: () {
        client.sonifier.playNote(InstrumentType.pawnMelody, 80, 8, .5);
        state.finished = true;
        client.loadTVGames();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            board.image != null ? CustomPaint(
              painter: BoardPainter(client,board),
            ) : const SizedBox.shrink(),
            getBoardPieces(board,Colors.brown),
            client.showControl ? getBoardControl(board) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget getBoardPieces(BoardMatrix board, Color borderColor) {
    return GridView.count(
      crossAxisCount: 8,
      children: List.generate(64, (index) {
        Coord squareCoord = Coord(index % 8, (index / 8).floor());
        Piece piece = board.getSquare(squareCoord).piece;
        BlendMode? blendMode = piece.color == ChessColor.white ? null : BlendMode.modulate;
        Color? color = piece.color == ChessColor.white ? null : client.blackPieceColor;
        return Container(
          decoration:
          BoxDecoration(border: Border.all(color: borderColor, width: 1)),
          child: (piece.type != PieceType.none)
              ? Image.asset("assets/images/pieces/${client.pieceStyle.name}/${piece.toString(white: true)}.png",colorBlendMode: blendMode, color: color)
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

class BoardState extends ChangeNotifier {
  String? id;
  Player? whitePlayer,blackPlayer;
  bool finished = false;
  bool active = false;
  bool blackPOV = false;
  BoardMatrix? board;
  Timer? clockTimer;
  MatrixClient client;

  BoardState(this.client,this.id,this.whitePlayer,this.blackPlayer) {
    print("Initializing: $id");
  }

  void updateState(id,whitePlayer,blackPlayer) {
    this.id = id;
    this.whitePlayer = whitePlayer;
    this.blackPlayer = blackPlayer;
    active = true;
  }

  Timer countDown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (active) {
        if (board?.turn == ChessColor.white) {
          whitePlayer?.nextTick();
        } else if (board?.turn == ChessColor.black) {
          blackPlayer?.nextTick();
        }
        updateWidget();
      }
      else {
        clockTimer?.cancel();
      }
    });
  }

  void updateWidget() {
    notifyListeners();
  }

  BoardMatrix? updateBoard(String fen,Move? lastMove, int wc, int bc) { //print("Updating: $id");
    clockTimer?.cancel();
    whitePlayer?.clock = wc;
    blackPlayer?.clock = bc;
    board = BoardMatrix(fen,lastMove,client.width,client.height,() => updateWidget(),colorStyle: client.colorStyle);
    clockTimer = countDown();
    return board;
  }

}

