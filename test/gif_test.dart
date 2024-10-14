import 'package:chess/chess.dart' hide Move;
import 'package:chess_matrix/board_state.dart';
import 'package:chess_matrix/chess.dart';
import 'package:chess_matrix/client.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GIF Test', (WidgetTester tester) async {
    gifTest();
  });
}

Future<void> gifTest() async {
  MatrixClient client = MatrixClient('lichess.org');
  BoardState state = BoardState.empty(0);
  state.moves = const IList.empty();
  String prevFEN;
  Chess chess = Chess();
  prevFEN = chess.fen; chess.move("e4");
  state.moves = state.moves.add(MoveState(Move("e2e4"), 0, 0, prevFEN, chess.fen));
  prevFEN = chess.fen; chess.move("e5");
  state.moves = state.moves.add(MoveState(Move("e7e5"), 0, 0, prevFEN, chess.fen));
  prevFEN = chess.fen; chess.move("Nf3");
  state.moves = state.moves.add(MoveState(Move("g1f3"), 0, 0, prevFEN, chess.fen));
  client.createGifFile(state, 480);
}