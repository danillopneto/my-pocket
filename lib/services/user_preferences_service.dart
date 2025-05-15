import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final String language;
  final String currencySymbol;
  final String currencyFormat;
  final bool darkMode;

  UserPreferences({
    required this.language,
    required this.currencySymbol,
    required this.currencyFormat,
    required this.darkMode,
  });

  Map<String, dynamic> toMap() => {
        'language': language,
        'currencySymbol': currencySymbol,
        'currencyFormat': currencyFormat,
        'darkMode': darkMode,
      };

  factory UserPreferences.fromMap(Map<String, dynamic> map) => UserPreferences(
        language: map['language'] ?? 'pt',
        currencySymbol: map['currencySymbol'] ?? 'R\$',
        currencyFormat: map['currencyFormat'] ?? '0.000,00',
        darkMode: map['darkMode'] ?? false,
      );
}

class UserPreferencesService {
  final _db = FirebaseFirestore.instance;

  Future<UserPreferences> getPreferences(String userId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .get();
    if (doc.exists) {
      return UserPreferences.fromMap(doc.data()!);
    } else {
      // Default preferences
      return UserPreferences(
          language: 'pt',
          currencySymbol: 'R\$',
          currencyFormat: '0.000,00',
          darkMode: false);
    }
  }

  Future<void> setPreferences(String userId, UserPreferences prefs) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .set(prefs.toMap());
  }
}
