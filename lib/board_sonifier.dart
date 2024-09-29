import 'dart:js' as js;
import 'dart:async';
import 'dart:math';
import 'package:chess_matrix/client.dart';
import 'package:flutter/material.dart';
import 'matrix_fields.dart';

enum InstrumentType {
  pawnMelody(Colors.white),
  knightMelody(Colors.orange),
  bishopMelody(Colors.pink),
  rookMelody(Colors.cyan),
  queenMelody(Colors.blue),
  kingMelody(Colors.amberAccent),
  mainMelody(Colors.deepPurple),
  mainRhythm(Colors.red);
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
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.dulcimer,.25),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.glockenspiel,.25),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.kalimba,.25),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.marimba,.25),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.celesta,.25),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.ocarina,.25),
      DefaultInstrument(InstrumentType.mainMelody,MidiInstrument.acousticGrandPiano,.25),
      DefaultInstrument(InstrumentType.mainRhythm,MidiInstrument.pizzStrings,.25),
    ],
    [
      DefaultInstrument(InstrumentType.pawnMelody,MidiInstrument.electricBassPick,0),
      DefaultInstrument(InstrumentType.knightMelody,MidiInstrument.timpani,0),
      DefaultInstrument(InstrumentType.bishopMelody,MidiInstrument.clarinet,0),
      DefaultInstrument(InstrumentType.rookMelody,MidiInstrument.trumpet,0),
      DefaultInstrument(InstrumentType.queenMelody,MidiInstrument.fx3Crystal,0),
      DefaultInstrument(InstrumentType.kingMelody,MidiInstrument.pad8Sweep,0),
      DefaultInstrument(InstrumentType.mainMelody,MidiInstrument.overdrivenGuitar,0),
      DefaultInstrument(InstrumentType.mainRhythm,MidiInstrument.acousticGrandPiano,.25),
    ],
  ];
  bool audioReady = false;
  bool muted = true;
  bool muteDrums = true;
  bool playing = false;
  double masterVolume = .25;
  Completer? loadingPatch;
  Completer? initializing;
  Map<InstrumentType,Instrument> orchMap = {};
  Map<MidiDrum,Instrument> drumMap = {};
  MidiTrack masterTrack = MidiTrack("Master",maxLength: 2);
  InstrumentType lead = InstrumentType.mainMelody;
  InstrumentType rhythm = InstrumentType.pawnMelody;
  MatrixClient client;
  KeyChord currentChord = KeyChord(MidiNote.noteA, MidiScale.majorScale);

  BoardSonifier(this.client);

  Future<void> init(int ensembleNum) async {
    initializing = Completer();
    js.context.callMethod("initAudio", [initialized]);
    await initializing?.future;
    await loadEnsemble(defaultEnsembles[ensembleNum]);
    await loadDrumKit([MidiDrum.bassDrum1,MidiDrum.snareDrum2,MidiDrum.closedHiHat,MidiDrum.rideCymbal1,MidiDrum.highTom1,MidiDrum.highTom2,MidiDrum.lowTom2,MidiDrum.tambourine]);
    orchMap[InstrumentType.mainRhythm]!.mute = true;
    audioReady = true;
  }

  void initialized() { //
      print("Audio Initialized");
      initializing?.complete();
  }

  List<DefaultInstrument> randomEnsemble() {
    List<DefaultInstrument> ensemble = [];
    for (InstrumentType it in InstrumentType.values) {
      ensemble.add(DefaultInstrument(it, MidiInstrument.values.elementAt(Random().nextInt(MidiInstrument.values.length)), .25));
    }
    return ensemble;
  }

  Future<void> loadEnsemble(List<DefaultInstrument> ensemble) async {
    for (DefaultInstrument defInst in ensemble) { //print("Loading from ensemble: ${defInst.type.name},${defInst.patch.index}");
      //defInst.
      await loadInstrument(defInst.type,defInst.instrument); //Instrument(defInst.instrument.iPatch,level : defInst.instrument.level)
    }
  }

  Future<void> loadInstrument(InstrumentType type, Instrument i) async {
    orchMap.update(type, (value) => i, ifAbsent: () => i);
    loadingPatch = Completer();
    js.context.callMethod("setInstrument",[i.iPatch?.name,i.iPatch?.index,loadedInstrument]);
    return loadingPatch?.future;
  }

  void loadedInstrument(String type,int patch) {
    MidiInstrument i = MidiInstrument.values.elementAt(patch);
    print("Loaded: $type: ${i.name}"); //orchMap.update(type, (value) => i, ifAbsent: () => i);
    loadingPatch?.complete(type);
  }

  Future<void> loadDrumKit(List<MidiDrum> kit) async {
    for (MidiDrum drum in kit) {
      await loadDrum(drum, Instrument(drumPatch: drum));
    }
  }

  Future<void> loadDrum(MidiDrum drum, Instrument i) async {
    drumMap.update(drum, (value) => i, ifAbsent: () => i);
    loadingPatch = Completer();
    js.context.callMethod("setDrumKit",[drum.name,drum.patchNum,loadedDrum]);
    return loadingPatch?.future;
  }

  void loadedDrum(String type,int patch) {
    print("Loaded: $type");
    loadingPatch?.complete(type);
  }

  void playChord(Instrument? i,double t, List<int> chord, double duration,double volume) {
    for (int pitch in chord) {
      playNote(i, t, pitch, duration, volume);
    }
  }

  void playNote(Instrument? i,double t, int pitch, double duration,double volume) {
    if (i != null && audioReady && !muted && !i.mute && isSoloed(i)) {
      if (i.iPatch != null) {
        js.context.callMethod("playNote",[i.iPatch!.name,t,pitch,duration,volume * masterVolume]);
      }
      else if (i.drumPatch != null && !muteDrums) {
        js.context.callMethod("playDrum",[i.drumPatch!.name,t,duration,volume * masterVolume]); //pitch?
      }
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

  static MidiNote getNewNote(MidiNote currentNote) {
    MidiNote newNote;
    do {
      newNote = MidiNote.values.elementAt(Random().nextInt(MidiNote.values.length));
    } while (newNote == currentNote);
    return newNote;
  }

  static MidiScale getNewScale(MidiScale currentScale) {
    MidiScale newScale;
    do {
      newScale = MidiScale.values.elementAt(Random().nextInt(MidiScale.values.length));
    } while (newScale == currentScale);
    return newScale;
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

  void loopTrack(MidiTrack track) {
    track.play(this, (t) {
      loopTrack(track);
    });
  }

}

class KeyChord {
  MidiNote key;
  MidiScale scale;
  KeyChord(this.key,this.scale);
}

enum MusicalElement {melody, harmony, rhythm}

class MidiTrack implements Comparable<MidiTrack> {
  String name;
  bool playing = false;
  Map<MusicalElement,List<MidiEvent>> subTracks = {};
  double _currentLength = 0; //_insertMarker = 0,
  double? maxLength;
  int maxHarmony;
  List<MidiEvent> newRhythmMap = []; //add initial rhythm?

  MidiTrack(this.name, {this.maxHarmony  = 2, this.maxLength}) {
    initTracks();
  }

  initTracks() {
    for (MusicalElement elem in MusicalElement.values) {
      subTracks.putIfAbsent(elem, () => []); //subTracks[] = [];
    }
    _currentLength = 0;
  }

  List<MidiEvent> getSubTrack(MusicalElement elem) {
    return subTracks[elem] ?? [];
  }

  Future<void> play(BoardSonifier player,dynamic onFinished) async {
    if (newRhythmMap.isNotEmpty) {
      getSubTrack(MusicalElement.rhythm).clear();
      for (MidiEvent e in newRhythmMap) {
        addNoteEvent(e, MusicalElement.rhythm, updatePitch: false);
      }
      newRhythmMap.clear();
    }
    List<MidiEvent> rhythm = getSubTrack(MusicalElement.rhythm); //print("Rhythm: $rhythm");
    List<MidiEvent> harmony = getSubTrack(MusicalElement.harmony);
    List<MidiEvent> melody = getSubTrack(MusicalElement.melody);
    for (var rhythmEvent in rhythm) { //print("Playing Rhythm: $midiEvent on $name");
      player.playNote(rhythmEvent.instrument,rhythmEvent.offset, rhythmEvent.pitch, rhythmEvent.duration,rhythmEvent.volume);
    }
    int currentMillis = ((maxLength ?? 1) * 1000).round(); //print("Waiting $currentMillis milliseconds...");
    Future.delayed(Duration(milliseconds: currentMillis)).then((value) => onFinished(this));
    double quantizeMillis =  currentMillis / 8; //print("Quantizing to: $quantizeMillis");
    for (double t = 0; t < currentMillis; t += quantizeMillis) {
      await Future.delayed(Duration(milliseconds: t.floor()));
      if (melody.isNotEmpty) {
        MidiEvent melodyEvent = melody.removeAt(0);
        player.playNote(melodyEvent.instrument,0, melodyEvent.pitch, melodyEvent.duration,melodyEvent.volume);
      }
      for (int i = 0; i < maxHarmony && harmony.isNotEmpty; i++) {
        MidiEvent harmonyEvent = harmony.removeAt(0);
        player.playNote(harmonyEvent.instrument,0, harmonyEvent.pitch, harmonyEvent.duration,harmonyEvent.volume);
      }
    }
  }

  void addRest(Instrument instrument,double duration) { //addNoteEvent(instrument,0,duration,0);
    _currentLength += duration;
  }

  int trimPitch(int pitch) {
    return pitch < maxPitch && pitch > minPitch ? pitch : 60;
  }

  void addNoteEvent(MidiEvent e,MusicalElement elem,{bool updatePitch = true}) { //MidiEvent e = createNoteEvent(instrument,pitch,duration,volume,offset: offset);
    if (elem == MusicalElement.rhythm) {
      double t2 = e.offset + e.duration;
      if (_currentLength < t2) _currentLength = t2;
      if (_currentLength > (maxLength ?? 999)) {
        print("Error: track overflow: $maxLength > ${e.offset} + ${e.duration}");
        return;
      } //else { print("New length: $maxLength > $t + $duration"); }
    }
    getSubTrack(elem).add(e);
    if (updatePitch) e.instrument.currentPitch = e.pitch;
  }

  MidiEvent createNoteEvent(Instrument instrument, int pitch, double duration, double volume, {double? offset}) {
    return MidiEvent(instrument, trimPitch(pitch), offset ?? _currentLength, duration, volume);
  }

  void addChordEvent(Instrument instrument, List<int> pitches, double duration, double volume, MusicalElement elem, {double? offset}) {
    double t = offset ?? _currentLength;
    for (int pitch in pitches) {
      addNoteEvent(createNoteEvent(instrument, pitch, duration, volume, offset: t), elem, updatePitch: false);
    }
    if (pitches.isNotEmpty) instrument.currentPitch = trimPitch(pitches.first);
  }

  void clearTrack() {
    subTracks.clear();
    initTracks();
  }

  @override
  int compareTo(MidiTrack other) {
    return _currentLength.compareTo(other._currentLength);
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
    return "[instrument: ${instrument.iPatch?.name}, note: ${BoardSonifier.getNote(pitch)}, pitch: $pitch, offset: $offset, duration: $duration, volume: $volume]";
  }

  @override
  int compareTo(MidiEvent other) {
    return offset.compareTo(other.offset);
  }
}

class DefaultInstrument {
  InstrumentType type;
  Instrument instrument;
  DefaultInstrument(this.type,MidiInstrument defPatch,double defLevel) : instrument = Instrument(iPatch: defPatch,level : defLevel);
}

class Instrument {
  MidiInstrument? iPatch;
  MidiDrum? drumPatch;
  double level;
  bool mute = false;
  bool solo = false;
  int currentPitch = 60;
  Instrument({ this.iPatch, this.drumPatch, this.level = .5 });
}

