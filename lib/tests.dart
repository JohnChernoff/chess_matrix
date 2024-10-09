import 'chess_sonifier.dart';
import 'client.dart';
import 'midi_manager.dart';

class MatrixTest {
  Future<void> rhythmTest(MatrixClient client) async {
    MidiManager sonifier = MidiManager();
    MidiTrack masterTrack = MidiTrack("Master",maxLength: 2);
    await sonifier.init(defaultEnsembles.first);
    sonifier.muted = false;
    double dur = .25;
    double vol = .25;
    Instrument i = sonifier.orchMap[MidiChessPlayer.pawnMelody.name]!;
    masterTrack.clearTrack();
    masterTrack.addChordEvent(i, [62], dur, vol);
    masterTrack.addRest(dur * 4);
    masterTrack.addChordEvent(i, [61], dur, vol);
    masterTrack.addChordEvent(i, [59,64], dur, vol);
    masterTrack.addChordEvent(i, [59], dur, vol);
    masterTrack.play(sonifier,looping: true); //sonifier.loopTrack(masterTrack);
  }
}

