import 'dart:js' as js;
import 'dart:async';
import 'dart:math';
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
  kingMelody(Colors.amberAccent),
  mainMelody(Colors.deepPurple);
  final Color color;
  const InstrumentType(this.color);
}

const octave = 12;
const int minPitch = octave * 2;
const int maxPitch = octave * 7;
enum MidiNote { noteC,noteDb,noteD,noteEb,noteE,noteF,noteGb,noteG,noteAb,noteA,noteBb,noteB }
enum MidiScale {
  majorScale([2,2,1,2,2,2,1]),
  naturalMinorScale([2,1,2,2,1,2,2]),
  bluesScale([3,2,1,1,3,2]);
  final List<int> intervals;
  const MidiScale(this.intervals);
}

class BoardSonifier extends ChangeNotifier {

  static List<List<DefaultInstrument>> defaultEnsembles = [
    [
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.pizzStrings,.25),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.glockenspiel,.25),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.kalimba,.25),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.marimba,.25),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.celesta,.25),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.ocarina,.25),
      DefaultInstrument(InstrumentType.mainMelody,MidiInstrument.xylophone,.25),
    ],
    [
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.acousticGrandPiano,0),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.timpani,0),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.clarinet,0),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.trumpet,0),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.viola,0),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.ocarina,0),
      DefaultInstrument(InstrumentType.mainMelody,MidiInstrument.electricGuitarClean,0),
    ],
  ];
  final drums = [MidiDrum.bassDrum1,MidiDrum.snareDrum2,MidiDrum.closedHiHat,MidiDrum.rideCymbal1,MidiDrum.highTom1,MidiDrum.highTom2,MidiDrum.lowTom2,MidiDrum.tambourine];
  bool audioReady = false;
  bool muted = true;
  bool playing = false;
  double masterVolume = .25;
  Completer? loadingPatch;
  Completer? initializing;
  Map<InstrumentType,Instrument> orchMap = {};
  Map<InstrumentType,MidiTrack> tracks = {};
  MidiTrack rhythmTrack = MidiTrack("rhythm");
  InstrumentType lead = InstrumentType.mainMelody;
  InstrumentType rhythm = InstrumentType.pawnMelody;
  MatrixClient client;
  KeyChord currentChord = KeyChord(MidiNote.noteA, MidiScale.majorScale);

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
    //looper(rhythmTrack);
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
    orchMap.update(type, (value) => i, ifAbsent: () => i);
    loadingPatch = Completer();
    js.context.callMethod("setInstrument",[i.patch.name,i.patch.index,loadedInstrument]);
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

  void playChord(Instrument? i,double t, List<int> chord, double duration,double volume) {
    for (int pitch in chord) {
      playNote(i, t, pitch, duration, volume);
    }
  }

  void playNote(Instrument? i,double t, int pitch, double duration,double volume) {
    if (i != null && audioReady && !muted && !i.mute && isSoloed(i)) {
      js.context.callMethod("playNote",[i.patch.name,t,pitch,duration,volume * masterVolume]);
    }
  }

  void playMelody(Instrument? i,int pitch,double volume) {
    if (i != null && audioReady && !muted && !i.mute && isSoloed(i)) {
      js.context.callMethod("playMelody",[i.patch.name,0,pitch,volume * masterVolume]);
    }
  }

  void toggleSolo(Instrument i) {
    i.solo = !i.solo;
    client.notifyListeners();
  }

  void toggleMute(Instrument i) {
    i.mute = !i.mute;
    client.notifyListeners();
  }

  bool isSoloed(Instrument i) {
    Iterable<Instrument> soloists = orchMap.values.where((instrument) => instrument.solo);
    return (soloists.contains(i) || soloists.isEmpty);
  }

  bool isMuted(Instrument i) {
    return i.mute;
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
    //rhythmTrack.playTrack(this);
    for (MidiTrack track in tracks.values) {
      track.play(this,(track) {});
    }
    int playLength = tracks.values.reduce((value,element) => value.currentTime > element.currentTime ? value : element).currentTime.round();
    for (MidiTrack track in tracks.values) { track.clearTrack(); }
    Future.delayed(Duration(seconds: playLength), () { playing = false; client.handleMidiComplete(); }); //print("Waiting $playLength seconds");
  }

  void initTracks() {
    tracks.clear();
    for (InstrumentType it in InstrumentType.values) {
      tracks.putIfAbsent(it, () => MidiTrack(it.name));
    }
  }

  static int calcScaleDegree(int pitch, KeyChord chord) { //int degreeInC = pitch % octave;
     for (int degree=0,p=chord.key.index; degree < chord.scale.intervals.length; p+=chord.scale.intervals[degree++]) { //print("Comparing: $pitch,$p");
       if (samePitch(pitch,p)) return degree;
     }
     return -1;
  }

  static bool samePitch(int p1, int p2) {
    return (p1 % octave) == (p2 % octave);
  }

  static MidiNote getNote(int pitch) {
    return MidiNote.values[pitch % octave];
  }

  int getNextPitch(int pitch, int steps, KeyChord chord) {
    int newPitch = pitch;
    int scaleDir = steps < 0 ? -1 : 1;
    int degree = calcScaleDegree(pitch, chord);
    if (degree < 0) return pitch + steps;
    //print("Pitch: $pitch, Note: ${getNote(pitch)}, Degree: $degree");
    for (int step = 0; step < steps.abs(); step++) {
      if (scaleDir > 0) {
        newPitch += (chord.scale.intervals[degree] * scaleDir);
      }
      degree += scaleDir;
      if (degree >= chord.scale.intervals.length) {
        degree = 0;
      } else if (degree < 0) {
        degree = chord.scale.intervals.length-1;
      }
      if (scaleDir < 0) {
        newPitch += (chord.scale.intervals[degree] * scaleDir);
      }
    }
    //print("$pitch,$steps -> $newPitch (${MidiNote.values[newPitch % octave].name})");
    return newPitch;
  }

  void looper(MidiTrack track) {
    track.play(this, (track) => looper(track));
  }

}

class KeyChord {
  MidiNote key;
  MidiScale scale;
  KeyChord(this.key,this.scale);
}

class MidiTrack implements Comparable<MidiTrack> {
  String name;
  bool playing = false;
  List<MidiEvent> track = [];
  MidiTrack(this.name);
  double currentTime = 0;
  int? currentPitch;

  Future<void> play(BoardSonifier player,dynamic onFinished,{immediately = true}) async {
    if (immediately) {
      for (var midiEvent in track) { print("Playing: $midiEvent on $name");
        player.playNote(midiEvent.instrument,midiEvent.offset, midiEvent.pitch, midiEvent.duration,midiEvent.volume);
      }
      print("Waiting: $currentTime seconds...");
      Future.delayed(Duration(milliseconds: max(1000,(currentTime * 1000).round()))).then((value) => onFinished(this));
    }
    else { //print("Starting: $name");
      if (track.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1000));
        return;
      }
      playing = true;
      while (playing) {
        double prevOffset = track.first.offset;
        for (var midiEvent in track) {
          int millis = ((midiEvent.offset - prevOffset) * 1000).round(); //print("Playing: $midiEvent on $name for $millis millis");
          await Future.delayed(Duration(milliseconds: millis));
          player.playNote(midiEvent.instrument, 0, midiEvent.pitch, midiEvent.duration, midiEvent.volume);
          prevOffset = midiEvent.offset;
        }
      }
      playing = false;
      onFinished(this);
    }
  }

  void addRest(Instrument instrument,double duration) {
    //addNoteEvent(instrument,0,duration,0);
    currentTime += duration;
  }

  void addNoteEvent(Instrument instrument, int pitch, double duration, double volume) {
    currentPitch = pitch < maxPitch && pitch > minPitch ? pitch : 60;
    MidiEvent e = MidiEvent(instrument, currentPitch!, currentTime, duration, volume);
    track.add(e); //print("Adding: $e");
    currentTime += duration;
  }

  void addChordEvent(Instrument instrument, List<int> pitches, double duration, double volume) {
    int? firstPitch = pitches.first;
    currentPitch = firstPitch < maxPitch && firstPitch > minPitch ? firstPitch : 60;
    for (int pitch in pitches) {
      MidiEvent e = MidiEvent(instrument, pitch, currentTime, duration, volume);
      track.add(e); //print("Adding: $e");
    }
    currentTime += duration;
  }

  void clearTrack() {
    track.clear();
    currentTime = 0;
  }

  @override
  int compareTo(MidiTrack other) {
    return currentTime.compareTo(currentTime);
  }

}

class MidiEvent implements Comparable<MidiEvent> {
  Instrument instrument;
  int pitch;
  double offset;
  double duration;
  double volume;
  MidiEvent(this.instrument,this.pitch,this.offset,this.duration,this.volume);
  @override
  String toString() {
    return "[instrument: ${instrument.patch.name}, note: ${BoardSonifier.getNote(pitch)}, pitch: $pitch, offset: $offset, duration: $duration, volume: $volume]";
  }

  @override
  int compareTo(MidiEvent other) {
    return offset.compareTo(other.offset);
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

