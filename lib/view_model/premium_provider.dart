import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple notifier using NotifierProvider
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setIsPurchased(bool value) {
    state = value;
  }
}

/// Provider you can use anywhere in the app
final premiumProvider = NotifierProvider<PremiumNotifier, bool>(
      () => PremiumNotifier(),
);