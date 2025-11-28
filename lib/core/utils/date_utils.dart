import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateForDisplay(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();

    // Normalize dates to just year, month, day (ignore time and timezone)
    // This ensures we're comparing dates, not timestamps
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    // Calculate base age (year difference)
    int age = today.year - birth.year;

    // Check if birthday has occurred this year
    // If current month is before birth month, birthday hasn't occurred yet
    // If same month but current day is before birth day, birthday hasn't occurred yet
    bool birthdayPassed = true;
    if (today.month < birth.month) {
      birthdayPassed = false;
    } else if (today.month == birth.month && today.day < birth.day) {
      birthdayPassed = false;
    }

    // If birthday hasn't passed this year, subtract 1 from age
    if (!birthdayPassed) {
      age--;
    }

    // Ensure age is never negative
    return age < 0 ? 0 : age;
  }

  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
