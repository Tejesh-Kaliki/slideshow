import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum CustomTextStyle {
  boxed,
  color,
  italic,
  heading,
  normal,
  headingSide,
  boxedSide
}

ui.ParagraphStyle normalStyle = ui.ParagraphStyle(
  textDirection: ui.TextDirection.ltr,
);

ui.ParagraphStyle centeredStyle = ui.ParagraphStyle(
  textDirection: ui.TextDirection.ltr,
  textAlign: ui.TextAlign.center,
);

Map<String, CustomTextStyle> styleMap = {
  "b": CustomTextStyle.boxed,
  "bs": CustomTextStyle.boxedSide,
  "i": CustomTextStyle.italic,
  "c": CustomTextStyle.color,
  "h": CustomTextStyle.heading,
  "hs": CustomTextStyle.headingSide
};

Future<bool> getStorageAccess() async {
  PermissionStatus status = await Permission.storage.request();
  return status.isGranted;
}

class TextBit {
  TextBit(String text,
      {CustomTextStyle textStyle = CustomTextStyle.normal,
      double fontSize = 50})
      : this.text = text,
        this.fontSize = fontSize,
        textType = textStyle;

  final String text;
  final double fontSize;
  final CustomTextStyle textType;

  ui.TextStyle getTextStyle(double scale) {
    return ui.TextStyle(
      fontFamily: "EuclidCircularA",
      fontSize: fontSize * scale,
      color:
          [CustomTextStyle.boxed, CustomTextStyle.boxedSide].contains(textType)
              ? Colors.white
              : textType == CustomTextStyle.color
                  ? Colors.green
                  : Colors.black,
      fontWeight: [CustomTextStyle.heading, CustomTextStyle.headingSide]
              .contains(textType)
          ? FontWeight.w700
          : FontWeight.normal,
      fontStyle: textType == CustomTextStyle.italic
          ? FontStyle.italic
          : FontStyle.normal,
    );
  }
}

/// Max width must be constant, for now
class Sentence {
  List<TextBit> textBits = [];
  Map<double, List<ui.Paragraph>> boxParagraphPerScale = {};
  Map<double, ui.Paragraph> paragraphPerScale = {};
  String rawSentence;

  Sentence.parseFrom(String text) {
    rawSentence = text;
    RegExp exp = RegExp(r"\.(b|c|i|h|hs|bs)\.");
    CustomTextStyle currentStyle = CustomTextStyle.normal;
    while (text.length > 0) {
      if (!text.contains(exp)) break;
      int start = text.indexOf(exp);
      int end = text.indexOf(".", start + 1);

      if (start > 0)
        textBits.add(
          TextBit(
            text.substring(0, start),
            textStyle: currentStyle,
            fontSize: currentStyle == CustomTextStyle.heading ||
                    currentStyle == CustomTextStyle.headingSide
                ? 70
                : 50,
          ),
        );

      String key = text.substring(start + 1, end);
      print(key);
      text = text.substring(end + 1);

      if (styleMap[key] == currentStyle)
        currentStyle = CustomTextStyle.normal;
      else if (currentStyle == CustomTextStyle.normal)
        currentStyle = styleMap[key];
      else
        break;
    }
    if (text.length > 0) textBits.add(TextBit(text));
  }

  ///return or render+return paragraph
  ui.Paragraph getRenderedParagraph(double scale, double maxWidth) =>
      paragraphPerScale.putIfAbsent(
          scale, () => renderFinalParagraph(scale, maxWidth));

  /// return or render+rerurn boxes
  List<ui.Paragraph> getRenderedBoxes(double scale) =>
      boxParagraphPerScale.putIfAbsent(scale, () => renderBoxParagraphs(scale));

  ui.Paragraph renderFinalParagraph(double scale, double maxWidth) {
    // if Sentence is a heading
    if (textBits[0].textType == CustomTextStyle.heading) {
      ui.ParagraphBuilder pb = ui.ParagraphBuilder(centeredStyle)
        ..pushStyle(textBits[0].getTextStyle(scale))
        ..addText(textBits[0].text)
        ..pop();
      return pb.build()..layout(ui.ParagraphConstraints(width: maxWidth));
    }
    double boxPadding = 15 * scale;

    ui.ParagraphBuilder finalBuilder = ui.ParagraphBuilder(normalStyle);
    List<ui.Paragraph> boxParagraphs = getRenderedBoxes(scale);
    int i = 0;

    for (TextBit tb in textBits) {
      if ([CustomTextStyle.boxed, CustomTextStyle.boxedSide]
          .contains(tb.textType)) {
        finalBuilder
          ..addPlaceholder(
            boxParagraphs[i].width + boxPadding,
            boxParagraphs[i].height + boxPadding,
            ui.PlaceholderAlignment.baseline,
            baseline: ui.TextBaseline.alphabetic,
            baselineOffset: boxParagraphs[i].height,
          );
        i++;
      } else {
        finalBuilder
          ..pushStyle(tb.getTextStyle(scale))
          ..addText(tb.text)
          ..pop();
      }
    }

    return finalBuilder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
  }

  List<ui.Paragraph> renderBoxParagraphs(double scale) {
    List<ui.Paragraph> result = [];
    double boxPadding = 15 * scale;

    for (var tb in textBits) {
      if ([CustomTextStyle.boxed, CustomTextStyle.boxedSide]
          .contains(tb.textType)) {
        ui.ParagraphBuilder pb = ui.ParagraphBuilder(
            tb.textType == CustomTextStyle.boxed ? centeredStyle : normalStyle)
          ..pushStyle(tb.getTextStyle(scale))
          ..addText(tb.text)
          ..pop();
        ui.Paragraph p = pb.build()
          ..layout(const ui.ParagraphConstraints(width: 10));
        p.layout(
            ui.ParagraphConstraints(width: p.maxIntrinsicWidth + boxPadding));
        result.add(p);
      }
    }

    return result;
  }
}

class MyPainter extends CustomPainter {
  List<Sentence> sentences;

  MyPainter(List<Sentence> sentences) : this.sentences = sentences;

  static void saveAsPicture(List<Sentence> sentences, String name) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(
        recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(1920.0, 1080.0)));

    // draw on canvas
    Paint paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, 1920, 1080), paint);
    drawText(
      canvas,
      sentences,
      boxPadding: 15,
      offset: Offset(100, 100),
      lineWidth: 1700,
    );

    //save to device
    ui.Picture pic = recorder.endRecording();
    ui.Image img = await pic.toImage(1920, 1080);
    ByteData byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    Uint8List byteList = byteData.buffer.asUint8List();

    bool hasAccess = await getStorageAccess();

    Directory dir;
    if (Platform.isAndroid && hasAccess) {
      dir = Directory("/storage/emulated/0/DCIM/slideshow");
      if (!dir.existsSync()) await dir.create(recursive: true);
    } else
      dir = await getExternalStorageDirectory();
    print(dir.path);
    File("${dir.path}/$name.png")
      ..createSync()
      ..writeAsBytesSync(byteList);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    drawText(
      canvas,
      sentences,
      boxPadding: 15,
      offset: Offset(100, 100),
      lineWidth: 1700,
      scale: size.width / 1920.0,
    );
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.sentences != this.sentences;
  }

  static void drawText(Canvas canvas, List<Sentence> sentences,
      {double boxPadding,
      Offset offset,
      double lineWidth,
      double scale = 1.0}) {
    offset *= scale;
    lineWidth *= scale;
    boxPadding *= scale;
    for (var sentence in sentences) {
      final paragraph = sentence.getRenderedParagraph(scale, lineWidth);
      canvas.drawParagraph(paragraph, offset);
      addBoxedText(
          paragraph, offset, scale, canvas, sentence.getRenderedBoxes(scale));
      offset += Offset(0, paragraph.height + 50 * scale);
    } // looping sentences
  }

  static void addBoxedText(ui.Paragraph paragraph, ui.Offset offset,
      double scale, ui.Canvas canvas, List<ui.Paragraph> boxParagraphs) {
    double boxPadding = 15 * scale;

    List<ui.TextBox> boxes = paragraph.getBoxesForPlaceholders();
    for (int i = 0; i < boxes.length; i++) {
      TextBox box = boxes[i];
      double left = box.left + offset.dx,
          top = box.top + offset.dy,
          width = box.right - box.left,
          height = box.bottom - box.top;

      // draw box
      canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, width, height),
            Radius.circular(boxPadding * 3 / 4),
          ),
          Paint()..color = Colors.grey);

      // draw text in box
      canvas.drawParagraph(
          boxParagraphs[i],
          Offset(left + boxPadding / 2,
              top + height / 2 - boxParagraphs[i].height / 2));
    }
  }
}
