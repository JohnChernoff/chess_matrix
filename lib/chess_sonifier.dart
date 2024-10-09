import 'dart:math';
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
  MidiTrack masterTrack = MidiTrack("Master",maxLength: 2);

  ChessSonifier(this.client);

  MidiChessPlayer? getPieceInstrument(Piece piece) {
    return switch(piece.type) {
      PieceType.none => null, //shouldn't occur
      PieceType.pawn => MidiChessPlayer.pawnMelody,
      PieceType.knight => MidiChessPlayer.knightMelody,
      PieceType.bishop => MidiChessPlayer.bishopMelody,
      PieceType.rook => MidiChessPlayer.rookMelody,
      PieceType.queen => MidiChessPlayer.queenMelody,
      PieceType.king => MidiChessPlayer.kingMelody,
    };
  }

  void generatePieceNotes(Piece piece, Move move, int yDist) {
    int distance = calcMoveDistance(move).round();
    Instrument? pieceInstrument = midi.orchMap[getPieceInstrument(piece)?.name];
    Instrument? mainInstrument = midi.orchMap[MidiChessPlayer.mainMelody.name];
    if (pieceInstrument != null && mainInstrument != null) {
      double dur = (yDist+1)/4;
      int newPitch = midi.getNextPitch(pieceInstrument.currentPitch, piece.color == ChessColor.black ? -distance : distance, midi.currentChord);

      masterTrack.addNoteEvent(masterTrack.createNoteEvent(pieceInstrument,newPitch,dur,.5),elem: TrackElement.realtimeHarmony);
      newPitch = midi.getNextPitch(mainInstrument.currentPitch, piece.color == ChessColor.black ? -distance : distance, midi.currentChord);
      masterTrack.addNoteEvent(masterTrack.createNoteEvent(mainInstrument,newPitch,dur,.5),elem: TrackElement.realtimeHarmony);
    }
  }

  void generatePawnRhythms(BoardMatrix board, bool realTime, ChessColor color, {drumVol = .25, compVol = .33, crossRhythm=false}) { //print("Generating pawn rhythm map...");
    Instrument? i = midi.orchMap[MidiChessPlayer.mainRhythm.name];
    if (i != null) {
      masterTrack.newMasterMap.clear();
      double duration = masterTrack.maxLength ?? 2;
      double halfDuration = duration / 2;
      double dur = duration / ranks;
      for (int beat = 0; beat < files; beat++) {
        for (int steps = 0; steps < ranks; steps++) {
          Piece compPiece = crossRhythm ? board.getSquare(Coord(steps,beat)).piece : board.getSquare(Coord(beat,steps)).piece;
          Piece drumPiece = crossRhythm ? board.getSquare(Coord(beat,steps)).piece : board.getSquare(Coord(steps,beat)).piece;
          if (compPiece.type == PieceType.pawn) { // && p.color == color) {
            double t = (beat/files) * duration;
            int pitch = midi.getNextPitch(midi.currentChord.key.index + (octave * 4), steps, midi.currentChord);
            masterTrack.newMasterMap.add(masterTrack.createNoteEvent(i, pitch, dur, compVol, offset: t));
          }
          if (drumPiece.type == PieceType.pawn) {
            double t = (beat/files) * halfDuration;
            int pitch = 60;
            if (steps < midi.drumMap.values.length) {
              masterTrack.newMasterMap.add(masterTrack.createNoteEvent(midi.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: t));
              masterTrack.newMasterMap.add(masterTrack.createNoteEvent(midi.drumMap.values.elementAt(steps), pitch, dur, drumVol, offset: halfDuration + t));
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
    midi.loopTrack(masterTrack);
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

}
