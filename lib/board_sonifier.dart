import 'dart:async';
import 'dart:js' as js;
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';
import 'matrix_fields.dart';

enum InstrumentType {
  pawnMelody(Colors.white),
  knightMelody(Colors.orange),
  bishopMelody(Colors.pink),
  rookMelody(Colors.cyan),
  queenMelody(Colors.blue),
  kingMelody(Colors.amberAccent);
  final Color color;
  const InstrumentType(this.color);
}

const drums = [35,40,42,51,50,48,41,19];
const octave = 12;
const int minPitch = octave * 2;
const int maxPitch = octave * 7;

class BoardSonifier extends ChangeNotifier {
  static List<List<DefaultInstrument>> defaultEnsembles = [
    [
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.pizzStrings,.25),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.glockenspiel,.25),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.kalimba,.25),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.marimba,.25),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.celesta,.25),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.ocarina,.25)
    ],
    [
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.flute,0),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.viola,0),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.clarinet,0),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.frenchHorn,0),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.celesta,0),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.ocarina,0)
    ],
  ];
  bool audioReady = false;
  bool muted = true;
  bool drums = false;
  double masterVolume = .25;
  Completer? loadingInstrument;
  Completer? initializing;
  Map<String,Instrument> orchMap = {};
  List<String> soloList = [];
  MatrixClient client;

  BoardSonifier(this.client);

  Future<void> init(int ensembleNum) async {
    initializing = Completer();
    js.context.callMethod("initAudio", [initialized]);
    await initializing?.future;
    await loadEnsemble(defaultEnsembles[ensembleNum]);
    audioReady = true;
  }

  void initialized() {
      print("Audio Initialized");
      initializing?.complete();
  }

  Future<void> loadEnsemble(List<DefaultInstrument> ensemble) async {
    for (DefaultInstrument defInst in ensemble) { //print("Loading from ensemble: ${defInst.type.name},${defInst.patch.index}");
      await loadInstrument(defInst.type,Instrument(defInst.instrument.patch,level : defInst.instrument.level));
    }
  }

  Future<void> loadInstrument(InstrumentType type, Instrument i) async {
    orchMap.update(type.name, (value) => i, ifAbsent: () => i);
    loadingInstrument = Completer();
    js.context.callMethod("setInstrument",[type.name,i.patch.index,loaded]);
    return loadingInstrument?.future;
  }

  void loaded(String type,int patch) {
    MidiInstrument i = MidiInstrument.values.elementAt(patch);
    print("Loaded: $type: ${i.name}");
    //orchMap.update(type, (value) => i, ifAbsent: () => i);
    loadingInstrument?.complete(type);
  }

  void playNote(InstrumentType? type,int pitch,int duration,double volume) {
    if (type != null && audioReady && !muted && !isMuted(type) && isSoloed(type)) {
      js.context.callMethod("playNote",[type.name,0,pitch,duration,volume * masterVolume]);
    }
  }

  void playMelody(InstrumentType? type,int pitch,double volume) {
    if (type != null && audioReady && !muted && !isMuted(type) && isSoloed(type)) {
      js.context.callMethod("playMelody",[type.name,0,pitch,volume * masterVolume]);
    }
  }

  void toggleSolo(InstrumentType type) {
    orchMap[type.name]?.solo = !(orchMap[type.name]?.solo ?? false);
    soloList = orchMap.keys.where((t) => orchMap[t]?.solo ?? false).toList(growable: false);
    client.notifyListeners();
  }

  void toggleMute(InstrumentType type) {
    orchMap[type.name]?.mute = !(orchMap[type.name]?.mute ?? false);
    client.notifyListeners();
  }

  bool isSoloed(InstrumentType type) {
     return soloList.isEmpty || soloList.contains(type.name);
  }

  bool isMuted(InstrumentType type) {
    return orchMap[type.name]?.mute ?? false;
  }

}

class DefaultInstrument {
  InstrumentType type;
  Instrument instrument;
  DefaultInstrument(this.type,MidiInstrument defPatch,double defLevel) : instrument = Instrument(defPatch,level : defLevel);
}

class Instrument {
  MidiInstrument patch;
  double level;
  bool mute = false;
  bool solo = false;
  Instrument(this.patch,{ this.level = .5 });
}