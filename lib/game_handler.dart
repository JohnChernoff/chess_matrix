import 'dart:convert';
import 'package:chess_matrix/client.dart';
import 'package:chess_matrix/main.dart';
import 'board_matrix.dart';
import 'board_state.dart';
import 'chess.dart';
import 'chess_sonifier.dart';
import 'package:chess/chess.dart' as dc;

class GameHandler {
  final MatrixClient client;
  final ChessSonifier sonifier;

  GameHandler(this.client, this.sonifier);

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
      } else if (type == 'finish') { mainLogger.i("Finished: $id, result: ${json.toString()}"); //print(json);
        board.setResult(data['win'] == 'w', data['win'] == 'b',client);
        Future.delayed(const Duration(seconds: 5)).then((v) => client.loadTVGames()); //TODO: check for already queued reload
      }
    }
  }

  void followStream(Stream<String> eventStream) {
    mainLogger.f("Event: $eventStream");
    String? token = client.lichessToken; if (token == null) { return; }
    eventStream.listen((data) {
      if (data.trim().isNotEmpty) { mainLogger.f('Event Chunk: $data');
        dynamic json = jsonDecode(data);
        String type = json["type"];
        if (type == "gameStart") {
          dynamic game = json['game']; String id = game['gameId'];
          dynamic whitePlayer = game['color'] == 'white' ? {'id' : client.userInfo['username'], 'rating' : client.getRatingByType(game['speed'])} : game['opponent'];
          dynamic blackPlayer = game['color'] == 'black' ? {'id' : client.userInfo['username'], 'rating' : client.getRatingByType(game['speed'])} : game['opponent'];
          BoardState state = BoardState.newGame(client.playBoards.length,id,Player.fromSeek(whitePlayer),Player.fromSeek(blackPlayer),client,
              initialFEN: startFEN,
              userSide: game['color'] == 'white' ? ChessColor.white : ChessColor.black,
              blackPOV: (game['color'] == 'black'),
          );
          //state.newGame(id,startFEN,Player.fromSeek(whitePlayer),Player.fromSeek(blackPlayer),client);
          client.playBoards = client.playBoards.add(state);
          client.lichessClient.followGame(id,token,followLiveGame);
          client.updateView();
        }
        else if (type == 'gameFinish') { //mainLogger.i("Game over: $data");
          dynamic game = json['game']; String id = game['gameId'];
          BoardState? state = client.playBoards.where((state) => state.id == id).firstOrNull;
          //state?.drawn = true;
          if (json['status'] == 'draw') {
            state?.setStatus(BoardStatus.draw,client);
          } else if (json['winner'] != null) {
            state?.setResult(json['winner'] == 'white', json['winner'] == 'black',client);
          }
        }
      }
    });
  }

  void followLiveGame(String gid, Stream<String> gameStream) {
    mainLogger.f("Following Game: $gid");
    gameStream.listen((data) {
      if (data.trim().isNotEmpty) {
        //print('Game Chunk: $data');
        for (String chunk in data.split("\n")) {
          if (chunk.isNotEmpty) {
            dynamic json =
                jsonDecode(chunk.trim()); //print('JSON Chunk: $json');
            BoardState? board =
                client.playBoards.where((state) => state.id == gid).firstOrNull;
            if (board != null) {
              String type =
                  json['type']; //print("Game Event Type: $type : $json");
              if (type == 'chatLine') {
                //board.drawOffered = true;
              } else {
                bool? wdraw = json['wdraw'], bdraw = json['bdraw'];
                if (wdraw ?? false) {
                  if (board.userSide == ChessColor.black) {
                    board.drawOffered = true; //!board.drawOffered;
                  } else {
                    board.offeringDraw = true;
                  }
                } else if (bdraw ?? false) {
                  if (board.userSide == ChessColor.white) {
                    board.drawOffered = true; //!board.drawOffered;
                  } else {
                    board.offeringDraw = true;
                  }
                } else {
                  board.offeringDraw = false;
                  board.drawOffered = false;
                }
                //board.drawOffered = false;
                dynamic state = type == 'gameState'
                    ? json
                    : type == 'gameFull'
                        ? json['state']
                        : null;
                if (state != null) { //print("State: $state");
                  List<String> moves = state['moves'].trim().split(" ");
                  if (moves.length > 1) {
                    bool refreshMoves = board.moves.isEmpty;
                    dc.Chess chess = dc.Chess.fromFEN(startFEN);
                    for (String m in moves) {
                      Move move = Move(m);
                      String beforeFEN = chess.fen;
                      chess.move(move.toJson());
                      if (refreshMoves) board.moves = board.moves.add(MoveState(move, 0, 0, beforeFEN, chess.fen)); //TODO: create move add method
                    }
                    String lastMove = moves[moves.length - 1];
                    board.updateBoard(
                        chess.fen,
                        !refreshMoves && lastMove.length > 3 ? Move(lastMove) : null,
                        ((state['wtime'] ?? 0) / 1000).floor(),
                        ((state['btime'] ?? 0) / 1000).floor(),
                        client);
                  }
                }
              }
            }
          }
        }
      }
    });
  }
}