import 'package:intl/intl.dart';

/// Utilidades para manejo de fechas
class DateUtils {
  /// Formatea una fecha a string con patrón personalizado
  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Formatea una fecha a string con hora
  static String formatDateTime(DateTime dateTime, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(pattern).format(dateTime);
  }

  /// Obtiene la diferencia de días entre dos fechas
  static int daysDifference(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Verifica si una fecha es en el pasado
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Verifica si una fecha es en el futuro
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Formatea tiempo transcurrido (ej: "hace 2 horas")
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} minuto(s)';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} hora(s)';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} día(s)';
    } else {
      return formatDate(dateTime);
    }
  }
}

/// Utilidades de validación
class ValidationUtils {
  /// Valida formato de email
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Valida formato de contraseña (min 6 caracteres)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Valida que la contraseña cumple con requisitos fuertes
  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  /// Valida formato de teléfono
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{7,}$').hasMatch(phone);
  }

  /// Valida no esté vacío o solo espacios
  static bool isNotEmpty(String? text) {
    return text != null && text.trim().isNotEmpty;
  }

  /// Calcula la edad a partir de fecha de nacimiento
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Verifica si el usuario es mayor de edad
  static bool isAdult(DateTime birthDate) {
    return calculateAge(birthDate) >= 18;
  }
}

/// Utilidades para strings
class StringUtils {
  /// Capitaliza la primera letra
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Capitaliza todas las palabras
  static String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) => capitalize(word))
        .join(' ');
  }

  /// Limita el texto a una longitud máxima
  static String truncate(String text, {int maxLength = 50, String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + ellipsis;
  }

  /// Elimina espacios en blanco al inicio y final
  static String trim(String text) {
    return text.trim();
  }

  /// Verifica si contiene solo números
  static bool isNumeric(String text) {
    return RegExp(r'^-?\d+(\.\d+)?$').hasMatch(text);
  }

  /// Convierte string a bool de forma segura
  static bool stringToBool(String? value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }
}

/// Utilidades numéricas
class NumberUtils {
  /// Formatea un número a moneda
  static String formatCurrency(double amount, {String symbol = '\$', int decimals = 2}) {
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }

  /// Formatea un número con separadores de miles
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Convierte un número a porcentaje
  static String toPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Limita un número dentro de un rango
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
