import 'package:flutter/material.dart';
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


