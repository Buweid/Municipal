import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // ── KEYS ─────────────────────────────────────────────────────────
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotifIssueUpdates = 'notif_issue_updates';
  static const String _keyNotifBroadcast = 'notif_broadcast';
  static const String _keyNotifTasks = 'notif_tasks';

  // ── STATE ─────────────────────────────────────────────────────────
  bool _isDarkMode = false;
  String _language = 'en';
  bool _notifIssueUpdates = true;
  bool _notifBroadcast = true;
  bool _notifTasks = true;

  // ── GETTERS ──────────────────────────────────────────────────────
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isArabic => _language == 'ar';
  bool get notifIssueUpdates => _notifIssueUpdates;
  bool get notifBroadcast => _notifBroadcast;
  bool get notifTasks => _notifTasks;

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Locale get locale => Locale(_language);

  // ── LOAD FROM PREFS ───────────────────────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _language = prefs.getString(_keyLanguage) ?? 'en';
    _notifIssueUpdates = prefs.getBool(_keyNotifIssueUpdates) ?? true;
    _notifBroadcast = prefs.getBool(_keyNotifBroadcast) ?? true;
    _notifTasks = prefs.getBool(_keyNotifTasks) ?? true;
    notifyListeners();
  }

  // ── SETTERS ──────────────────────────────────────────────────────
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> toggleNotifIssueUpdates() async {
    _notifIssueUpdates = !_notifIssueUpdates;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifIssueUpdates, _notifIssueUpdates);
    notifyListeners();
  }

  Future<void> toggleNotifBroadcast() async {
    _notifBroadcast = !_notifBroadcast;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifBroadcast, _notifBroadcast);
    notifyListeners();
  }

  Future<void> toggleNotifTasks() async {
    _notifTasks = !_notifTasks;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifTasks, _notifTasks);
    notifyListeners();
  }
}