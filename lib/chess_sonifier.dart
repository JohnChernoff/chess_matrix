import 'dart:math';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'board_matrix.dart';
import 'chess.dart';
import 'client.dart';
import 'matrix_fields.dart';
import 'midi_manager.dart';

enum MidiChessPlayer {
  pawnMelody(Colors.white),
  knightMelody(Colors.orange),
  bishopMelody(Colors.pink),
  rookMelody(Colors.cyan),
  queenMelody(Colors.blue),
  kingMelody(Colors.amberAccent),
  mainMelody(Colors.deepPurple),
  mainRhythm(Colors.red);
  final Color color;
  const MidiChessPlayer(this.color);
}

List<List<MidiAssignment>> defaultEnsembles = [
  [
    MidiAssignment(MidiChessPlayer.pawnMelody.name,MidiInstrument.dulcimer,.25),
    MidiAssignment(MidiChessPlayer.knightMelody.name,MidiInstrument.glockenspiel,.25),
    MidiAssignment(MidiChessPlayer.bishopMelody.name,MidiInstrument.kalimba,.25),
    MidiAssignment(MidiChessPlayer.rookMelody.name,MidiInstrument.marimba,.25),
    MidiAssignment(MidiChessPlayer.queenMelody.name,MidiInstrument.celesta,.25),
    MidiAssignment(MidiChessPlayer.kingMelody.name,MidiInstrument.ocarina,.25),
    MidiAssignment(MidiChessPlayer.mainMelody.name,MidiInstrument.acousticGrandPiano,.25),
    MidiAssignment(MidiChessPlayer.mainRhythm.name,MidiInstrument.pizzStrings,.25),
  ],
  [
    MidiAssignment(MidiChessPlayer.pawnMelody.name,MidiInstrument.electricBassPick,0),
    MidiAssignment(MidiChessPlayer.knightMelody.name,MidiInstrument.timpani,0),
    MidiAssignment(MidiChessPlayer.bishopMelody.name,MidiInstrument.clarinet,0),
    MidiAssignment(MidiChessPlayer.rookMelody.name,MidiInstrument.trumpet,0),
    MidiAssignment(MidiChessPlayer.queenMelody.name,MidiInstrument.fx3Crystal,0),
    MidiAssignment(MidiChessPlayer.kingMelody.name,MidiInstrument.pad8Sweep,0),
    MidiAssignment(MidiChessPlayer.mainMelody.name,MidiInstrument.overdrivenGuitar,0),
    MidiAssignment(MidiChessPlayer.mainRhythm.name,MidiInstrument.acousticGrandPiano,.25),
  ],
];

class ChessSonifier {
  MatrixClient client;
  MidiManager midi = MidiManager();
  MidiTrack loopTrack = MidiTrack("LoopTrack",maxLength: 2);
  MidiTrack gameTrack = MidiTrack("GameTrack"); //int n = 0;

  ChessSonifier(this.client);

  MidiChessPlayer? getPieceInstrument(Piece? piece) {
    return switch(piece?.type ?? PieceType.none) {
      PieceType.none => null, //shouldn't occur
      PieceType.pawn => MidiChessPlayer.pawnMelody,
      PieceType.knight => MidiChessPlayer.knightMelody,
      PieceType.bishop => MidiChessPlayer.bishopMelody,
      PieceType.rook => MidiChessPlayer.rookMelody,
      PieceType.queen => MidiChessPlayer.queenMelody,
      PieceType.king => MidiChessPlayer.kingMelody,
    };
  }

  int getMoveInterval(Piece piece, Move move) {
    int distance = calcMoveDistance(move).round();
    return piece.color == ChessColor.black ? -distance : distance;
  }

  List<MidiEvent> getMoveMidiEvents(MidiTrack track, MidiChessPlayer? player, Piece? piece, Move move, {double tempo = .25, xRest = false, yRest = false}) {
    List<MidiEvent> events = []; if (piece == null) return events;
    int yDist = piece.color == ChessColor.black ? move.to.y : ranks - (move.to.y);
    Instrument? i = midi.orchMap[player?.name];
    if (i != null) {
      int newPitch = midi.getNextPitch(i.currentPitch, getMoveInterval(piece, move), midi.currentChord);
      events.add(track.createNoteEvent(i, newPitch, (yDist + 1) * tempo, .5));
      if (xRest) {
        int xRestDist = piece.color == ChessColor.black ? move.to.x : files - (move.to.x);
        events.add(track.createRestEvent(i, (xRestDist + 1) * tempo));
      }
      else if (yRest) {
        int yRestDist = piece.color == ChessColor.black ? move.from.x : files - (move.from.x);
        events.add(track.createRestEvent(i, (yRestDist + 1) * tempo/8));
      }
    }
    return events;
  }

  void generatePieceNotes(Piece piece, Move move) {
    if (!gameTrack.playing) {
      MidiEvent? e = getMoveMidiEvents(loopTrack,getPieceInstrument(piece),piece,move).firstOrNull;
      if (e != null) loopTrack.addNoteEvent(e,elem: TrackElement.realtimeHarmony);
      MidiEvent? e2 = getMoveMidiEvents(loopTrack,MidiChessPlayer.mainMelody,piece,move).firstOrNull;
      if (e2 != null) loopTrack.addNoteEvent(e2,elem: TrackElement.realtimeHarmony);
    }
  }

  void generatePawnRhythms(BoardMatrix board, bool realTime, ChessColor color, {drumVol = .25, compVol = .33, crossRhythm=false}) { //print("Generating pawn rhythm map...");
    Instrument? i = midi.orchMap[MidiChessPlayer.mainRhythm.name];
    if (!gameTrack.playing && i != null) {
      loopTrack.newMasterMap.clear();
      double duration = loopTrack.maxLength ?? 2;
      double dur = duration / ranks;
      for (int beat = 0; beat < files; beat++) {
        for (int steps = 0; steps < ranks; steps++) {
          Piece compPiece = crossRhythm ? board.getSquare(Coord(steps,beat)).piece : board.getSquare(Coord(beat,steps)).piece;
          Piece drumPiece = crossRhythm ? board.getSquare(Coord(beat,steps)).piece : board.getSquare(Coord(steps,beat)).piece;
          if (compPiece.type == PieceType.pawn) { // && p.color == color) {
            double t = (beat/files) * duration;
            int pitch = midi.getNextPitch(midi.currentChord.key.index + (octave * 4), steps, midi.currentChord);
            loopTrack.newMasterMap.add(loopTrack.createNoteEvent(i, pitch, dur, compVol, offset: t));
          }
          if (drumPiece.type == PieceType.pawn) {
            double halfDuration = duration / 2;
            double t = (beat/files) * halfDuration;
            int pitch = 60;
            if (steps < midi.drumMap.values.length) {
              loopTrack.newMasterMap.add(loopTrack.createNoteEvent(midi.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: t));
              loopTrack.newMasterMap.add(loopTrack.createNoteEvent(midi.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: halfDuration + t));
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

  void toggleAudio() {
    midi.muted = !midi.muted;
    if (!midi.muted && !midi.audioReady) {
      initAudio();
    } else {
      client.updateView();
    }
  }

  void toggleDrums() {
    midi.muteDrums = !midi.muteDrums;
    client.updateView();
  }

  Future<void> initAudio() async { print("Loading audio");
    await midi.init(defaultEnsembles.first);
    loopTrack.play(midi,looping: true); //midi.loopTrack(loopTrack);
    client.updateView();
  }

  void loadInstrument(MidiPerformer perf, MidiInstrument patch) async {
    await midi.loadInstrument(perf, Instrument(iPatch: patch)); //TODO: levels
    client.updateView(); //todo: avoid redundancy when calling via initAudio?
  }

  Future<void> loadRandomEnsemble() async {
    await midi.loadEnsemble(midi.randomEnsemble(MidiChessPlayer.values.map((v) => v.name).toList()));
    client.updateView();
  }

  void keyChange() { //print("Key change!");
    midi.currentChord = KeyChord(
        MidiManager.getNewNote(midi.currentChord.key),
        MidiManager.getNewScale(midi.currentChord.scale));
    client.updateView();
  }

  Future<void> playGame(IList<MoveState> moves) async {
    loopTrack.stop();
    for (MoveState move in moves) { //final MidiChessPlayer? player = getPieceInstrument(move.piece);
      print("${move.piece} -> ${move.move}");
      for (MidiEvent e in getMoveMidiEvents(gameTrack, MidiChessPlayer.mainRhythm, move.piece, move.move, tempo: .05, yRest: true)) {
        print("Note Event: $e");
        gameTrack.addNoteEvent(e);
      }
    }
    await gameTrack.play(midi, looping: false);
    loopTrack.play(midi,looping: true);
  }

}
