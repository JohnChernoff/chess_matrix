import 'package:chess_matrix/board_sonifier.dart';
import 'package:chess_matrix/client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rhythm Test', (WidgetTester tester) async {
    rhythmTest();
  });
}

Future<void> rhythmTest() async {
  MatrixClient client = MatrixClient('wss://socket.lichess.org/api/socket');
  MidiPlayer sonifier = MidiPlayer(client);
  await sonifier.init(1);
  double dur = .25;
  double vol = .25;
  sonifier.masterTrack.clearTrack();
  sonifier.masterTrack.addChordEvent(sonifier.orchMap[sonifier.rhythm]!, [62], dur, vol);
  sonifier.masterTrack.addRest(sonifier.orchMap[sonifier.rhythm]!,dur * 4);
  sonifier.masterTrack.addChordEvent(sonifier.orchMap[sonifier.rhythm]!, [61], dur, vol);
  sonifier.masterTrack.addChordEvent(sonifier.orchMap[sonifier.rhythm]!, [59,64], dur, vol);
  sonifier.masterTrack.addChordEvent(sonifier.orchMap[sonifier.rhythm]!, [59], dur, vol);
}