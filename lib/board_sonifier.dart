import 'dart:async';
import 'dart:js' as js;
import 'matrix_fields.dart';

enum InstrumentType {
  moveMelody,moveRhythm,captureHarmony,castling,check
}

const drums = [35,40,42,51,50,48,41,19];
const octave = 12;
const int minPitch = octave * 2;
const int maxPitch = octave * 7;

class BoardSonifier {
  static List<List<DefaultInstrument>> defaultEnsembles = [
    [
      DefaultInstrument(InstrumentType.moveMelody,MidiInstrument.fx3Crystal,0),
      DefaultInstrument(InstrumentType.moveRhythm,MidiInstrument.electricGuitarMuted,50),
      DefaultInstrument(InstrumentType.captureHarmony,MidiInstrument.electricPiano1,50),
      DefaultInstrument(InstrumentType.castling,MidiInstrument.choirAahs,0),
      DefaultInstrument(InstrumentType.check,MidiInstrument.pizzStrings,50),
    ],
    [
      DefaultInstrument(InstrumentType.moveMelody,MidiInstrument.flute,48),
      DefaultInstrument(InstrumentType.moveRhythm,MidiInstrument.synthDrum,16),
      DefaultInstrument(InstrumentType.captureHarmony,MidiInstrument.acousticGrandPiano,20),
      DefaultInstrument(InstrumentType.castling,MidiInstrument.choirAahs,50),
      DefaultInstrument(InstrumentType.check,MidiInstrument.pizzStrings,50),
    ],
    [
      DefaultInstrument(InstrumentType.moveMelody,MidiInstrument.viola,36),
      DefaultInstrument(InstrumentType.moveRhythm,MidiInstrument.kalimba,24),
      DefaultInstrument(InstrumentType.captureHarmony,MidiInstrument.electricGuitarMuted,16),
      DefaultInstrument(InstrumentType.castling,MidiInstrument.pizzStrings,50),
      DefaultInstrument(InstrumentType.check,MidiInstrument.taikoDrum,50),
    ]
  ];
  bool audioReady = false;
  bool muted = true;
  int drumBoard = 0;
  bool drums = false;
  Completer? loadingInstrument;
  Completer? initializing;
  Map<String,MidiInstrument> orchMap = {};

  BoardSonifier();

  Future<void> init(int ensembleNum) async {
    //setTempo(TEMPO_CONTROL.valueAsNumber);
    //setDrumKit(DRUMS);
    //melodizer();
    //drumBeat();
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
      await loadInstrument(defInst.type,defInst.patch);
    }
  }

  Future<void> loadInstrument(InstrumentType type, MidiInstrument patch) async {
    loadingInstrument = Completer();
    js.context.callMethod("setInstrument",[type.name,patch.index,loaded]);
    return loadingInstrument?.future;
  }

  void loaded(String type,int patch) {
    MidiInstrument i = MidiInstrument.values.elementAt(patch);
    print("Loaded: $type: ${i.name}");
    orchMap.update(type, (value) => i, ifAbsent: () => i);
    loadingInstrument?.complete(type);
  }

  void playNote(InstrumentType type,int pitch,int duration,double volume) {
    if (audioReady && !muted) {
      js.context.callMethod("playNote",[type.name,0,pitch,duration,volume]);
    }
  }

}

class DefaultInstrument {
  InstrumentType type;
  MidiInstrument patch;
  int level;
  DefaultInstrument(this.type,this.patch,this.level);
}