import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:m6_sudoku/features/sudoku/engine/bank/puzzle_bank.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

/// Loads the bundled `assets/puzzles/<difficulty>.txt` banks and draws new
/// games from them. Shared by the regular and cube games so every face of
/// an Evil cube is as genuinely Evil as a regular Evil game.
class PuzzleBankSource {
  PuzzleBankSource({
    Future<String> Function(String assetPath)? loadAsset,
    Random? random,
  }) : _loadAsset = loadAsset ?? rootBundle.loadString,
       _random = random ?? Random();

  final Future<String> Function(String assetPath) _loadAsset;
  final Random _random;
  final Map<Difficulty, Future<PuzzleBank?>> _banks = {};

  /// A puzzle for [difficulty], or null if its bank is missing, empty or
  /// unreadable — callers then fall back to live generation, so a bad
  /// asset degrades to the old behaviour rather than breaking New Game.
  Future<PuzzleGenerationResult?> draw(Difficulty difficulty) async {
    final bank = await _banks.putIfAbsent(difficulty, () => _load(difficulty));
    if (bank == null || bank.isEmpty) return null;
    return bank.draw(_random);
  }

  Future<PuzzleBank?> _load(Difficulty difficulty) async {
    try {
      final text = await _loadAsset('assets/puzzles/${difficulty.name}.txt');
      return PuzzleBank.parse(text);
    } catch (_) {
      return null;
    }
  }
}
