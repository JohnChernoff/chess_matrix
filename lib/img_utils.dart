import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:zug_utils/zug_utils.dart';
import 'board_matrix.dart';
import 'board_state.dart';
import 'chess.dart';
import 'main.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:image/image.dart' as img;

class ImgUtils {

  static final Map<String,img.Image?> pieceImages = {};

  static Future<void> setPieces(PieceStyle pieceStyle) async {
    for (PieceType t in PieceType.values) {
      if (t != PieceType.none) {
        final wPieceImg = await ZugUtils.imageToImgPkg(cb.ChessBoard.getPieceImage(pieceStyle.name,t.dartChessType,cb.Color.WHITE));
        pieceImages.update(Piece(t,ChessColor.white).toString(), (i) => wPieceImg, ifAbsent: () => wPieceImg);
        final bPieceImg = await ZugUtils.imageToImgPkg(cb.ChessBoard.getPieceImage(pieceStyle.name,t.dartChessType,cb.Color.BLACK));
        pieceImages.update(Piece(t,ChessColor.black).toString(), (i) => bPieceImg, ifAbsent: () => bPieceImg);
      }
    }
    mainLogger.i("Loaded Pieces");
  }

  static void createGifFile(BoardState state, int resolution, {PieceStyle pieceStyle = PieceStyle.horsey, MatrixColorScheme? colorScheme}) async {
    generateGIF(state, resolution, pieceStyle: pieceStyle, colorScheme: colorScheme).then((bytes) {
      if (bytes?.isNotEmpty ?? false) {
        FileSaver.instance.saveFile(
          name: "zenchess.gif",
          bytes: bytes,
          mimeType: MimeType.gif,
        );
      }
    });
  }

  static Future<Uint8List?> generateGIF(BoardState state, int resolution, {PieceStyle pieceStyle = PieceStyle.horsey, MatrixColorScheme? colorScheme}) async {
    if (state.moves.isEmpty) return null;
    await setPieces(pieceStyle);
    final encoder = img.GifEncoder();
    for (MoveState m in state.moves) {
      final matrix = BoardMatrix.fromFEN(m.afterFEN, width: resolution, height: resolution, colorScheme: colorScheme ?? ColorStyle.rainbow.colorScheme);
      final data = matrix.generateRawImage();
      img.Image image = img.Image.fromBytes(width: resolution, height: resolution, bytes: data.buffer, order: img.ChannelOrder.rgba); //, frameType: img.FrameType.animation);
      image = drawPieces(matrix,image, status: BoardStatus.draw);
      encoder.addFrame(image); //print("Adding frame: $image");
    }
    mainLogger.i("Writing GIF");
    return encoder.finish();
  }

  static img.Image drawPieces(BoardMatrix matrix, img.Image? boardImg, { int boardSize = 0, BoardStatus status = BoardStatus.playing }) {
    img.Image destImg = boardImg ?? img.Image(width: boardSize, height: boardSize);
    double squareWidth = destImg.width / files;
    double squareHeight = destImg.height / ranks;
    for (int rank = 0; rank < ranks; rank++) {
      for (int file = 0; file < files; file++) {
        final piece = matrix.getSquare(Coord(file,rank)).piece;
        img.Image? pieceImg = pieceImages[piece.toString()];
        if (pieceImg != null) {
          if (status == BoardStatus.blackWon && (piece.color != ChessColor.black || piece.type != PieceType.king)) img.pixelate(pieceImg, size: 24);
          if (status == BoardStatus.whiteWon && (piece.color != ChessColor.white || piece.type != PieceType.king)) img.pixelate(pieceImg, size: 24);
          if (status == BoardStatus.draw) pieceImg = img.copyRotate(pieceImg, angle: 45);
          boardImg = img.compositeImage(destImg, pieceImg,
              dstX: (squareWidth * file).floor(), dstY: (squareHeight * rank).floor(), dstW: squareWidth.floor(), dstH: squareHeight.floor());
        }
      }
    }
    return destImg;
  }

}