import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:altodevmobile/models/relation_session.dart';

/// Persists relation sessions and the currently active one.
class RelationStorage {
  // Storage keys for relation sessions and active session
  static const String _activeSessionKey = 'relation_active_session_v1';
  static const String _activeRelationCodeKey = 'relation_active_code_v1';
  static const String _sessionsKey = 'relation_sessions_v1';
  final FlutterSecureStorage _storage;

  RelationStorage(this._storage);

  Future<void> saveActiveSession(RelationSession session) async {
    await upsertSession(session);
    await setActiveRelationCode(session.myRelationCode);
    await _storage.write(key: _activeSessionKey, value: session.toJson());
  }

  Future<void> upsertSession(RelationSession session) async {
    final sessions = await readAllSessions();
    int index = -1;
    for (int i = 0; i < sessions.length; i++) {
      if (sessions[i].myRelationCode == session.myRelationCode) {
        index = i;
        break;
      }
    }

    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }

    final encoded = jsonEncode(sessions.map((s) => s.toMap()).toList());
    await _storage.write(key: _sessionsKey, value: encoded);
  }

  Future<List<RelationSession>> readAllSessions() async {
    final raw = await _storage.read(key: _sessionsKey);
    if (raw == null || raw.trim().isEmpty) {
      final active = await _readLegacyActiveSession();
      return active == null ? <RelationSession>[] : <RelationSession>[active];
    }

    try {
      final decoded = jsonDecode(raw);

      final isList = decoded is List;
      if (!isList) return <RelationSession>[];

      final sessions = <RelationSession>[];

      for (final item in decoded) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final session = RelationSession.fromMap(map);
          sessions.add(session);
        }
      }

      return sessions;
    } catch (_) {
      return <RelationSession>[];
    }
  }

  Future<void> setActiveRelationCode(String relationCode) async {
    await _storage.write(key: _activeRelationCodeKey, value: relationCode);
  }

  Future<RelationSession?> readActiveSession() async {
    final activeCode = await _storage.read(key: _activeRelationCodeKey);
    if (activeCode != null && activeCode.trim().isNotEmpty) {
      final sessions = await readAllSessions();
      for (final session in sessions) {
        if (session.myRelationCode == activeCode.trim()) {
          return session;
        }
      }
    }

    final legacy = await _readLegacyActiveSession();
    if (legacy != null) await saveActiveSession(legacy);
    return legacy;
  }

  Future<void> clearActiveSession() async {
    await _storage.delete(key: _activeRelationCodeKey);
    await _storage.delete(key: _activeSessionKey);
  }

  Future<RelationSession?> _readLegacyActiveSession() async {
    final raw = await _storage.read(key: _activeSessionKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return RelationSession.fromJson(raw);
    } catch (_) {
      return null;
    }
  }
}
