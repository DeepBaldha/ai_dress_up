import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart';

/// A [StateNotifier] that manages user credit balance securely.
class CreditNotifier extends StateNotifier<int> {
  static const _storageKey = 'user_credit';
  final FlutterSecureStorage _storage;

  CreditNotifier(this._storage) : super(0) {
    _loadCredit();
  }

  bool canAfford(int cost) => state >= cost;


  Future<void> _loadCredit() async {
    try {
      final storedValue = await _storage.read(key: _storageKey);
      if (storedValue != null) {
        state = int.tryParse(storedValue) ?? 0;
      } else {
        state = 0;
        await _storage.write(key: _storageKey, value: state.toString());
      }
      debugPrint('💰 Loaded credits: $state');
    } catch (e) {
      debugPrint('❌ Error loading credit: $e');
    }
  }

  /// Set credit to a specific value
  Future<void> setCredit(int amount) async {
    state = amount;
    await _save();
    debugPrint('💰 Credit set to: $state');
  }

  /// Add credits
  Future<void> addCredit(int amount) async {
    try {
      state += amount;
      await _save();
      debugPrint('💰 Added $amount credits → Total: $state');
    } on Exception catch (e) {
      showLog('There is error in adding credit : ${e}');
    }
  }

  /// Deduct credits (never below 0)
  Future<void> deductCredit(int amount) async {
    if (state >= amount) {
      state -= amount;
    } else {
      state = 0;
    }
    await _save();
    debugPrint('💰 Deducted $amount credits → Remaining: $state');
  }

  /// Save credits to secure storage
  Future<void> _save() async {
    await _storage.write(key: _storageKey, value: state.toString());
  }

  /// Force reload from storage
  Future<void> reloadCredit() async => _loadCredit();
}

/// Riverpod provider for CreditNotifier
final creditProvider = StateNotifierProvider<CreditNotifier, int>((ref) {
  return CreditNotifier(const FlutterSecureStorage());
});
