import 'dart:js' as js;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

enum MidiBank {
  piano,chromaticPerc,organ,guitar,bass,strings,ensemble,brass,reed,pipe,synthLead,synthPad,synthFX,ethnic,perc,soundFX
}

enum MidiInstrument {
  acousticGrandPiano(MidiBank.piano),
  brightAcousticPiano(MidiBank.piano),
  electricGrandPiano(MidiBank.piano),
  honkyTonkPiano(MidiBank.piano),
  electricPiano1(MidiBank.piano),
  electricPiano2(MidiBank.piano),
  harpsichord(MidiBank.piano),
  clavinet(MidiBank.piano),
  celesta(MidiBank.chromaticPerc),
  glockenspiel(MidiBank.chromaticPerc),
  musicBox(MidiBank.chromaticPerc),
  marimba(MidiBank.chromaticPerc),
  vibraphone(MidiBank.chromaticPerc),
  xylophone(MidiBank.chromaticPerc),
  tubularBells(MidiBank.chromaticPerc),
  dulcimer(MidiBank.chromaticPerc),
  drawBarOrgan(MidiBank.organ),
  percOrgan(MidiBank.organ),
  rockOrgan(MidiBank.organ),
  churchOrgan(MidiBank.organ),
  reedOrgan(MidiBank.organ),
  accordion(MidiBank.organ),
  harmonica(MidiBank.organ),
  tangoAccordion(MidiBank.organ),
  acousticGuitarNylon(MidiBank.guitar),
  acousticGuitarSteel(MidiBank.guitar),
  electricGuitarJazz(MidiBank.guitar),
  electricGuitarClean(MidiBank.guitar),
  electricGuitarMuted(MidiBank.guitar),
  overdrivenGuitar(MidiBank.guitar),
  distortionGuitar(MidiBank.guitar),
  guitarHarmonics(MidiBank.guitar),
  acousticBass(MidiBank.bass),
  electricBassFinger(MidiBank.bass),
  electricBassPick(MidiBank.bass),
  fretkessBass(MidiBank.bass),
  slapBass1(MidiBank.bass),
  slapBass2(MidiBank.bass),
  synthBass1(MidiBank.bass),
  synthBass2(MidiBank.bass),
  violin(MidiBank.strings),
  viola(MidiBank.strings),
  cello(MidiBank.strings),
  contrabass(MidiBank.strings),
  tremoloStrings(MidiBank.strings),
  pizzStrings(MidiBank.strings),
  orchHarp(MidiBank.strings),
  timpani(MidiBank.strings), //why is this strings?
  stringEnsemble1(MidiBank.ensemble),
  stringEnsemble2(MidiBank.ensemble),
  synthStrings1(MidiBank.ensemble),
  synthStrings2(MidiBank.ensemble),
  choirAahs(MidiBank.ensemble),
  choirOohs(MidiBank.ensemble),
  synthChoir(MidiBank.ensemble),
  orchHit(MidiBank.ensemble),
  trumpet(MidiBank.brass),
  trombone(MidiBank.brass),
  tuba(MidiBank.brass),
  mutedTrumpet(MidiBank.brass),
  frenchHorn(MidiBank.brass),
  brassSection(MidiBank.brass),
  synthBrass1(MidiBank.brass),
  synthBrass2(MidiBank.brass),
  sopranoSax(MidiBank.reed),
  altoSax(MidiBank.reed),
  tenorSax(MidiBank.reed),
  baritoneSax(MidiBank.reed),
  oboe(MidiBank.reed),
  englishHorn(MidiBank.reed),
  bassoon(MidiBank.reed),
  clarinet(MidiBank.reed),
  piccolo(MidiBank.pipe),
  flute(MidiBank.pipe),
  recorder(MidiBank.pipe),
  panFlute(MidiBank.pipe),
  blownBottle(MidiBank.pipe),
  shakuhachi(MidiBank.pipe),
  whistle(MidiBank.pipe),
  ocarina(MidiBank.pipe),
  lead1Square(MidiBank.synthLead),
  lead2Sawtooth(MidiBank.synthLead),
  lead3Calliope(MidiBank.synthLead),
  lead4Chiff(MidiBank.synthLead),
  lead5Charang(MidiBank.synthLead),
  lead6Voice(MidiBank.synthLead),
  lead7Fifths(MidiBank.synthLead),
  lead8BassAndLead(MidiBank.synthLead),
  pad1NewAge(MidiBank.synthPad),
  pad2Warm(MidiBank.synthPad),
  pad3Polysynth(MidiBank.synthPad),
  pad4Chior(MidiBank.synthPad),
  pad5Bowed(MidiBank.synthPad),
  pad6Metallic(MidiBank.synthPad),
  pad7Halo(MidiBank.synthPad),
  pad8Sweep(MidiBank.synthPad),
  fx1Rain(MidiBank.synthFX),
  fx2Soundtrack(MidiBank.synthFX),
  fx3Crystal(MidiBank.synthFX),
  fx4Atmosphere(MidiBank.synthFX),
  fx5Brightness(MidiBank.synthFX),
  fx6Goblins(MidiBank.synthFX),
  fx7Echoes(MidiBank.synthFX),
  fx8SciFi(MidiBank.synthFX),
  sitar(MidiBank.ethnic),
  banjo(MidiBank.ethnic),
  shamisen(MidiBank.ethnic),
  koto(MidiBank.ethnic),
  kalimba(MidiBank.ethnic),
  bagpipe(MidiBank.ethnic),
  fiddle(MidiBank.ethnic),
  shanai(MidiBank.ethnic),
  tinkleBell(MidiBank.perc),
  agogo(MidiBank.perc),
  steelDrums(MidiBank.perc),
  woodBlock(MidiBank.perc),
  taikoDrum(MidiBank.perc),
  melodicTom(MidiBank.perc),
  synthDrum(MidiBank.perc),
  reverseCymbal(MidiBank.perc),
  guitarFretNoise(MidiBank.soundFX),
  breathNoise(MidiBank.soundFX),
  seashore(MidiBank.soundFX),
  birdTweet(MidiBank.soundFX),
  telephoneRing(MidiBank.soundFX),
  helicopter(MidiBank.soundFX),
  applause(MidiBank.soundFX),
  gunshot(MidiBank.soundFX);
  final MidiBank bank;
  const MidiInstrument(this.bank);
}

enum MidiDrum {
  bassDrum1(35),
  bassDrum2(36),
  rimshot(37),
  snareDrum1(38),
  handClap(39),
  snareDrum2(40),
  lowTom2(41),
  closedHiHat(42),
  lowTom1(43),
  pedalHiHat(44),
  midTom2(45),
  openHiHat(46),
  midTom1(47),
  highTom2(48),
  crashCymbal1(49),
  highTom1(50),
  rideCymbal1(51),
  chineseCymbal(52),
  rideBell(53),
  tambourine(54),
  splashCymbal(55),
  cowBell(56),
  crashCymbal2(57),
  vibraSlap(58),
  rideCymbal2(59),
  highBongo(60),
  lowBongo(61),
  muteHighConga(62),
  openHighConga(63),
  lowConga(64),
  highTimbale(65),
  lowTimbale(66),
  highAgogo(67),
  lowAgogo(68),
  cabasa(69),
  meracas(70),
  shortWhistle(71),
  longWhistle(72),
  shortGuiro(73),
  longGuiro(74),
  claves(75),
  highWoodBlock(76),
  lowWoodBlock(77),
  muteCuica(78),
  openCuica(79),
  muteTriangle(80),
  openTriangle(81);
  final int patchNum;
  const MidiDrum(this.patchNum);
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

typedef MidiPerformer = String;

//TODO: move to library
class MidiManager extends ChangeNotifier {
  var midiLogger = Logger(
    printer: PrettyPrinter(),
  );
  bool audioReady = false;
  bool muted = true;
  bool muteDrums = true;
  bool playing = false;
  double masterVolume = .25;
  Completer? loadingPatch;
  Completer? initializing;
  Map<MidiPerformer,Instrument> orchMap = {};
  Map<MidiDrum,Instrument> drumMap = {};
  KeyChord currentChord = KeyChord(MidiNote.noteA, MidiScale.majorScale);

  MidiManager();

  Future<void> init(List<MidiAssignment> ensemble) async {
    initializing = Completer();
    js.context.callMethod("initAudio", [initialized]);
    await initializing?.future;
    await loadEnsemble(ensemble);
    await loadDrumKit([MidiDrum.bassDrum1,MidiDrum.snareDrum2,MidiDrum.closedHiHat,MidiDrum.rideCymbal1,MidiDrum.highTom1,MidiDrum.highTom2,MidiDrum.lowTom2,MidiDrum.tambourine]);
    audioReady = true;
  }

  void initialized() { //
      midiLogger.i("Audio Initialized");
      initializing?.complete();
  }

  List<MidiAssignment> randomEnsemble(List<MidiPerformer> players) {
    List<MidiAssignment> ensemble = [];
    for (MidiPerformer mp in players) {
      ensemble.add(MidiAssignment(mp, MidiInstrument.values.elementAt(Random().nextInt(MidiInstrument.values.length)), .25));
    }
    return ensemble;
  }

  Future<void> loadEnsemble(List<MidiAssignment> ensemble) async {
    for (MidiAssignment defInst in ensemble) { //print("Loading from ensemble: ${defInst.type.name},${defInst.patch.index}");
      //defInst.
      await loadInstrument(defInst.player,defInst.instrument); //Instrument(defInst.instrument.iPatch,level : defInst.instrument.level)
    }
  }

  Future<void> loadInstrument(MidiPerformer player, Instrument i) async {
    orchMap.update(player, (value) => i, ifAbsent: () => i);
    loadingPatch = Completer();
    js.context.callMethod("setInstrument",[i.iPatch?.name,i.iPatch?.index,loadedInstrument]);
    return loadingPatch?.future;
  }

  void loadedInstrument(String type,int patch) {
    MidiInstrument i = MidiInstrument.values.elementAt(patch);
    midiLogger.i("Loaded: $type: ${i.name}");
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
    midiLogger.i("Loaded: $type");
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
  }

  void toggleMute(Instrument i) {
    i.mute = !i.mute;
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
    if (degree < 0) return pitch + steps; //print("Pitch: $pitch, Note: ${getNote(pitch)}, Degree: $degree");
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

}

class KeyChord {
  MidiNote key;
  MidiScale scale;
  KeyChord(this.key,this.scale);
}

enum TrackElement {realtimeMelody, realtimeHarmony, master}

class MidiTrack implements Comparable<MidiTrack> {
  var trackLogger = Logger(
    printer: PrettyPrinter(),
  );
  String name;
  bool playing = false;
  Map<TrackElement,List<MidiEvent>> subTracks = {};
  double _currentLength = 0; //_insertMarker = 0,
  double? maxLength;
  int maxHarmony;
  List<MidiEvent> newMasterMap = []; //add initial rhythm?

  MidiTrack(this.name, {this.maxHarmony  = 2, this.maxLength}) {
    initTracks();
  }

  initTracks() {
    for (TrackElement elem in TrackElement.values) {
      subTracks.putIfAbsent(elem, () => []); //subTracks[] = [];
    }
    _currentLength = 0;
  }

  List<MidiEvent> getSubTrack(TrackElement elem) {
    return subTracks[elem] ?? [];
  }

  Future<void> play(MidiManager player,{looping = false, realTime = true}) async {
    playing = true;
    do {
      if (newMasterMap.isNotEmpty) {
        getSubTrack(TrackElement.master).clear();
        for (MidiEvent e in newMasterMap) {
          addNoteEvent(e, updatePitch: false);
        }
        newMasterMap.clear();
      }
      List<MidiEvent> master = getSubTrack(TrackElement.master);
      for (MidiEvent e in master) {
        player.playNote(e.instrument,e.offset, e.pitch, e.duration,e.volume);
      }
      //final eot = //.then((value) => onFinished());
      if (looping) {
        int currentMillis = ((maxLength ?? 1) * 1000).round(); //print("$name: Waiting $currentMillis milliseconds...");
        List<MidiEvent> harmony = getSubTrack(TrackElement.realtimeHarmony);
        List<MidiEvent> melody = getSubTrack(TrackElement.realtimeMelody);
        double quantizeMillis =  currentMillis / 8;
        for (double t = 0; t < currentMillis && playing; t += quantizeMillis) { //print("$name: Waiting $quantizeMillis millis")
          await Future.delayed(Duration(milliseconds: quantizeMillis.floor()));
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
      else if (realTime) {
        int millis = (max(maxLength ?? 1,_currentLength) * 1000).floor();
        player.midiLogger.f("Waiting $millis milliseconds");
        await Future.delayed(Duration(milliseconds: millis));
      }
    } while (looping && playing);
    playing = false;
  }

  //void pause() {}

  void stop() {
    playing = false;
  }

  void addRest(double duration) { //addNoteEvent(instrument,0,duration,0);
    _currentLength += duration;
  }

  int trimPitch(int pitch) {
    return pitch < maxPitch && pitch > minPitch ? pitch : 60;
  }

  MidiEvent createRestEvent(Instrument instrument,double duration, {double? offset}) {
    return MidiEvent(instrument, 0, offset ?? _currentLength, duration, 0);
  }

  MidiEvent createNoteEvent(Instrument instrument, int pitch, double duration, double volume, {double? offset}) {
    return MidiEvent(instrument, trimPitch(pitch), offset ?? _currentLength, duration, volume);
  }

  void addNoteEvent(MidiEvent e,{elem = TrackElement.master, updatePitch = true}) { //MidiEvent e = createNoteEvent(instrument,pitch,duration,volume,offset: offset);
    if (e.pitch <= 0) {
      addRest(e.duration); return;
    }
    if (elem == TrackElement.master) {
      double t2 = e.offset + e.duration;
      if (_currentLength < t2) _currentLength = t2;
      if (_currentLength > (maxLength ?? 999)) {
        trackLogger.w("Error: track overflow: $maxLength > ${e.offset} + ${e.duration}");
        return;
      } //else { print("New length: $maxLength > $t + $duration"); }
    }
    getSubTrack(elem).add(e);
    if (updatePitch) e.instrument.currentPitch = e.pitch;
  }
  void addChordEvent(Instrument instrument, List<int> pitches, double duration, double volume, {elem = TrackElement.master, double? offset}) {
    double t = offset ?? _currentLength;
    for (int pitch in pitches) {
      addNoteEvent(createNoteEvent(instrument, pitch, duration, volume, offset: t), elem : elem, updatePitch: false);
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
    return "[instrument: ${instrument.iPatch?.name}, note: ${MidiManager.getNote(pitch)}, pitch: $pitch, offset: $offset, duration: $duration, volume: $volume]";
  }

  @override
  int compareTo(MidiEvent other) {
    return offset.compareTo(other.offset);
  }
}

class MidiAssignment {
  MidiPerformer player;
  Instrument instrument;
  MidiAssignment(this.player,MidiInstrument defPatch,double defLevel) : instrument = Instrument(iPatch: defPatch,level : defLevel);
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

