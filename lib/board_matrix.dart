import 'dart:js' as js;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
const emptyVal = 0, pawnVal = 1, knightVal = 2, bishopVal = 3, rookVal = 4, queenVal = 5, kingVal = 6;
const ranks = 8, files = 8;
const Color deepBlue = Color(0xFF0000FF);
const Color deepRed = Color(0xFFFF0000);
const Color deepYellow = Color(0xFFFFFF00);

enum ColorComponent {red,green,blue}
enum ColorStyle {
  heatmap(MatrixColorScheme(deepBlue,deepRed,Colors.black)),
  lava(MatrixColorScheme(deepYellow,deepRed,Colors.black)),
  rainbow(MatrixColorScheme(deepYellow,deepBlue,Colors.black)),
  forest(MatrixColorScheme(Color(0xffd8ffb0),Color(0xff171717),Color(0xff76c479),blackPieceBlendColor: Color(0xff92cf94),whitePieceBlendColor: Color(0xff14ffe9))),
  mono(MatrixColorScheme(Colors.white,Colors.black,Colors.grey)),
  ;
  final MatrixColorScheme colorScheme;
  const ColorStyle(this.colorScheme);
}
enum MixStyle {pigment,checker,add}
enum ChessColor {none,white,black}
enum PieceType {none,pawn,knight,bishop,rook,queen,king}

class BoardMatrix {
  final String fen;
  final int width, height;
  final int maxControl;
  final List<List<Square>> squares = List<List<Square>>.generate(
      ranks, (i) => List<Square>.generate(
      files, (index) => Square(
        Piece(PieceType.none,ChessColor.none),
      (index + i).isEven ? SquareShade.light : SquareShade.dark), growable: false), growable: false);
  final Color edgeColor;
  final MatrixColorScheme colorScheme;
  final MixStyle mixStyle;
  final Move? lastMove;
  final bool blackPOV;
  final bool triColor = true;
  late final ChessColor turn;
  ui.Image? image;

  BoardMatrix(this.fen,this.lastMove,this.width,this.height,this.colorScheme,this.mixStyle,imgCall,{this.blackPOV  = false, this.maxControl = 5, this.edgeColor = Colors.black}) {
    List<String> fenStrs = fen.split(" ");
    turn = fenStrs[1] == "w" ? ChessColor.white : ChessColor.black;
    _setPieces(fenStrs[0]);
    updateControl();
    ui.decodeImageFromPixels(getLinearInterpolation(), width, height, ui.PixelFormat.rgba8888, (ui.Image img) {
      image = img;
      imgCall();
    });
  }

  void _setPieces(String boardStr) {
    List<String> fenRanks = boardStr.split("/");
    for (int rank = 0; rank < fenRanks.length; rank++) {
      int file = 0;
      for (int i = 0; i < fenRanks[rank].length; i++) {
        String char = fenRanks[rank][i];
        Piece piece = Piece.fromChar(char);
        if (piece.type == PieceType.none) {
          file += int.parse(char); //todo: try
        } else {
          if (blackPOV) {
            squares[fenRanks.length - 1 - file++][fenRanks.length - 1 - rank].piece = piece;
          } else {
            squares[file++][rank].piece = piece;
          }
        }
      }
    }
  }

  List<Square> getSquares() {
    List<Square> squareList = [];
    for (int y = 0; y < ranks; y++) {
      for (int x = 0; x < files; x++) {
        squareList.add(squares[x][y]);
      }
    }
    return squareList;
  }

  int colorVal(ChessColor color) {
    return color == ChessColor.black ? -1 : color == ChessColor.white ? 1 : 0;
  }

  bool isPiece(Coord p, PieceType t) {
    return getSquare(p).piece.type == t;
  }

  Square getSquare(Coord p) {
    return squares[p.x][p.y];
  }

  void updateControl() {
    for (int y = 0; y < ranks; y++) {
      for (int x = 0; x < files; x++) {
        squares[x][y].setControl(calcControl(Coord(x,y)),colorScheme,mixStyle,maxControl);
      }
    }
  }

  ControlTable calcControl(Coord p) {
    ControlTable control = const ControlTable(0, 0);
    control = control.add(knightControl(p));
    control = control.add(diagControl(p));
    control = control.add(lineControl(p));
    return control;
  }

  ControlTable knightControl(Coord p) {
   int blackControl = 0, whiteControl = 0;
    for (int x = -2; x <= 2; x++) {
      for (int y = -2; y <= 2; y++) {
        if ((x.abs() + y.abs()) == 3) {
          Coord p2 = Coord(p.x + x,  p.y + y);
          if (p2.x >= 0 && p2.x < 8 && p2.y >= 0 && p2.y < 8) {
            Piece piece = getSquare(p2).piece;
            if (piece.type == PieceType.knight) {
              piece.color == ChessColor.black ? blackControl++ : whiteControl++;
            }
          }
        }
      }
    }
    return ControlTable(whiteControl,blackControl);
  }

  ControlTable diagControl(Coord p1) {
    int blackControl = 0, whiteControl = 0;
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
              piece.color == ChessColor.black ? blackControl++ : whiteControl++;
            } else if (p1.isAdjacent(p2)) {
              if (piece.type == PieceType.king) {
                piece.color == ChessColor.black ? blackControl++ : whiteControl++;
              } else if (piece.type == PieceType.pawn && piece.color == ChessColor.white && (blackPOV ? p1.y > p2.y : p1.y < p2.y)) {
                whiteControl++;
              } else if (piece.type == PieceType.pawn && piece.color == ChessColor.black && (blackPOV ? p1.y < p2.y : p1.y > p2.y)) {
                blackControl++;
              }
            }
            clearLine = (piece.type == PieceType.none);
          }
        }
      }
    }
    return ControlTable(whiteControl,blackControl);
  }

  ControlTable lineControl(Coord p1) {
    int whiteControl = 0, blackControl = 0;
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
                piece.color == ChessColor.black ? blackControl++ : whiteControl++;
              } else if (p1.isAdjacent(p2)) {
                if (piece.type == PieceType.king) {
                  piece.color == ChessColor.black ? blackControl++ : whiteControl++;
                }
              }
              clearLine = (piece.type == PieceType.none);
            }
          }
        }
      }
    }
    return ControlTable(whiteControl,blackControl);
  }

  Uint8List getLinearInterpolation() {
    int squareWidth = (width / ranks).floor();
    int squareHeight = (height / files).floor();
    int paddedBoardWidth = squareWidth * 10, paddedBoardHeight = squareHeight * 10;
    List<List<ColorArray>> pixArray = List<List<ColorArray>>.generate(
        paddedBoardWidth, (i) => List<ColorArray>.generate(
        paddedBoardHeight, (index) => ColorArray.fromFill(0), growable: false), growable: false);

    int w2 = (squareWidth/2).floor(), h2 = (squareHeight/2).floor();
    ColorArray edgeCol = ColorArray(edgeColor.red,edgeColor.green,edgeColor.blue);

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

        //TODO: unreverse this?
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
    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        int off = ((py * height) + px) * 4;
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

class ControlTable {
  final int whiteControl;
  final int blackControl;
  int get totalControl => whiteControl - blackControl;
  const ControlTable(this.whiteControl,this.blackControl);
  ControlTable add(ControlTable ctab) {
    return ControlTable(whiteControl + ctab.whiteControl, blackControl + ctab.blackControl);
  }
  @override
  String toString() {
    return "[$whiteControl,$blackControl,$totalControl]";
  }
}

enum SquareShade {
  light,dark
}

class Square {
  final Color bigRed = const Color.fromARGB(255, 255, 0, 0);
  final Color bigGreen = const Color.fromARGB(255, 0,255, 0);
  final Color bigBlue = const Color.fromARGB(255, 0,0, 255);
  SquareShade shade;
  Piece piece;
  ControlTable control = const ControlTable(0, 0);
  ColorArray color = ColorArray.fromFill(0);
  Square(this.piece,this.shade);

  void setControl(ControlTable c, MatrixColorScheme colorScheme, MixStyle mixStyle, int maxControl) {
    control = c;
    color = switch(mixStyle) {
      MixStyle.add => getAddidiveColor(colorScheme, maxControl),
      MixStyle.checker => getCheckerColor(colorScheme, maxControl),
      MixStyle.pigment => getMixColor(colorScheme, maxControl),
    };
  }

  ColorArray getAddidiveColor(MatrixColorScheme colorScheme, int maxControl) {
    ColorArray colorMatrix = ColorArray.fromColor(colorScheme.voidColor);
    double controlGrad =  min(control.totalControl.abs(),maxControl) / maxControl;
    if (control.totalControl > 0) {
      colorMatrix.addRed = ((colorScheme.whiteColor.red - colorScheme.voidColor.red) * controlGrad).floor();
      colorMatrix.addGreen = ((colorScheme.whiteColor.green - colorScheme.voidColor.green) * controlGrad).floor();
      colorMatrix.addBlue = ((colorScheme.whiteColor.blue - colorScheme.voidColor.blue) * controlGrad).floor();
    } else if (control.totalControl < 0) {
      colorMatrix.addRed = ((colorScheme.blackColor.red - colorScheme.voidColor.red) * controlGrad).floor();
      colorMatrix.addGreen = ((colorScheme.blackColor.green - colorScheme.voidColor.green) * controlGrad).floor();
      colorMatrix.addBlue = ((colorScheme.blackColor.blue - colorScheme.voidColor.blue) * controlGrad).floor();
    }
    //if (control != 0) print("${voidColor.red},${voidColor.green},${voidColor.blue} -> ${colorMatrix.values}");
    return colorMatrix;
  }

  ColorArray getCheckerColor(MatrixColorScheme colorScheme, int maxControl) {
    double whiteControlGrad =  min(control.whiteControl,maxControl) / maxControl;
    double blackControlGrad =  min(control.blackControl,maxControl) / maxControl;
    return ColorArray(
      (255 * blackControlGrad).floor(),
      shade == SquareShade.dark ? 0 : 255,
      (255 * whiteControlGrad).floor(),
    );
  }

  ColorArray getMixColor(MatrixColorScheme colorScheme, int maxControl) {
    double whiteControlGrad =  min(control.whiteControl,maxControl) / maxControl;
    double blackControlGrad =  min(control.blackControl,maxControl) / maxControl;

    ColorArray whiteMatrix = ColorArray(
        (colorScheme.whiteColor.red * whiteControlGrad).floor(),
        (colorScheme.whiteColor.green * whiteControlGrad).floor(),
        (colorScheme.whiteColor.blue * whiteControlGrad).floor());

    ColorArray blackMatrix = ColorArray(
        (colorScheme.blackColor.red * blackControlGrad).floor(),
        (colorScheme.blackColor.green * blackControlGrad).floor(),
        (colorScheme.blackColor.blue * blackControlGrad).floor());

    if (control.whiteControl == 0 && control.blackControl >  0) {
      return blackMatrix;
    } else if (control.whiteControl > 0 && control.blackControl == 0) {
      return whiteMatrix;
    } else if (control.whiteControl == 0 && control.blackControl == 0) {
      return ColorArray.fromColor(colorScheme.voidColor);
    }
    var mixedColor = js.context.callMethod("mixColors",[
      whiteMatrix.red,whiteMatrix.green,whiteMatrix.blue,
      blackMatrix.red,blackMatrix.green,blackMatrix.blue,
      .5
    ]); //print("Mixed Color: $mixedColor");
    return ColorArray(mixedColor[0], mixedColor[1], mixedColor[2]);
  }
}

class Piece {
  late final PieceType type;
  late final ChessColor color;

  Piece(this.type,this.color);
  Piece.fromChar(String char) {
    type = _decodeChar(char);
    color = char == char.toUpperCase() ? ChessColor.white : ChessColor.black;
  }

  bool eq(PieceType t, ChessColor c) {
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
  String toString({bool white = false}) {
    String pieceChar = (type == PieceType.knight) ? "n" : (type == PieceType.none) ? "-" : type.name[0];
    return (white || color == ChessColor.white ? "w" : "b") + pieceChar.toUpperCase();
  }
}

class Move {
  final String moveStr;
  late final Coord from, to;
  Move(this.moveStr) {
    from = Coord(moveStr.codeUnitAt(0) - "a".codeUnitAt(0),7 - (moveStr.codeUnitAt(1) - "1".codeUnitAt(0)));
    to = Coord(moveStr.codeUnitAt(2) - "a".codeUnitAt(0),7 - (moveStr.codeUnitAt(3) - "1".codeUnitAt(0)));
  }
  static coord2Int(Coord c) {
    return c.x + (c.y * ranks);
  }
  bool eq(Move move) {
    return from.eq(move.from) && to.eq(move.to);
  }
  @override
  String toString() {
    return moveStr;
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
  bool eq(Coord p) {
    return x == p.x && y == p.y;
  }
  @override
  String toString() {
    return "[$x,$y]";
  }
}

class ColorArray {
  final List<int> values;
  int get red => values[0]; set addRed(int i) => values[0] += i;
  int get green => values[1]; set addGreen(int i) => values[1] += i;
  int get blue => values[2]; set addBlue(int i) => values[2] += i;
  ColorArray.fromFill(final int v) : values = List.filled(3, 0);
  ColorArray.fromColor(Color c) : values = [c.red,c.green,c.blue];
  ColorArray(final int red, final int green, final int blue) : values = List.of([red,green,blue]);
}

class MatrixColorScheme {
  final Color whiteColor;
  final Color blackColor;
  final Color voidColor;
  final Color whitePieceBlendColor;
  final Color blackPieceBlendColor;
  final Color gridColor;
  final Color edgeColor;

  const MatrixColorScheme(this.whiteColor,this.blackColor,this.voidColor, {
    this.whitePieceBlendColor = const Color.fromARGB(255, 255, 231, 20 ),
    this.blackPieceBlendColor = const Color.fromARGB(255, 20, 255, 233 ),
    this.gridColor = const Color.fromARGB(72, 255, 255, 255),
    this.edgeColor = Colors.black,
  });
}

Color rndCol() {
  return Colors.primaries[Random().nextInt(Colors.primaries.length)];
}