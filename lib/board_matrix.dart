import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'client.dart';

const startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
const emptyVal = 0, pawnVal = 1, knightVal = 2, bishopVal = 3, rookVal = 4, queenVal = 5, kingVal = 6;
const maxControl = 4;
const ranks = 8, files = 8;

enum ColorComponent {red,green,blue}
enum PieceColor {none,white,black}
enum PieceType {none,pawn,knight,bishop,rook,queen,king}

class BoardState {
  String id;
  Player whitePlayer,blackPlayer;
  bool finished = false;
  BoardState(this.id,this.whitePlayer,this.blackPlayer);
}

class BoardMatrix {
  final String fen;
  final int width, height;
  final bool blackPOV;
  final List<List<Square>> elements = List<List<Square>>.generate(
      ranks, (i) => List<Square>.generate(
      files, (index) => Square(Piece(PieceType.none,PieceColor.none)), growable: false), growable: false);
  late final ColorArray edgeCol;
  ui.Image? image;

  BoardMatrix(this.fen,this.width,this.height,imgCall,{this.blackPOV = false, edgeColor = Colors.black}) {
    edgeCol = ColorArray(edgeColor.red,edgeColor.green,edgeColor.blue);
    List<String> fenRanks = fen.split(" ")[0].split("/");
    for (int rank = 0; rank < fenRanks.length; rank++) {
      int file = 0;
      for (int i = 0; i < fenRanks[rank].length; i++) {
        String char = fenRanks[rank][i];
        Piece piece = Piece.fromChar(char);
        if (piece.type == PieceType.none) {
          file += int.parse(char); //todo: try
        } else {
          if (blackPOV) {
            elements[7 - rank][7 - file++].piece = piece;
          } else {
            elements[rank][file++].piece = piece;
          }
        }
      }
    }
    updateControl();
    ui.decodeImageFromPixels(getLinearInterpolation(), width, height, ui.PixelFormat.rgba8888, (ui.Image img) {
      image = img;
      imgCall();
    });
  }

  int colorVal(PieceColor color) {
    return color == PieceColor.black ? -1 : color == PieceColor.white ? 1 : 0;
  }

  bool isPiece(Coord p, PieceType t) {
    return getSquare(p).piece.type == t;
  }

  Square getSquare(Coord p) {
    return elements[p.x][p.y];
  }

  void updateControl() {
    for (int y = 0; y < ranks; y++) {
      for (int x = 0; x < files; x++) {
        elements[x][y].setControl(calcControl(Coord(x,y)));
      }
    }
  }

  int calcControl(Coord p) {
    int control = 0;
    control += knightControl(p);
    control += diagControl(p);
    control += lineControl(p);
    return control;
  }

  int knightControl(Coord p) {
    int control = 0;
    for (int x = -2; x <= 2; x++) {
      for (int y = -2; y <= 2; y++) {
        if ((x.abs() + y.abs()) == 3) {
          Coord p2 = Coord(p.x + x,  p.y + y);
          if (p2.x >= 0 && p2.x < 8 && p2.y >= 0 && p2.y < 8) {
            Piece piece = getSquare(p2).piece;
            if (piece.type == PieceType.knight) {
              control += colorVal(piece.color);
            }
          }
        }
      }
    }
    return control;
  }

  int diagControl(Coord p1) {
    int control = 0;
    for (int dx = -1; dx <= 1; dx += 2) {
      for (int dy = -1; dy <= 1; dy += 2) {
        Coord p2 = Coord.fromCoord(p1);
        bool clearLine = true;
        while (clearLine) {
          p2.add(dx,dy);
          clearLine = p2.squareBounds(8);
          if (clearLine) {
            Piece piece = getSquare(p2).piece;
            if (piece.type == PieceType.bishop || piece.type == PieceType.queen) {
              control += colorVal(piece.color);
            } else if (p1.isAdjacent(p2)) {
              if (piece.type == PieceType.king) {
                control += colorVal(piece.color);
              } else if (piece.type == PieceType.pawn &&
                  (blackPOV ? p2.x < p1.x : p2.x > p1.x)) {
                control += colorVal(PieceColor.white);
              } else if (piece.type == PieceType.pawn &&
                  (blackPOV ? p2.x > p1.x : p2.x < p1.x)) {
                control += colorVal(PieceColor.black);
              }
            }
            clearLine = (piece.type == PieceType.none);
          }
        }
      }
    }
    return control;
  }

  int lineControl(Coord p1) {
    int control = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if ((dx == 0) ^ (dy == 0)) {
          Coord p2 = Coord.fromCoord(p1);
          bool clearLine = true;
          while (clearLine) {
            p2.add(dx, dy);
            clearLine = p2.squareBounds(8);
            if (clearLine) {
              Piece piece = getSquare(p2).piece;
              if (piece.type == PieceType.rook || piece.type == PieceType.queen) {
                control += colorVal(piece.color);
              } else if (p1.isAdjacent(p2)) {
                if (piece.type == PieceType.king) {
                  control += colorVal(piece.color);
                }
              }
              clearLine = (piece.type == PieceType.none);
            }
          }
        }
      }
    }
    return control;
  }

  Uint8List getLinearInterpolation() {
    int squareWidth = (width / ranks).floor();
    int squareHeight = (height / files).floor();
    int paddedBoardWidth = squareWidth * 10, paddedBoardHeight = squareHeight * 10;
    List<List<ColorArray>> pixArray = List<List<ColorArray>>.generate(
        paddedBoardWidth, (i) => List<ColorArray>.generate(
        paddedBoardHeight, (index) => ColorArray.fromFill(0), growable: false), growable: false);

    int w2 = (squareWidth/2).floor(), h2 = (squareHeight/2).floor();

    for (int my = -1; my < ranks; my++) {
      for (int mx = -1; mx < files; mx++) {

        Coord coordNW = Coord(mx, my);
        Coord coordNE = Coord(mx, my + 1);
        Coord coordSW = Coord(mx + 1, my);
        Coord coordSE = Coord(mx + 1, my + 1);

        ColorArray colorNW = coordNW.squareBounds(8) ? getSquare(coordNW).color : edgeCol;
        ColorArray colorNE = coordNE.squareBounds(8) ? getSquare(coordNE).color : edgeCol;
        ColorArray colorSW = coordSW.squareBounds(8) ? getSquare(coordSW).color : edgeCol;
        ColorArray colorSE = coordSE.squareBounds(8) ? getSquare(coordSE).color : edgeCol;

        int x = (((coordNW.y + 1) * squareWidth) + w2).floor();
        int y = (((coordNW.x + 1) * squareHeight) + h2).floor();

        for (int i = 0; i < 3; i++) {
          for (int x1 = 0; x1 < squareWidth; x1++) {
            double v = x1 / squareWidth;
            int ly = y + squareHeight;
            int x2 = x + x1;
            //interpolate right
            pixArray[y][x2].values[i] =
                lerp(v, colorNW.values[i], colorNE.values[i]).floor();
            pixArray[ly][x2].values[i] =
                lerp(v, colorSW.values[i], colorSE.values[i]).floor();
            //interpolate down
            for (int y1 = 0; y1 < squareHeight; y1++) {
              int y2 = y + y1;
              pixArray[y2][x2].values[i] = lerp(y1 / squareHeight,
                      pixArray[y][x2].values[i], pixArray[ly][x2].values[i])
                  .floor();
            }
          }
        }
      }
    }

    Uint8List imgData =  Uint8List(width * height * 4); //ctx.createImageData(board_dim.board_width,board_dim.board_height);
    for (int px = 0; px < height; px++) {
      for (int py = 0; py < width; py++) {
        int off = ((px * width) + py) * 4;
        int px2 = px + squareWidth;
        int py2 = py + squareHeight;
        imgData[off] = pixArray[px2][py2].values[0];
        imgData[off + 1] = pixArray[px2][py2].values[1];
        imgData[off + 2] = pixArray[px2][py2].values[2];
        imgData[off + 3] = 255;
      }
    }
    return imgData; //ctx.putImageData(imgData,board_dim.board_x,board_dim.board_y);
  }

  double lerp(double v, int start, int end) {
    return (1 - v) * start + v * end;
  }

}

class Square {
  Piece piece;
  int control = 0;
  ColorArray color = ColorArray.fromFill(0);
  Square(this.piece);

  void setControl(int c) {
    control = c;
    color = getTwoColor(ColorComponent.red, ColorComponent.green, ColorComponent.blue);
  }

  ColorArray getTwoColor(ColorComponent blackColor, ColorComponent voidColor,ColorComponent whiteColor) {
    List<int> colorMatrix = [0,0,0];
    double controlGrad = 256 / maxControl;
    int c = (control * controlGrad).round();
    if (c < 0) {
      colorMatrix[blackColor.index] = c.abs();
      colorMatrix[voidColor.index] = 0;
      colorMatrix[whiteColor.index] = 0;
    } else {
      colorMatrix[blackColor.index] = 0;
      colorMatrix[voidColor.index] = 0;
      colorMatrix[whiteColor.index] = c.abs();
    }
    return ColorArray(colorMatrix[0], colorMatrix[1], colorMatrix[2]);
  }
}

class Piece {
  late final PieceType type;
  late final PieceColor color;

  Piece(this.type,this.color);
  Piece.fromChar(String char) {
    type = _decodeChar(char);
    color = char == char.toUpperCase() ? PieceColor.white : PieceColor.black;
  }

  bool eq(PieceType t, PieceColor c) {
    return type == t && color == c;
  }

  PieceType _decodeChar(String char) {
    return switch(char.toUpperCase()) {
      "P" => PieceType.pawn,
      "N" => PieceType.knight,
      "B" => PieceType.bishop,
      "R" => PieceType.rook,
      "Q" => PieceType.queen,
      "K" => PieceType.king,
      _ => PieceType.none,
    };
  }

  @override
  String toString() {
    String pieceChar = (type == PieceType.knight) ? "n" : type.name[0];
    return (color == PieceColor.white ? "w" : "b") + pieceChar.toLowerCase();
  }
}

class Coord {
  int x,y;
  Coord(this.x,this.y);
  Coord.fromCoord(Coord p) : x = p.x, y = p.y;
  void add(int x1, int y1) {
    x += x1; y += y1;
  }
  bool squareBounds(int n) {
    return x >= 0 && y >= 0 && x < n && y < n;
  }
  bool isAdjacent(Coord p) {
    return (p.x - x).abs() < 2 && (p.y - y).abs() < 2;
  }
}

class ColorArray {
  final List<int> values;
  ColorArray.fromFill(final int v) : values = List.filled(3, 0);
  ColorArray(final int red, final int green, final int blue) : values = List.of([red,green,blue]);
}
