import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Name display order.
enum NameOrder {
  lastFirst('Last, First'),
  firstLast('First Last');

  final String label;
  const NameOrder(this.label);
}

String formatPersonName(String firstName, String lastName, NameOrder order) {
  return switch (order) {
    NameOrder.lastFirst => '$lastName, $firstName',
    NameOrder.firstLast => '$firstName $lastName',
  };
}

/// Name order provider.
final nameOrderProvider =
    NotifierProvider<NameOrderNotifier, NameOrder>(NameOrderNotifier.new);

class NameOrderNotifier extends Notifier<NameOrder> {
  @override
  NameOrder build() {
    _load();
    return NameOrder.lastFirst;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('nameOrder') ?? 'lastFirst';
    state = value == 'firstLast' ? NameOrder.firstLast : NameOrder.lastFirst;
  }

  Future<void> set(NameOrder order) async {
    state = order;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nameOrder', order.name);
  }
}

/// Theme mode provider.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('themeMode') ?? 'system';
    state = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}
