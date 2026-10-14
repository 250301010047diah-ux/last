import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/flame.dart';

class Frame {
  Frame({
    required this.name,
    required this.source,
    this.content,
    this.anchor,
    this.surfaceY = 0,
    this.surfaceEdge,
  });

  final String name;
  final ui.Rect source;
  final ui.Rect? content;
  final ui.Offset? anchor;
  final double surfaceY;
  final String? surfaceEdge;

  /// Region of the sheet actually drawn: [content] (or [source]), trimmed
  /// where it would bleed into a neighbouring frame's art.
  late ui.Rect crop = content ?? source;
}

class Sheet {
  Sheet({
    required this.image,
    required this.frames,
    required this.frameMap,
    required this.animations,
    required this.animMaxHeight,
    this.refHeight,
  });

  final ui.Image image;
  final List<Frame> frames;
  final Map<String, Frame> frameMap;
  final Map<String, List<Frame>> animations;
  final Map<String, double> animMaxHeight;

  /// Sheet-wide height that maps to the requested draw height. Using one
  /// value for every animation keeps a character the same size when it
  /// switches animation (per-animation maxima differ by up to ~15%).
  final double? refHeight;

  List<Frame>? anim(String name) => animations[name];

  void drawAnim(
    ui.Canvas canvas,
    String animationName,
    double time,
    double anchorX,
    double anchorY,
    double targetHeight, {
    bool flip = false,
    double alpha = 1,
  }) =>
      drawAnimation(canvas, this, animationName, time, anchorX, anchorY,
          targetHeight, flip, alpha);
}

ui.Rect _rect(Map<String, dynamic> m) =>
    ui.Rect.fromLTWH(_d(m['x']), _d(m['y']), _d(m['w']), _d(m['h']));

double _d(dynamic v) => (v as num).toDouble();

Frame _parseFrame(Map<String, dynamic> m) {
  final anchorMap = m['anchor'];
  final anchor = anchorMap != null
      ? ui.Offset(_d(anchorMap['x']), _d(anchorMap['y']))
      : null;
  return Frame(
    name: m['name'] as String,
    source: _rect(m['source']),
    content: m['content'] != null ? _rect(m['content']) : null,
    anchor: anchor,
    surfaceY: m['surfaceY'] != null ? _d(m['surfaceY']) : 0,
    surfaceEdge: m['surfaceEdge'] as String?,
  );
}

Future<Sheet> loadSheet(String basename, bool withFrames) async {
  final image = await Flame.images.load('$basename.webp');
  final frameMap = <String, Frame>{};
  final animations = <String, List<Frame>>{};
  final frames = <Frame>[];
  final animMaxHeight = <String, double>{};
  double? refHeight;
  if (withFrames) {
    final data = await Flame.assets.readJson('json/$basename.frames.json');
    for (final f in (data['frames'] as List)) {
      final fr = _parseFrame(f as Map<String, dynamic>);
      frameMap[fr.name] = fr;
      frames.add(fr);
    }
    trimFrameOverlaps(frames);
    final grid = data['grid'];
    if (grid is Map && grid['frameHeight'] is num) {
      // Art overhangs its grid cell; 1.15x the cell is a typical content
      // height, so draw sizes stay close to what they were before.
      refHeight = (grid['frameHeight'] as num).toDouble() * 1.15;
    }
    // The JSON has a flat "frames" list (texture-packer style). Animations are
    // derived from the frame-name convention "<animName>_<index>".
    final groups = <String, List<Frame>>{};
    for (final fr in frames) {
      final name = fr.name;
      final idx = name.lastIndexOf('_');
      var animName = name;
      if (idx > 0 && RegExp(r'^\d+$').hasMatch(name.substring(idx + 1))) {
        animName = name.substring(0, idx);
      }
      (groups[animName] ??= <Frame>[]).add(fr);
    }
    groups.forEach((name, list) => animations[name] = list);

    for (final entry in animations.entries) {
      var maxH = 0.0;
      for (final f in entry.value) {
        final c = f.content ?? f.source;
        if (c.height > maxH) maxH = c.height;
      }
      animMaxHeight[entry.key] = maxH;
    }
  }
  return Sheet(
      image: image,
      frames: frames,
      frameMap: frameMap,
      animations: animations,
      animMaxHeight: animMaxHeight,
      refHeight: refHeight);
}

/// Some frames' content boxes reach into a neighbouring frame, so cropping
/// them would show a sliver of the neighbour's art. For every overlapping
/// pair, cut both crops at the midpoint between their grid cells, along the
/// axis where they overlap least. Frames without conflicts are untouched.
void trimFrameOverlaps(List<Frame> frames) {
  for (int i = 0; i < frames.length; i++) {
    for (int j = i + 1; j < frames.length; j++) {
      final a = frames[i];
      final b = frames[j];
      final overlap = a.crop.intersect(b.crop);
      if (overlap.width <= 0 || overlap.height <= 0) continue;
      final horizontal = overlap.width < overlap.height;
      final aFirst = horizontal
          ? a.source.center.dx < b.source.center.dx
          : a.source.center.dy < b.source.center.dy;
      final first = aFirst ? a : b;
      final second = aFirst ? b : a;
      if (horizontal) {
        final cut = (first.source.right + second.source.left) / 2;
        first.crop = ui.Rect.fromLTRB(first.crop.left, first.crop.top,
            math.min(first.crop.right, cut), first.crop.bottom);
        second.crop = ui.Rect.fromLTRB(math.max(second.crop.left, cut),
            second.crop.top, second.crop.right, second.crop.bottom);
      } else {
        final cut = (first.source.bottom + second.source.top) / 2;
        first.crop = ui.Rect.fromLTRB(first.crop.left, first.crop.top,
            first.crop.right, math.min(first.crop.bottom, cut));
        second.crop = ui.Rect.fromLTRB(second.crop.left,
            math.max(second.crop.top, cut), second.crop.right, second.crop.bottom);
      }
    }
  }
}

ui.Paint _alphaPaint(double alpha) {
  if (alpha >= 1) return ui.Paint();
  return ui.Paint()
    ..colorFilter = ui.ColorFilter.mode(
      ui.Color.fromARGB((alpha * 255).round(), 255, 255, 255),
      ui.BlendMode.modulate,
    );
}

void drawFrameInBox(ui.Canvas canvas, Sheet? sheet, String frameName, double x,
    double y, double w, double h,
    [double alpha = 1]) {
  if (sheet == null) return;
  final frame = sheet.frameMap[frameName];
  if (frame == null) return;
  final crop = frame.crop;
  final scale = math.min(w / crop.width, h / crop.height);
  final dw = crop.width * scale;
  final dh = crop.height * scale;
  final dx = x + (w - dw) / 2;
  final dy = y + (h - dh) / 2;
  canvas.drawImageRect(
    sheet.image,
    crop,
    ui.Rect.fromLTWH(dx, dy, dw, dh),
    _alphaPaint(alpha),
  );
}

void drawAnimation(ui.Canvas canvas, Sheet? sheet, String animationName,
    double time, double anchorX, double anchorY, double targetHeight,
    [bool flip = false, double alpha = 1]) {
  if (sheet == null) return;
  final frames = sheet.animations[animationName];
  if (frames == null || frames.isEmpty) return;
  final frame = frames[(time * 9).floor() % frames.length];
  final crop = frame.crop;
  final refHeight = sheet.refHeight ?? sheet.animMaxHeight[animationName] ?? 0.0;
  if (refHeight <= 0) return;
  final scale = targetHeight / refHeight;
  final anchor = frame.anchor ??
      ui.Offset(frame.source.left + frame.source.width / 2,
          frame.source.top + frame.source.height);
  final dx = (crop.left - anchor.dx) * scale;
  final dy = (crop.top - anchor.dy) * scale;
  canvas.save();
  canvas.translate(anchorX, anchorY);
  if (flip) canvas.scale(-1, 1);
  canvas.drawImageRect(
    sheet.image,
    crop,
    ui.Rect.fromLTWH(dx, dy, crop.width * scale, crop.height * scale),
    _alphaPaint(alpha),
  );
  canvas.restore();
}

void drawCover(ui.Canvas canvas, Sheet? sheet, double w, double h) {
  if (sheet == null) return;
  final img = sheet.image;
  final scale = math.max(w / img.width, h / img.height);
  final dw = img.width * scale;
  final dh = img.height * scale;
  canvas.drawImageRect(
    sheet.image,
    ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    ui.Rect.fromLTWH((w - dw) / 2, (h - dh) / 2, dw, dh),
    _alphaPaint(1),
  );
}
