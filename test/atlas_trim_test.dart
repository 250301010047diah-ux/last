import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/game/atlas.dart';
import 'package:runtuh/game/atlas_metadata.dart';

ui.Rect _rect(Map m) => ui.Rect.fromLTWH(
    (m['x'] as num).toDouble(), (m['y'] as num).toDouble(),
    (m['w'] as num).toDouble(), (m['h'] as num).toDouble());

void main() {
  test('after trimming, no frame crop reaches into another frame', () {
    expect(atlasMetadata, isNotEmpty);
    var trimmedSheets = 0;
    for (final entry in atlasMetadata.entries) {
      final data = entry.value;
      final frames = [
        for (final f in data['frames'] as List)
          Frame(
            name: f['name'] as String,
            source: _rect(f['source'] as Map),
            content: f['content'] != null ? _rect(f['content'] as Map) : null,
          ),
      ];
      final before = [for (final f in frames) f.crop];
      trimFrameOverlaps(frames);
      if (!frames.every((f) => before[frames.indexOf(f)] == f.crop)) trimmedSheets++;
      for (int i = 0; i < frames.length; i++) {
        // Trimming only ever shrinks a crop, and never past its own cell.
        expect(before[i].contains(frames[i].crop.topLeft), isTrue);
        expect(frames[i].crop.overlaps(frames[i].source), isTrue,
            reason: '${entry.key} ${frames[i].name}');
        for (int j = i + 1; j < frames.length; j++) {
          final o = frames[i].crop.intersect(frames[j].crop);
          expect(o.width <= 0 || o.height <= 0, isTrue,
              reason: '${entry.key}: ${frames[i].name} x ${frames[j].name}');
        }
      }
    }
    // Sanity: the fix actually had something to do.
    expect(trimmedSheets, greaterThan(0));
  });
}
