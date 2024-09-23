import 'board_sonifier.dart';
import 'client.dart';

class MatrixTest {
  Future<void> rhythmTest(MatrixClient client) async {
    BoardSonifier sonifier = BoardSonifier(client);
    await sonifier.init(1);
    sonifier.muted = false;
    double dur = .25;
    double vol = .25;
    Instrument i = sonifier.orchMap[InstrumentType.pawnMelody]!;
    sonifier.rhythmTrack.clearTrack();
    sonifier.rhythmTrack.addChordEvent(i, [62], dur, vol);
    sonifier.rhythmTrack.addRest(i,dur * 4);
    sonifier.rhythmTrack.addChordEvent(i, [61], dur, vol);
    sonifier.rhythmTrack.addChordEvent(i, [59,64], dur, vol);
    sonifier.rhythmTrack.addChordEvent(i, [59], dur, vol);
    sonifier.looper(sonifier.rhythmTrack);
  }
}

