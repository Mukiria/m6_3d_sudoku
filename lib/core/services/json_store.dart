import 'dart:convert';

import 'package:dartz/dartz.dart';

import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';

/// Factors out the "JSON-encoded value under one SharedPreferences key"
/// boilerplate every `*_local_datasource.dart` used to repeat by hand: a
/// try/catch around `jsonDecode`/`fromJson` (or a default when the key is
/// missing) returning `Either<Failure, T>`, and the write-side mirror.
///
/// This is deliberately thin. It does not know about caching, read-modify-
/// write cycles, schema versioning, or any entity-specific policy — each
/// datasource still owns its own keys and that orchestration logic; this
/// only replaces the encode/decode/try-catch shell that was copy-pasted
/// once per entity. A datasource whose read or write doesn't fit this exact
/// shape (a mutating cache pop, a version check, a silently-swallowed
/// error) is expected to stay hand-written rather than be forced through
/// here.
class JsonStore {
  JsonStore(this._storage);

  final StorageService _storage;

  /// Reads [key] and JSON-decodes it with [decode], or returns [orElse]'s
  /// result if the key is missing. [label] names the operation for the
  /// failure message: `'Failed to $label: $e'`.
  Either<Failure, T> readJson<T>(
    String key,
    T Function(dynamic decoded) decode,
    T Function() orElse,
    String label,
  ) {
    try {
      final jsonString = _storage.getString(key);
      if (jsonString == null) return Right(orElse());
      return Right(decode(jsonDecode(jsonString)));
    } catch (e) {
      return Left(CacheFailure('Failed to $label: $e'));
    }
  }

  /// JSON-encodes [encodable] and writes it to [key]. [label] names the
  /// operation for the failure message: `'Failed to $label: $e'`.
  Future<Either<Failure, void>> writeJson(
    String key,
    Object? encodable,
    String label,
  ) async {
    try {
      await _storage.setString(key, jsonEncode(encodable));
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to $label: $e'));
    }
  }

  /// Removes every key in [keys]. [label] names the operation for the
  /// failure message: `'Failed to $label: $e'`.
  Future<Either<Failure, void>> removeKeys(
    List<String> keys,
    String label,
  ) async {
    try {
      for (final key in keys) {
        await _storage.remove(key);
      }
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to $label: $e'));
    }
  }
}
