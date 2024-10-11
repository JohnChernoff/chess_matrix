import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'chess.dart';

typedef MoveSelectionCallback = void Function(MoveState state);

class MoveListWidget extends StatefulWidget {
  final IList<MoveState> moves;
  final Axis orientation;
  final double span;
  final MoveSelectionCallback? onTap;
  final MoveSelectionCallback? onDoubleTap;
  final MoveSelectionCallback? onLongPress;
  const MoveListWidget(this.moves,{this.orientation = Axis.vertical,this.span = 128, this.onTap, this.onDoubleTap, this.onLongPress, super.key});

  @override
  State<StatefulWidget> createState() => _MoveListWidgeState();

}

class _MoveListWidgeState extends State<MoveListWidget> {

  @override
  Widget build(BuildContext context) { //print("Orientation: ${widget.orientation}");
      return SizedBox(
        width: widget.orientation == Axis.vertical
            ? widget.span
            : null,
        height: widget.orientation == Axis.horizontal
            ? widget.span
            : null,
        child: widget.moves.isEmpty
            ? Container(color: Colors.brown)
            : GridView.count(
                scrollDirection: widget.orientation,
                crossAxisCount: 2,
                children: widget.moves.first.turn == ChessColor.black
                    ? ([getNullMove()] + getMoveWidgets())
                    : getMoveWidgets()));
  }

  Widget getNullMove() {
    return Container(color: Colors.black, child: const Center(child: Text("...",style: TextStyle(color: Colors.white))));
  }

  List<Widget> getMoveWidgets({startNum = 1}) {
    int moveNum = startNum;
    return List.generate(widget.moves.length, (movePly) {
      MoveState m = widget.moves[movePly];
      String turnStr = m.turn == ChessColor.white ? "${moveNum++}. " : "";
      return InkWell(
          onTap: () => widget.onTap?.call(m),
          onDoubleTap: () => widget.onDoubleTap?.call(m),
          onLongPress: () => widget.onLongPress?.call(m),
          child: Container(
            color: Colors.grey, child: Center(
            child: Text(turnStr + m.move.toString(),style: TextStyle(color: m.turn == ChessColor.white ? Colors.white : Colors.black))), //yellowAccent))),
        )
      );
    });
  }

}