import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

/// Effects are synthesized as WAV bytes so the app ships without audio assets.
enum Sfx {
  tap([880], 40),
  correct([523, 659, 784, 1047], 110),
  wrong([330, 220], 160);

  const Sfx(this.notes, this.ms);
  final List<int> notes;
  final int ms;
}

final _player = AudioPlayer();
final _cache = <Sfx, Uint8List>{};

void playSfx(WidgetRef ref, Sfx s) {
  if (!ref.read(settingsProvider).sound) return;
  _player.stop().then((_) => _player.play(BytesSource(_cache[s] ??= _wav(s), mimeType: 'audio/wav')));
}

Uint8List _wav(Sfx s) {
  const rate = 22050;
  final per = rate * s.ms ~/ 1000;
  final n = per * s.notes.length;
  final b = ByteData(44 + n * 2);
  void str(int o, String v) => v.codeUnits.asMap().forEach((i, c) => b.setUint8(o + i, c));
  str(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVEfmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, rate, Endian.little);
  b.setUint32(28, rate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  str(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final t = i % per;
    final fade = math.min(1.0, math.min(t, per - t) / (rate * 0.005)); // avoid clicks
    final v = math.sin(2 * math.pi * s.notes[i ~/ per] * i / rate) * fade * 0.3;
    b.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}
