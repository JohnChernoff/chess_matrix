import 'dart:convert';
import 'package:chess_matrix/client.dart';
import 'package:chess_matrix/main.dart';
import 'board_matrix.dart';
import 'board_state.dart';
import 'chess.dart';
import 'chess_sonifier.dart';

class TVHandler {
  final MatrixClient client;
  final ChessSonifier sonifier;

  TVHandler(this.client, this.sonifier);

  void handleMsg(msg) { //print("Message: $msg");
    dynamic json = jsonDecode(msg);
    String type = json['t'];
    dynamic data = json['d'];
    String id = data['id'] ?? "";
    BoardState? board = client.getBoardByID(id);
    if (board != null) {
      if (type == "fen") {
        int whiteClock = int.parse(data['wc'].toString());
        int blackClock = int.parse(data['bc'].toString());
        Move lastMove = Move(data['lm']);
        String fen = data['fen']; //print("FEN: $fen");
        String fullFEN = "$fen - - 0 1"; //print("Full FEN: $fullFEN");
        BoardMatrix? matrix = board.updateBoard(fullFEN, lastMove, whiteClock, blackClock, client);
        if (matrix != null) {
          Piece piece = matrix.getSquare(lastMove.to).piece; //print("LastMove: ${lastMove.from}-${lastMove.to}, piece: ${piece.type}");
          if (piece.type == PieceType.none) {  //print("castling?!");
            client.sonifier.keyChange();
          }
          else {
            sonifier.generatePieceNotes(piece,lastMove);
            if (piece.type == PieceType.pawn) {
              sonifier.generatePawnRhythms(matrix,false,piece.color);
            }
          }
        }
      } else if (type == 'finish') { mainLogger.i("Finished: $id");
        board.finished = true;
        client.loadTVGames();
      }
    }
  }



}