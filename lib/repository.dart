import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'math_engine.dart';

final authProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

/// Rebuilt whenever the signed-in user changes, which also resets the game.
final repoProvider = Provider<Repo>((ref) {
  final uid = ref.watch(authProvider.select((_) => FirebaseAuth.instance.currentUser?.uid));
  return Repo(uid ?? '');
});

class Profile {
  Profile(this.score, this.solved);

  int score;

  /// level → number ("0427") → LaTeX of the user's solution.
  final Map<Level, Map<String, String>> solved;

  bool isSolved(Level l, String n) => solved[l]!.containsKey(n);

  factory Profile.fromData(Map<String, dynamic>? d) {
    // Tolerates fields of the wrong type so a bad document cannot lock the user out.
    Map map(Object? v) => v is Map ? v : const {};
    final score = d?['score'];
    final raw = map(d?['solved']);
    return Profile(score is num && score.isFinite ? score.toInt() : 0, {
      for (final l in Level.values)
        l: {
          for (final e in map(raw[l.name]).entries)
            '${e.key}': switch (map(e.value)['latex']) { final String s => s, _ => '' },
        },
    });
  }
}

/// Firestore layout: users/{uid} = {score, email, solved: {level: {number: {latex, at}}}}
class Repo {
  Repo(this.uid);
  final String uid;
  Future<Profile>? _profile;

  /// Last profile loaded, kept in sync with [markSolved].
  Profile? current;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  static const _timeout = Duration(seconds: 12);

  Future<Profile> _load() async => current = Profile.fromData((await _doc.get().timeout(_timeout)).data());

  Future<Profile> profile() => _profile ??= _load();

  Future<Profile> reload() => _profile = _load();

  Future<void> markSolved(Level level, String number, String latex) async {
    final p = await profile();
    if (p.isSolved(level, number)) return;
    // A transaction needs the server, so offline it fails within the timeout
    // instead of queueing forever, and a retry can never score the number twice.
    // ponytail: score is client-incremented; a cheater can edit their own doc. Move scoring to a Cloud Function if a public ranking is added.
    await FirebaseFirestore.instance.runTransaction((tx) async {
      if (Profile.fromData((await tx.get(_doc)).data()).isSolved(level, number)) return;
      tx.set(_doc, {
        'email': FirebaseAuth.instance.currentUser?.email,
        'score': FieldValue.increment(level.points),
        'solved': {
          level.name: {
            number: {'latex': latex, 'at': FieldValue.serverTimestamp()},
          },
        },
      }, SetOptions(merge: true));
    }, timeout: _timeout, maxAttempts: 2).timeout(_timeout);
    p.score += level.points;
    p.solved[level]![number] = latex;
  }
}

/// Why a Firestore call failed, so the UI can explain it in the user's language.
enum CloudError { offline, denied, unknown }

CloudError cloudError(Object? e) => switch (e) {
  TimeoutException() => CloudError.offline,
  FirebaseException(code: 'unavailable' || 'deadline-exceeded' || 'network-request-failed') => CloudError.offline,
  FirebaseException(code: 'permission-denied' || 'unauthenticated') => CloudError.denied,
  _ => CloudError.unknown,
};
