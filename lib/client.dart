import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:chess_matrix/board_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lichess_package/lichess_package.dart';
import 'package:lichess_package/zug_sock.dart';
import 'board_matrix.dart';

const noAvailableSlot = -1;

class MatrixClient extends ChangeNotifier {
  static const maxStreams = 4;
  final int width, height;
  final Map<String,BoardWidget> boards = {};
  final Map<String,dynamic> callbacks = {};
  final Map<String,ui.Image> pieceImages = {};
  List<int> availableSlots = [];
  String gameType;
  late ZugSock lichSock;

  MatrixClient(this.gameType,this.width,this.height) {
    loadPieces();
    lichSock = ZugSock('wss://socket.lichess.org/api/socket', connected, handleMsg, disconnected);
  }

  void connected() {
    print("Connected");
    loadTVGames(gameType);
  }

  void handleMsg(String msg) {
    dynamic json = jsonDecode(msg);
    //print("Message: $json");
    String type = json['t'];
    dynamic data = json['d'];
    String id = data['id'] ?? "";
    if (type == "fen") {
      String fen = data['fen'];
      if (callbacks.containsKey(id)) callbacks[id](fen);
    } else if (type == 'finish') {
      clearBoard(id);
    }

  }

  void disconnected() {
    print("Disconnected");
  }

  int getLowestAvailableSlot() {
    for (int slot = 0; slot < maxStreams; slot++) {
      if (!availableSlots.contains(slot)) return slot;
    }
    return noAvailableSlot;
  }

  Future<void> loadPieces() async {
    for (PieceColor c in PieceColor.values) {
      for (PieceType t in PieceType.values) {
        String p = Piece(t, c).toString(); //print("Loading: $p.png...");
        ui.Image img = await loadImage("assets/images/$p.png");
        pieceImages.putIfAbsent(p, () => img);
      }
    }
  }

  void loadTVGames(String type) async {
    List<String> ids = await Lichess.getTV(type);
    print("ids: $ids");
    for (int i = 0; i < min(maxStreams,ids.length); i++) {
      addBoard(ids[i]);
    }
    notifyListeners();
  }

  void addBoard(String id) {
    if (!boards.containsKey(id)) {
      int slot = getLowestAvailableSlot();
      if (slot != noAvailableSlot) {
        print("Adding $id at slot: $slot");
        boards.putIfAbsent(id,() => BoardWidget(this, id, slot, width, height));
        availableSlots.add(slot);
        lichSock.send(
            jsonEncode({ 't': 'startWatching', 'd': id })
        );
      }
    }
  }

  void clearBoard(String id) { //todo: animation?
    print("Removing: $id");
    BoardWidget? board = boards.remove(id);
    availableSlots.remove(board?.slot);
    callbacks.remove(id);
    loadTVGames(gameType);
  }

  Future<ui.Image> loadImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: (height / 8).round(),
      targetWidth: (width / 8).round(),
    );
    var frame = await codec.getNextFrame();
    return frame.image;
  }
}