import 'dart:convert';
import 'dart:math';
import 'package:chess_matrix/client.dart';
import 'board_matrix.dart';
import 'board_sonifier.dart';
import 'board_state.dart';

class TVHandler {
  final MatrixClient client;
  final BoardSonifier sonifier;

  TVHandler(this.client, this.sonifier);

  void handleMsg(String msg) { //print("Message: $msg");
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
            client.keyChange();
          }
          else {
            generatePieceNotes(piece,calcMoveDistance(lastMove).round(),piece.color == ChessColor.black ? lastMove.to.y : ranks - (lastMove.to.y));
            if (piece.type == PieceType.pawn) {
              generatePawnRhythms(matrix,false,piece.color);
            }
          }
        }
      } else if (type == 'finish') {
        print("Finished: $id");
        board.finished = true;
        client.loadTVGames();
      }
    }
  }

  InstrumentType? getPieceInstrument(Piece piece) {
    return switch(piece.type) {
      PieceType.none => null, //shouldn't occur
      PieceType.pawn => InstrumentType.pawnMelody,
      PieceType.knight => InstrumentType.knightMelody,
      PieceType.bishop => InstrumentType.bishopMelody,
      PieceType.rook => InstrumentType.rookMelody,
      PieceType.queen => InstrumentType.queenMelody,
      PieceType.king => InstrumentType.kingMelody,
    };
  }

  void generatePieceNotes(Piece piece, int distance, int yDist) {
    Instrument? pieceInstrument = sonifier.orchMap[getPieceInstrument(piece)];
    Instrument? mainInstrument = sonifier.orchMap[InstrumentType.mainMelody];
    if (pieceInstrument != null && mainInstrument != null) {
      double dur = (yDist+1)/4;
      int newPitch = sonifier.getNextPitch(pieceInstrument.currentPitch, piece.color == ChessColor.black ? -distance : distance, sonifier.currentChord);

      sonifier.masterTrack.addNoteEvent(sonifier.masterTrack.createNoteEvent(pieceInstrument,newPitch,dur,.5),MusicalElement.harmony);
      newPitch = sonifier.getNextPitch(mainInstrument.currentPitch, piece.color == ChessColor.black ? -distance : distance, sonifier.currentChord);
      sonifier.masterTrack.addNoteEvent(sonifier.masterTrack.createNoteEvent(mainInstrument,newPitch,dur,.5),MusicalElement.harmony);
    }
  }

  void generatePawnRhythms(BoardMatrix board, bool realTime, ChessColor color, {drumVol = .25, compVol = .33, crossRhythm=false}) { //print("Generating pawn rhythm map...");
    Instrument? i = sonifier.orchMap[InstrumentType.mainRhythm];
    if (i != null) {
      sonifier.masterTrack.newRhythmMap.clear();
      double duration = sonifier.masterTrack.maxLength ?? 2;
      double halfDuration = duration / 2;
      double dur = duration / ranks;
      for (int beat = 0; beat < files; beat++) {
        for (int steps = 0; steps < ranks; steps++) {
          Piece compPiece = crossRhythm ? board.getSquare(Coord(steps,beat)).piece : board.getSquare(Coord(beat,steps)).piece;
          Piece drumPiece = crossRhythm ? board.getSquare(Coord(beat,steps)).piece : board.getSquare(Coord(steps,beat)).piece;
          if (compPiece.type == PieceType.pawn) { // && p.color == color) {
            double t = (beat/files) * duration;
            int pitch = sonifier.getNextPitch(sonifier.currentChord.key.index + (octave * 4), steps, sonifier.currentChord);
            sonifier.masterTrack.newRhythmMap.add(sonifier.masterTrack.createNoteEvent(i, pitch, dur, compVol, offset: t));
          }
          if (drumPiece.type == PieceType.pawn) {
            double t = (beat/files) * halfDuration;
            int pitch = 60;
            if (steps < sonifier.drumMap.values.length) {
              sonifier.masterTrack.newRhythmMap.add(sonifier.masterTrack.createNoteEvent(sonifier.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: t));
              sonifier.masterTrack.newRhythmMap.add(sonifier.masterTrack.createNoteEvent(sonifier.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: halfDuration + t));
            }
          }
        }
      }
    }
  }

  void handleMidiComplete() {
    print("Track finished"); //sonifier.playAllTracks();
  }

  double calcMoveDistance(Move move) {
    return sqrt(pow((move.from.x - move.to.x),2) + pow((move.from.y - move.to.y),2));
  }

}