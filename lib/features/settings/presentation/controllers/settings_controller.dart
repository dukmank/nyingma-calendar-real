import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends StateNotifier<void> {
  SettingsNotifier() : super(null);
}

final settingsControllerProvider =
    StateNotifierProvider((ref) => SettingsNotifier());
