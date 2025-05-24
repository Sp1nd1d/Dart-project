class MoodEntry {
  final double value;
  final String comment;
  final DateTime date;
  bool isFavorite;

  MoodEntry({
    required this.value, 
    required this.comment, 
    required this.date,
    this.isFavorite = false,
  });
}

class MoodDescriptions {
  static String getMoodText(double value) {
    if (value < 1.0) return 'Ужасно';
    if (value < 2.0) return 'Плохо';
    if (value < 3.0) return 'Нормально';
    if (value < 4.0) return 'Хорошо';
    if (value < 5.0) return 'Отлично';
    return 'Супер';
  }

  static String getDetailedMoodText(double value) {
    if (value < 1.5) return 'Очень плохо';
    if (value < 2.5) return 'Плохо';
    if (value < 3.5) return 'Нормально';
    if (value < 4.5) return 'Хорошо';
    return 'Отлично';
  }
} 