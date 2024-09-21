import 'dart:js' as js;
import 'dart:async';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';
import 'board_matrix.dart';
import 'matrix_fields.dart';

const List<double> rhythmMap = [.125,.25,.5,.75,1,1.25,1.5,2];

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
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.acousticGrandPiano,0),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.distortionGuitar,0),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.clarinet,0),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.trumpet,0),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.viola,0),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.ocarina,0)
    ],
  ];
  final drums = [MidiDrum.bassDrum1,MidiDrum.snareDrum2,MidiDrum.closedHiHat,MidiDrum.rideCymbal1,MidiDrum.highTom1,MidiDrum.highTom2,MidiDrum.lowTom2,MidiDrum.tambourine];
  bool audioReady = false;
  bool muted = true;
  bool playing = false;
  double masterVolume = .25;
  Completer? loadingPatch;
  Completer? initializing;
  Map<String,Instrument> orchMap = {};
  Map<InstrumentType,MidiTrack> tracks = {};
  List<String> soloList = [];
  MatrixClient client;

  BoardSonifier(this.client) {
    initTracks();
  }

  Future<void> init(int ensembleNum) async {
    initializing = Completer();
    js.context.callMethod("initAudio", [initialized]);
    await initializing?.future;
    await loadEnsemble(defaultEnsembles[ensembleNum]);
    //await loadDrumKit(drums);
    audioReady = true;
  }

  void initialized() { //
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
    loadingPatch = Completer();
    js.context.callMethod("setInstrument",[type.name,i.patch.index,loadedInstrument]);
    return loadingPatch?.future;
  }

  void loadedInstrument(String type,int patch) {
    MidiInstrument i = MidiInstrument.values.elementAt(patch);
    print("Loaded: $type: ${i.name}"); //orchMap.update(type, (value) => i, ifAbsent: () => i);
    loadingPatch?.complete(type);
  }

  Future<void> loadDrumKit(List<MidiDrum> kit) async {
    for (MidiDrum drum in kit) {
      await loadDrum(drum);
    }
  }

  Future<void> loadDrum(MidiDrum drum) async {
    loadingPatch = Completer();
    js.context.callMethod("setDrumKit",[drum.name,drum.patchNum,loadedDrum]);
    return loadingPatch?.future;
  }

  void loadedDrum(String type,int patch) {
    print("Loaded: $type");
    loadingPatch?.complete(type);
  }

  void playDrum(MidiDrum drum,double t, double duration, double volume) {
    if (audioReady) {
      js.context.callMethod("playDrum",[drum.name,t,duration,volume * masterVolume]);
    }
  }

  void playNote(InstrumentType? type,double t, int pitch, double duration,double volume) {
    if (type != null && audioReady && !muted && !isMuted(type) && isSoloed(type)) {
      js.context.callMethod("playNote",[type.name,t,pitch,duration,volume * masterVolume]);
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

  void playDrumTrack(BoardMatrix board, {offset = 0, tempo = 8}) {
    for (int beat = 0; beat < ranks; beat++) {
      for (int patch = 0; patch < files; patch++) {
        Square square = board.getSquare(Coord(beat,patch));
        if (square.piece.type == PieceType.pawn) {
          double v =square.control.abs() / board.maxControl;
          playDrum(drums[patch],(beat/tempo) + offset,1/tempo,v);
        }
      }
    }
  }

  void playAllTracks() {
    playing = true;
    for (MidiTrack track in tracks.values) {
      track.playTrack(this);
    }
    int playLength = tracks.values.reduce((value,element) => value._currentTime > element._currentTime ? value : element)._currentTime.round();
    for (MidiTrack track in tracks.values) { track.clearTrack(); }
    Future.delayed(Duration(seconds: playLength), () { playing = false; client.handleMidiComplete(); }); //print("Waiting $playLength seconds");
  }

  void initTracks() {
    tracks.clear();
    for (InstrumentType it in InstrumentType.values) {
      tracks.putIfAbsent(it, () => MidiTrack(it));
    }
  }

}

class MidiTrack implements Comparable<MidiTrack> {
  InstrumentType instrument;
  List<MidiEvent> track = [];
  MidiTrack(this.instrument);
  double _currentTime = 0;
  int? currentPitch;
  void playTrack(BoardSonifier player) {
    for (var midiEvent in track) { //print("Playing: $midiEvent on $instrument");
      player.playNote(instrument,midiEvent.offset, midiEvent.pitch, midiEvent.duration,midiEvent.volume);
    }
  }

  void addNoteEvent(int pitch, double duration, double volume) {
    currentPitch = pitch < maxPitch && pitch > minPitch ? pitch : 60;
    MidiEvent e = MidiEvent(currentPitch!, _currentTime, duration, volume);
    track.add(e); //print("Adding: $e");
    _currentTime += duration;
  }

  void clearTrack() {
    track.clear();
    _currentTime = 0;
  }

  @override
  int compareTo(MidiTrack other) {
    return (_currentTime - other._currentTime).round();
  }

}

class MidiEvent {
  int pitch;
  double offset;
  double duration;
  double volume;
  MidiEvent(this.pitch,this.offset,this.duration,this.volume);
  @override
  String toString() {
    return "[pitch: $pitch, offset: $offset, duration: $duration, volume: $volume]";
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