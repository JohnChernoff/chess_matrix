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
    sonifier.masterTrack.clearTrack();
    sonifier.masterTrack.addChordEvent(i, [62], dur, vol, MusicalElement.rhythm);
    sonifier.masterTrack.addRest(i,dur * 4);
    sonifier.masterTrack.addChordEvent(i, [61], dur, vol, MusicalElement.rhythm);
    sonifier.masterTrack.addChordEvent(i, [59,64], dur, vol, MusicalElement.rhythm);
    sonifier.masterTrack.addChordEvent(i, [59], dur, vol, MusicalElement.rhythm);
    sonifier.loopTrack(sonifier.masterTrack,2);
  }
}

