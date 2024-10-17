import 'package:chess/chess.dart' hide Move;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:zug_chess/zug_chess.dart';
import '../board_state.dart';
import '../img_utils.dart';

class MatrixTests {
  static void gifTest() {
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
    ImgUtils.createGifFile(state, 800);
  }
}