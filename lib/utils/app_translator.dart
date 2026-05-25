import 'package:flutter/material.dart';

extension AppTranslator on BuildContext {
  String tr(String key) {
    final locale = Localizations.localeOf(this).languageCode;
    return _translations[locale]?[key] ?? _translations['es']?[key] ?? key;
  }
}

const Map<String, Map<String, String>> _translations = {
  'es': {
    'balanceGeneral': 'BALANCE GENERAL',
    'income': 'INGRESO',
    'expense': 'GASTO',
    'destinar': 'DESTINAR',
    'categories': 'CATEGORÍAS',
    'reparto': 'REPARTO',
    'history': 'HISTORIAL',
    'savings': 'MIS AHORROS',
    'assignedToExpenses': 'DINERO ASIGNADO A GASTOS',
    'settings': 'Ajustes',
    'profile': 'Perfil',
    'darkMode': 'Modo oscuro',
    'language': 'Idioma',
    'donate': 'Donar',
    'adFreeMode': 'Sin anuncios por 6 horas',
    'premium': 'Premium',
    'logout': 'Cerrar sesión',
    'deleteAccount': 'Eliminar cuenta',
    'cancel': 'Cancelar',
    'confirm': 'Confirmar',
    'currency': 'Moneda',
  },
  'en': {
    'balanceGeneral': 'GENERAL BALANCE',
    'income': 'INCOME',
    'expense': 'EXPENSE',
    'destinar': 'ALLOCATE',
    'categories': 'CATEGORIES',
    'reparto': 'SPLIT',
    'history': 'HISTORY',
    'savings': 'MY SAVINGS',
    'assignedToExpenses': 'MONEY ASSIGNED TO EXPENSES',
    'settings': 'Settings',
    'profile': 'Profile',
    'darkMode': 'Dark mode',
    'language': 'Language',
    'donate': 'Donate',
    'adFreeMode': 'Ad-free for 6 hours',
    'premium': 'Premium',
    'logout': 'Log out',
    'deleteAccount': 'Delete account',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'currency': 'Currency',
  },
};