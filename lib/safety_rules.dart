import 'package:flutter/foundation.dart';

@immutable
class SafetyResult {
  const SafetyResult({required this.concern, required this.emergency});

  final bool concern;
  final bool emergency;
}

class SafetyRules {
  static const _selfReportMarkers = <String>[
    'اعاني',
    'اشعر',
    'حاسس',
    'حاسة',
    'بحس',
    'بشتكي',
    'اشكو',
    'عندي شكوى',
    'عندي اعراض',
    'ظهرت علي اعراض',
    'ممكن اكون مصاب',
    'هل انا مصاب',
    'هل عندي مرض',
    'هل عندي',
    'i have',
    "i'm experiencing",
    'my symptoms',
    'could i have',
    'do i have',
  ];

  static const _symptomTerms = <String>[
    'الم',
    'وجع',
    'صداع',
    'حرارة',
    'سخونية',
    'كحة',
    'سعال',
    'ضيق نفس',
    'قيء',
    'استفراغ',
    'اسهال',
    'دوخة',
    'دوار',
    'طفح',
    'نزيف',
    'خفقان',
    'تعب شديد',
    'تنميل',
    'تورم',
    'pain',
    'fever',
    'cough',
    'vomiting',
    'diarrhea',
    'dizziness',
    'rash',
  ];

  static const _outOfScopeMarkers = <String>[
    'شخصني',
    'شخص حالتي',
    'تشخيص',
    'ما العلاج',
    'ايه العلاج',
    'علاج',
    'جرعة',
    'اخد ايه',
    'اخذ ايه',
    'دواء',
    'ادوية',
    'وصفة',
    'dose',
    'dosage',
    'diagnose me',
    'diagnosis',
    'treatment',
    'medicine',
    'medication',
  ];

  static const _emergencyMarkers = <String>[
    'صعوبة التنفس',
    'صعوبة في التنفس',
    'ضيق التنفس',
    'ضيق في التنفس',
    'مش قادر اتنفس',
    'ضيق في التنفس',
    'مش قادر اتنفس',
    'مش قادرة اتنفس',
    'اختناق',
    'فقدان الوعي',
    'اغمى علي',
    'اغماء',
    'نزيف شديد',
    'الم شديد في الصدر',
    'الم في الصدر',
    'جلطة',
    'تشنج شديد',
    'حساسية مفرطة',
    'severe chest pain',
    'difficulty breathing',
    'trouble breathing',
    'unconscious',
    'severe bleeding',
    'stroke',
    'severe allergic reaction',
  ];

  static SafetyResult classify(String text) {
    final normalized = _normalize(text);
    final emergency = _containsAny(normalized, _emergencyMarkers);
    final concernMarker = _containsAny(normalized, _selfReportMarkers);
    final symptom = _containsAny(normalized, _symptomTerms);
    final personalSymptom = normalized.contains('عندي') && symptom;
    final outOfScope = _containsAny(normalized, _outOfScopeMarkers);
    return SafetyResult(
      concern: emergency || concernMarker || personalSymptom || outOfScope,
      emergency: emergency,
    );
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
  }

  static bool _containsAny(String text, List<String> phrases) {
    return phrases.any((phrase) => text.contains(_normalize(phrase)));
  }
}
