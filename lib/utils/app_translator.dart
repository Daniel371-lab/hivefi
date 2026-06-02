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
    'currency_setup_title': 'Elige tu moneda',
    'currency_setup_subtitle': 'Puedes cambiarla después en configuración.',
    'currency_setup_confirm': 'CONFIRMAR',
    'exitWithoutSaving': '¿Salir sin guardar?',
    'unsavedAmount': 'Tienes un monto sin confirmar.',
    'unsavedChanges': 'Tienes cambios sin guardar.',
    'genericError': 'Ocurrió un error. Intenta de nuevo.',
	'language_setup_title': 'Elige tu idioma',
    'language_setup_subtitle': 'Puedes cambiarlo después en Configuración.',
    'language_setup_next': 'SIGUIENTE',

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

    // Settings — secciones
    'sectionAccount': 'CUENTA',
    'sectionAppearance': 'APARIENCIA',
    'sectionBenefits': 'BENEFICIOS',
    'sectionAbout': 'ACERCA DE',
    'sectionSession': 'SESIÓN',
	
	//Premium
	'premiumSubtitulo': 'Pago único. Sin suscripciones.',
    'premiumBeneficio1': 'Modo oscuro',
    'premiumBeneficio1Desc': 'Cuida tus ojos con el tema oscuro.',
    'premiumBeneficio2': 'Categorías ilimitadas',
    'premiumBeneficio2Desc': 'Crea todos los sobres que necesitas.',
    'premiumBeneficio3': 'Sin anuncios para siempre',
    'premiumBeneficio3Desc': 'Experiencia limpia sin interrupciones.',
    'premiumPagoUnico': 'Pago único — acceso de por vida',
    'premiumActivar': 'Activar Premium',
    'premiumActivo': 'Premium activo',
    'premiumRestaurar': 'Restaurar compra anterior',
    'premiumRestaurado': 'Compra restaurada correctamente.',
    'premiumErrorCompra': 'No se pudo completar la compra. Intenta de nuevo.',

    // Settings — items
    'settings': 'Ajustes',
    'profile': 'Perfil',
    'darkMode': 'Modo oscuro',
    'themeSystem': 'Sistema',
    'themeLight': 'Claro',
    'themeDark': 'Oscuro',
    'language': 'Idioma',
    'donate': 'Apoya al desarrollador',
    'adFreeMode': 'Sin anuncios por 6 horas',
    'premium': 'Premium',
    'logout': 'Cerrar sesión',
    'deleteAccount': 'Eliminar cuenta',
    'logoutConfirm': '¿Seguro que quieres cerrar sesión?',
    'deleteAccountConfirm':
        'Esta acción es irreversible. Se borrarán todos tus datos y perderás tu beneficio Premium si lo adquiriste. ¿Deseas continuar?',
    'aboutApp': 'Acerca de Hivefi',
    'appVersion': 'Versión 1.0.0',
    'madeBy': 'Desarrollado por',

    // Perfil
    'saveName': 'GUARDAR NOMBRE',
    'nameEmpty': 'El nombre no puede estar vacío.',
    'nameUpdated': 'Nombre actualizado correctamente.',
    'changePassword': 'Cambiar contraseña',
    'changePasswordDesc':
        'Te enviaremos un correo a tu dirección registrada con un enlace para cambiar tu contraseña.',
    'sendResetEmail': 'ENVIAR CORREO DE RESTABLECIMIENTO',
    'resetSent': 'Correo enviado. Revisa tu bandeja de entrada.',

    // Login
    'email': 'CORREO ELECTRÓNICO',
    'emailHint': 'ejemplo@correo.com',
    'password': 'CONTRASEÑA',
    'login': 'INICIAR SESIÓN',
    'forgotPassword': '¿Olvidaste tu contraseña?',
    'noAccount': '¿No tienes cuenta?',
    'register': 'Registrate',
    'tagline': 'Tus finanzas, organizadas.',

    // Registro
    'name': 'NOMBRE',
    'nameHint': 'Tu nombre',
    'confirmPassword': 'CONFIRMAR CONTRASEÑA',
    'createAccount': 'CREAR CUENTA',
    'alreadyHaveAccount': '¿Ya tienes cuenta?',
    'loginLink': 'Iniciá sesión',
    'passwordMismatch': 'Las contraseñas no coinciden.',
    'passwordTooShort': 'La contraseña debe tener al menos 6 caracteres.',

    // Categorías
    'newCategory': 'NUEVA\nCATEGORÍA',
    'categoryType': 'TIPO DE CATEGORÍA',
    'categoryIngreso': 'Ingreso',
    'categoryIngresoDesc': 'Dinero que recibes',
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
	'noIncomeCategories': 'Sin categorías de ingreso.',
    'noExpenseCategories': 'Sin sobres de gasto.',
    'createInCategoriesFirst': 'Crea una en Categorías primero.',
    'noResults': 'Sin resultados.',

    // Gasto
    'registerExpense': 'REGISTRAR\nGASTO',
    'whereMoneyLeaves': '¿DE QUÉ SOBRE SALE EL DINERO?',
    'expenseAmount': 'MONTO A GASTAR',
    'confirmExpense': 'CONFIRMAR GASTO',
    'expenseRegistered': 'Gasto registrado correctamente.',
    'notEnoughFunds': 'No tienes suficiente dinero en este sobre.',

    // Destinar
    'allocateMoney': 'DESTINAR\nDINERO',
    'allocateSubtitle': 'Distribuye tus ingresos en sobres de gasto o ahorro.',
    'whereMoneyFrom': '¿DE DÓNDE SALE EL DINERO?',
    'whereMoneyTo': '¿A QUÉ SOBRE LO ASIGNÁS?',
    'amountToAllocate': 'MONTO A DESTINAR',
    'confirmAllocate': 'CONFIRMAR DESTINO',
    'allocateRegistered': 'Dinero destinado correctamente.',
    'sameAccountError': 'El origen y destino no pueden ser iguales.',
    'notEnoughFundsGeneral': 'No tienes suficiente dinero disponible.',
    'savingsLabel': 'AHORRO',

    // Reparto
    'splitTitle': 'REPARTO\nENTRE SOBRES',
    'splitSubtitle': 'Mueve dinero de un sobre a otro.',
    'splitFrom': '¿DE QUÉ SOBRE SACAS?',
    'splitTo': '¿A QUÉ SOBRE LO ENVIAS?',
    'amountToSplit': 'MONTO A TRASPASAR',
    'confirmSplit': 'EJECUTAR REPARTO',
    'splitRegistered': 'Reparto realizado correctamente.',
    'notEnoughInEnvelope': 'No tienes suficiente dinero en ese sobre.',

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
    'longPressHint':
        'Manten presionado un movimiento para editarlo o anularlo.',
		'adFreeActivated': 'Sin anuncios por 6 horas. ¡Disfrutalo!',
    'adFreeError': 'No se pudo activar. Intenta de nuevo.',

    // Tooltips primera vez
    'tooltip_ingreso': 'Aquí registras el dinero que recibes. Selecciona una cuenta y confirma el monto.',
    'tooltip_gasto': 'Aquí registras tus gastos. El dinero se descuenta del sobre seleccionado.',
    'tooltip_destinar': 'Mueve dinero de tus ingresos hacia un sobre de gasto o ahorro.',
    'tooltip_reparto': 'Redistribuye dinero entre tus sobres sin necesidad de un ingreso nuevo.',
    'tooltip_categorias': 'Tus sobres de presupuesto. Puedes crear sobres de ingreso, gasto y ahorro.',
    'tooltip_historial': 'Consulta y analiza todos tus movimientos filtrados por mes.',

    // Errores generales
    'emptyAmount': 'Ingresa un monto.',
    'invalidAmount': 'El monto no es válido.',
  },
  'en': {
    // General
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'currency': 'Currency',
    'currency_setup_title': 'Choose your currency',
    'currency_setup_subtitle': 'You can change it later in Settings.',
    'currency_setup_confirm': 'CONFIRM',
    'exitWithoutSaving': 'Exit without saving?',
    'unsavedAmount': 'You have an unconfirmed amount.',
    'unsavedChanges': 'You have unsaved changes.',
    'genericError': 'An error occurred. Please try again.',
	'language_setup_title': 'Choose your language',
    'language_setup_subtitle': 'You can change it later in Settings.',
    'language_setup_next': 'NEXT',

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

    // Settings — secciones
    'sectionAccount': 'ACCOUNT',
    'sectionAppearance': 'APPEARANCE',
    'sectionBenefits': 'BENEFITS',
    'sectionAbout': 'ABOUT',
    'sectionSession': 'SESSION',

//Premium

'premiumSubtitulo': 'One-time payment. No subscriptions.',
    'premiumBeneficio1': 'Dark mode',
    'premiumBeneficio1Desc': 'Easy on the eyes with a dark theme.',
    'premiumBeneficio2': 'Unlimited categories',
    'premiumBeneficio2Desc': 'Create as many envelopes as you need.',
    'premiumBeneficio3': 'No ads forever',
    'premiumBeneficio3Desc': 'Clean experience without interruptions.',
    'premiumPagoUnico': 'One-time payment — lifetime access',
    'premiumActivar': 'Activate Premium',
    'premiumActivo': 'Premium active',
    'premiumRestaurar': 'Restore previous purchase',
    'premiumRestaurado': 'Purchase restored successfully.',
    'premiumErrorCompra': 'Could not complete purchase. Please try again.',

    // Settings — items
    'settings': 'Settings',
    'profile': 'Profile',
    'darkMode': 'Dark mode',
    'themeSystem': 'System',
    'themeLight': 'Light',
    'themeDark': 'Dark',
    'language': 'Language',
    'donate': 'Support the developer',
    'adFreeMode': 'Ad-free for 6 hours',
    'premium': 'Premium',
    'logout': 'Log out',
    'deleteAccount': 'Delete account',
    'logoutConfirm': 'Are you sure you want to log out?',
    'deleteAccountConfirm':
        'This action is irreversible. All your data will be deleted and you will lose your Premium benefit if you purchased it. Continue?',
    'aboutApp': 'About Hivefi',
    'appVersion': 'Version 1.0.0',
    'madeBy': 'Developed by',

    // Perfil
    'saveName': 'SAVE NAME',
    'nameEmpty': 'Name cannot be empty.',
    'nameUpdated': 'Name updated successfully.',
    'changePassword': 'Change password',
    'changePasswordDesc':
        'We will send an email to your registered address with a link to change your password.',
    'sendResetEmail': 'SEND RESET EMAIL',
    'resetSent': 'Email sent. Check your inbox.',

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
	'noIncomeCategories': 'No income categories.',
    'noExpenseCategories': 'No expense envelopes.',
    'createInCategoriesFirst': 'Create one in Categories first.',
    'noResults': 'No results.',

    // Gasto
    'registerExpense': 'REGISTER\nEXPENSE',
    'whereMoneyLeaves': 'WHICH ENVELOPE COVERS THIS EXPENSE?',
    'expenseAmount': 'AMOUNT TO SPEND',
    'confirmExpense': 'CONFIRM EXPENSE',
    'expenseRegistered': 'Expense registered successfully.',
    'notEnoughFunds': 'Not enough money in this envelope.',

    // Destinar
    'allocateMoney': 'ALLOCATE\nMONEY',
    'allocateSubtitle':
        'Distribute your income into spending or savings envelopes.',
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
    'longPressHint':
        'Long press a movement to edit or cancel it.',

'adFreeActivated': 'Ad-free for 6 hours. Enjoy!',
    'adFreeError': 'Could not activate. Please try again.',
	
    // Tooltips primera vez
    'tooltip_ingreso': 'Here you register the money you receive. Select an account and confirm the amount.',
    'tooltip_gasto': 'Here you register your expenses. Money is deducted from the selected envelope.',
    'tooltip_destinar': 'Move money from your income into a spending or savings envelope.',
    'tooltip_reparto': 'Redistribute money between your envelopes without needing a new income.',
    'tooltip_categorias': 'Your budget envelopes. You can create income, expense and savings envelopes.',
    'tooltip_historial': 'View and analyze all your transactions filtered by month.',

    // Errores generales
    'emptyAmount': 'Enter an amount.',
    'invalidAmount': 'The amount is not valid.',
  },
};