import 'package:chess_matrix/chess_sonifier.dart';
import 'package:chess_matrix/client.dart';
import 'package:chess_matrix/midi_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rhythm Test', (WidgetTester tester) async {
    rhythmTest();
  });
}

Future<void> rhythmTest() async {
  MatrixClient client = MatrixClient('lichess.org');
  ChessSonifier sonifier = ChessSonifier(client);
  MidiTrack masterTrack = MidiTrack("Master",maxLength: 2);
  await sonifier.midi.init(defaultEnsembles.first);
  double dur = .25;
  double vol = .25;
  masterTrack.clearTrack();
  masterTrack.addChordEvent(sonifier.midi.orchMap[MidiChessPlayer.mainRhythm.name]!, [62], dur, vol);
  masterTrack.addRest(sonifier.midi.orchMap[MidiChessPlayer.mainRhythm.name]!,dur * 4);
  masterTrack.addChordEvent(sonifier.midi.orchMap[MidiChessPlayer.mainRhythm.name]!, [61], dur, vol);
  masterTrack.addChordEvent(sonifier.midi.orchMap[MidiChessPlayer.mainRhythm.name]!, [59,64], dur, vol);
  masterTrack.addChordEvent(sonifier.midi.orchMap[MidiChessPlayer.mainRhythm.name]!, [59], dur, vol);
}