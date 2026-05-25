import 'package:flutter/material.dart';

extension AppTranslator on BuildContext {
  String tr(String key) {
    final locale = Localizations.localeOf(this).languageCode;
    return _translations[locale]?[key] ?? _translations['es']?[key] ?? key;
  }
}

const Map<String, Map<String, String>> _translations = {
  'es': {
    // General
    'cancel': 'Cancelar',
    'confirm': 'Confirmar',
    'currency': 'Moneda',
    'exitWithoutSaving': '¿Salir sin guardar?',
    'unsavedAmount': 'Tenés un monto sin confirmar.',
    'unsavedChanges': 'Tenés cambios sin guardar.',

    // Home
    'balanceGeneral': 'BALANCE GENERAL',
    'assignedToExpenses': 'DINERO ASIGNADO A GASTOS',
    'savings': 'MIS AHORROS',

    // Navegación
    'income': 'INGRESO',
    'expense': 'GASTO',
    'destinar': 'DESTINAR',
    'categories': 'CATEGORÍAS',
    'reparto': 'REPARTO',
    'history': 'HISTORIAL',

    // Settings
    'settings': 'Ajustes',
    'profile': 'Perfil',
    'darkMode': 'Modo oscuro',
    'language': 'Idioma',
    'donate': 'Donar',
    'adFreeMode': 'Sin anuncios por 6 horas',
    'premium': 'Premium',
    'logout': 'Cerrar sesión',
    'deleteAccount': 'Eliminar cuenta',
    'logoutConfirm': '¿Seguro que querés cerrar sesión?',
    'deleteAccountConfirm': 'Esta acción es irreversible. ¿Querés eliminar tu cuenta?',

    // Login
    'email': 'CORREO ELECTRÓNICO',
    'emailHint': 'ejemplo@correo.com',
    'password': 'CONTRASEÑA',
    'login': 'INICIAR SESIÓN',
    'forgotPassword': '¿Olvidaste tu contraseña?',
    'noAccount': '¿No tenés cuenta?',
    'register': 'Registrate',
    'tagline': 'Tus finanzas, organizadas.',

    // Registro
    'name': 'NOMBRE',
    'nameHint': 'Tu nombre',
    'confirmPassword': 'CONFIRMAR CONTRASEÑA',
    'createAccount': 'CREAR CUENTA',
    'alreadyHaveAccount': '¿Ya tenés cuenta?',
    'loginLink': 'Iniciá sesión',
    'passwordMismatch': 'Las contraseñas no coinciden.',
    'passwordTooShort': 'La contraseña debe tener al menos 6 caracteres.',

    // Categorías
    'newCategory': 'NUEVA\nCATEGORÍA',
    'categoryType': 'TIPO DE CATEGORÍA',
    'categoryIngreso': 'Ingreso',
    'categoryIngresoDesc': 'Dinero que recibís',
    'categoryGasto': 'Gasto',
    'categoryGastoDesc': 'Sobre para destinar dinero',
    'categoryAhorro': 'Ahorro',
    'categoryAhorroDesc': 'Meta a largo plazo',
    'categoryName': 'IDENTIFICADOR',
    'categoryNameHint': 'Ej: Viajes, Sueldo, Comida...',
    'categoryCreated': 'Categoría creada correctamente.',
    'categoryEmptyError': 'El nombre no puede estar vacío.',
    'createCategory': 'CREAR CATEGORÍA',

    // Ingreso
    'registerIncome': 'REGISTRAR\nINGRESO',
    'whereMoneyEnters': '¿A QUÉ CUENTA ENTRA EL DINERO?',
    'incomeAmount': 'MONTO DEL INGRESO',
    'confirmIncome': 'CONFIRMAR ENTRADA',
    'incomeRegistered': 'Ingreso registrado correctamente.',
    'recentHistory': 'HISTORIAL RECIENTE',
    'available': 'Disponible',

    // Gasto
    'registerExpense': 'REGISTRAR\nGASTO',
    'whereMoneyLeaves': '¿DE QUÉ SOBRE SALE EL DINERO?',
    'expenseAmount': 'MONTO A GASTAR',
    'confirmExpense': 'CONFIRMAR GASTO',
    'expenseRegistered': 'Gasto registrado correctamente.',
    'notEnoughFunds': 'No tenés suficiente dinero en este sobre.',

    // Destinar
    'allocateMoney': 'DESTINAR\nDINERO',
    'allocateSubtitle': 'Distribuí tus ingresos en sobres de gasto o ahorro.',
    'whereMoneyFrom': '¿DE DÓNDE SALE EL DINERO?',
    'whereMoneyTo': '¿A QUÉ SOBRE LO ASIGNÁS?',
    'amountToAllocate': 'MONTO A DESTINAR',
    'confirmAllocate': 'CONFIRMAR DESTINO',
    'allocateRegistered': 'Dinero destinado correctamente.',
    'sameAccountError': 'El origen y destino no pueden ser iguales.',
    'notEnoughFundsGeneral': 'No tenés suficiente dinero disponible.',
    'savingsLabel': 'AHORRO',

    // Reparto
    'splitTitle': 'REPARTO\nENTRE SOBRES',
    'splitSubtitle': 'Mové dinero de un sobre a otro.',
    'splitFrom': '¿DE QUÉ SOBRE SACÁS?',
    'splitTo': '¿A QUÉ SOBRE LO ENVIÁS?',
    'amountToSplit': 'MONTO A TRASPASAR',
    'confirmSplit': 'EJECUTAR REPARTO',
    'splitRegistered': 'Reparto realizado correctamente.',
    'notEnoughInEnvelope': 'No tenés suficiente dinero en ese sobre.',

    // Historial
    'historialTitle': 'ANÁLISIS\nDE CUENTA',
    'filterByMonth': 'FILTRAR POR MES',
    'year': 'AÑO',
    'tabSummary': 'RESUMEN',
    'tabIncome': 'INGRESOS',
    'tabExpenses': 'GASTOS',
    'balance': 'SALDO',
    'noMovements': 'Sin movimientos.',
    'editMovement': 'Editar movimiento',
    'cancelMovement': 'Anular movimiento',
    'longPressHint': 'Mantené presionado un movimiento para editarlo o anularlo.',

    // Errores generales
    'emptyAmount': 'Ingresá un monto.',
    'invalidAmount': 'El monto no es válido.',
  },
  'en': {
    // General
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'currency': 'Currency',
    'exitWithoutSaving': 'Exit without saving?',
    'unsavedAmount': 'You have an unconfirmed amount.',
    'unsavedChanges': 'You have unsaved changes.',

    // Home
    'balanceGeneral': 'GENERAL BALANCE',
    'assignedToExpenses': 'MONEY ASSIGNED TO EXPENSES',
    'savings': 'MY SAVINGS',

    // Navegación
    'income': 'INCOME',
    'expense': 'EXPENSE',
    'destinar': 'ALLOCATE',
    'categories': 'CATEGORIES',
    'reparto': 'SPLIT',
    'history': 'HISTORY',

    // Settings
    'settings': 'Settings',
    'profile': 'Profile',
    'darkMode': 'Dark mode',
    'language': 'Language',
    'donate': 'Donate',
    'adFreeMode': 'Ad-free for 6 hours',
    'premium': 'Premium',
    'logout': 'Log out',
    'deleteAccount': 'Delete account',
    'logoutConfirm': 'Are you sure you want to log out?',
    'deleteAccountConfirm': 'This action is irreversible. Delete your account?',

    // Login
    'email': 'EMAIL',
    'emailHint': 'example@email.com',
    'password': 'PASSWORD',
    'login': 'LOG IN',
    'forgotPassword': 'Forgot your password?',
    'noAccount': "Don't have an account?",
    'register': 'Sign up',
    'tagline': 'Your finances, organized.',

    // Registro
    'name': 'NAME',
    'nameHint': 'Your name',
    'confirmPassword': 'CONFIRM PASSWORD',
    'createAccount': 'CREATE ACCOUNT',
    'alreadyHaveAccount': 'Already have an account?',
    'loginLink': 'Log in',
    'passwordMismatch': 'Passwords do not match.',
    'passwordTooShort': 'Password must be at least 6 characters.',

    // Categorías
    'newCategory': 'NEW\nCATEGORY',
    'categoryType': 'CATEGORY TYPE',
    'categoryIngreso': 'Income',
    'categoryIngresoDesc': 'Money you receive',
    'categoryGasto': 'Expense',
    'categoryGastoDesc': 'Envelope to allocate money',
    'categoryAhorro': 'Savings',
    'categoryAhorroDesc': 'Long-term goal',
    'categoryName': 'IDENTIFIER',
    'categoryNameHint': 'E.g: Travel, Salary, Food...',
    'categoryCreated': 'Category created successfully.',
    'categoryEmptyError': 'Name cannot be empty.',
    'createCategory': 'CREATE CATEGORY',

    // Ingreso
    'registerIncome': 'REGISTER\nINCOME',
    'whereMoneyEnters': 'WHICH ACCOUNT RECEIVES THE MONEY?',
    'incomeAmount': 'INCOME AMOUNT',
    'confirmIncome': 'CONFIRM INCOME',
    'incomeRegistered': 'Income registered successfully.',
    'recentHistory': 'RECENT HISTORY',
    'available': 'Available',

    // Gasto
    'registerExpense': 'REGISTER\nEXPENSE',
    'whereMoneyLeaves': 'WHICH ENVELOPE COVERS THIS EXPENSE?',
    'expenseAmount': 'AMOUNT TO SPEND',
    'confirmExpense': 'CONFIRM EXPENSE',
    'expenseRegistered': 'Expense registered successfully.',
    'notEnoughFunds': 'Not enough money in this envelope.',

    // Destinar
    'allocateMoney': 'ALLOCATE\nMONEY',
    'allocateSubtitle': 'Distribute your income into spending or savings envelopes.',
    'whereMoneyFrom': 'WHERE DOES THE MONEY COME FROM?',
    'whereMoneyTo': 'WHICH ENVELOPE DO YOU ASSIGN IT TO?',
    'amountToAllocate': 'AMOUNT TO ALLOCATE',
    'confirmAllocate': 'CONFIRM ALLOCATION',
    'allocateRegistered': 'Money allocated successfully.',
    'sameAccountError': 'Origin and destination cannot be the same.',
    'notEnoughFundsGeneral': 'Not enough money available.',
    'savingsLabel': 'SAVINGS',

    // Reparto
    'splitTitle': 'SPLIT\nBETWEEN ENVELOPES',
    'splitSubtitle': 'Move money from one envelope to another.',
    'splitFrom': 'WHICH ENVELOPE DO YOU TAKE FROM?',
    'splitTo': 'WHICH ENVELOPE DO YOU SEND TO?',
    'amountToSplit': 'AMOUNT TO TRANSFER',
    'confirmSplit': 'EXECUTE TRANSFER',
    'splitRegistered': 'Transfer completed successfully.',
    'notEnoughInEnvelope': 'Not enough money in that envelope.',

    // Historial
    'historialTitle': 'ACCOUNT\nANALYSIS',
    'filterByMonth': 'FILTER BY MONTH',
    'year': 'YEAR',
    'tabSummary': 'SUMMARY',
    'tabIncome': 'INCOME',
    'tabExpenses': 'EXPENSES',
    'balance': 'BALANCE',
    'noMovements': 'No movements.',
    'editMovement': 'Edit movement',
    'cancelMovement': 'Cancel movement',
    'longPressHint': 'Long press a movement to edit or cancel it.',

    // Errores generales
    'emptyAmount': 'Enter an amount.',
    'invalidAmount': 'The amount is not valid.',
  },
};