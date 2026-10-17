from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

_ARABIC_DIACRITICS = re.compile(r"[\u064B-\u065F\u0670\u0640]")


def normalize_arabic(text: str) -> str:
    text = unicodedata.normalize("NFKC", text).lower()
    text = _ARABIC_DIACRITICS.sub("", text)
    return (
        text.replace("أ", "ا")
        .replace("إ", "ا")
        .replace("آ", "ا")
        .replace("ى", "ي")
        .replace("ؤ", "و")
        .replace("ئ", "ي")
    )


def _contains_any(text: str, phrases: tuple[str, ...]) -> bool:
    return any(normalize_arabic(phrase) in text for phrase in phrases)


@dataclass(frozen=True)
class SafetyResult:
    concern_detected: bool
    emergency: bool


EMERGENCY_PHRASES = (
    "صعوبة التنفس",
    "صعوبة في التنفس",
    "ضيق التنفس",
    "ضيق في التنفس",
    "مش قادر اتنفس",
    "مش قادرة اتنفس",
    "اختناق",
    "فقدان الوعي",
    "اغمى علي",
    "اغماء",
    "نزيف شديد",
    "الم شديد في الصدر",
    "الم في الصدر",
    "جلطة",
    "تشنج شديد",
    "حساسيه مفرطه",
    "severe chest pain",
    "difficulty breathing",
    "trouble breathing",
    "unconscious",
    "severe bleeding",
    "stroke",
    "severe allergic reaction",
)

_CONCERN_MARKERS = (
    "اعاني",
    "اشعر",
    "حاسس",
    "حاسة",
    "بحس",
    "بشتكي",
    "اشكو",
    "شكواي",
    "عندي شكوى",
    "عندي مرض",
    "عندي ربو",
    "عندي الربو",
    "عندي سكر",
    "عندي سكري",
    "عندي ضغط",
    "عندي ضغط الدم",
    "عندي انيميا",
    "عندي فقر الدم",
    "عندي حساسيه",
    "عندي كوليسترول",
    "عندي التهاب المفاصل",
    "لدي ربو",
    "لدي الربو",
    "لدي سكري",
    "لدي السكري",
    "لدي السكر",
    "لدي ضغط الدم",
    "لدي انيميا",
    "لدي فقر الدم",
    "عندي اعراض",
    "ظهرت علي اعراض",
    "ممكن اكون مصاب",
    "ممكن اكون عندي",
    "هل انا مصاب",
    "هل عندي مرض",
    "هل عندي",
    "اشك ان عندي",
    "i have",
    "i am experiencing",
    "i'm experiencing",
    "my symptoms",
    "could i have",
    "do i have",
)

_SYMPTOM_TERMS = (
    "الم",
    "وجع",
    "صداع",
    "حرارة",
    "سخونية",
    "كحة",
    "سعال",
    "ضيق نفس",
    "قيء",
    "استفراغ",
    "اسهال",
    "دوخة",
    "دوار",
    "طفح",
    "نزيف",
    "خفقان",
    "تعب شديد",
    "تنميل",
    "تورم",
    "pain",
    "fever",
    "cough",
    "vomiting",
    "diarrhea",
    "dizziness",
    "rash",
)

_OUT_OF_SCOPE_MARKERS = (
    "شخصني",
    "شخص حالتي",
    "تشخيص",
    "ما العلاج",
    "ايه العلاج",
    "اعالج",
    "علاج",
    "جرعة",
    "اخد ايه",
    "اخذ ايه",
    "دواء",
    "ادوية",
    "وصفة",
    "dose",
    "dosage",
    "diagnose me",
    "diagnosis",
    "treatment",
    "medicine",
    "medication",
)


def classify_message(text: str) -> SafetyResult:
    normalized = normalize_arabic(text)
    emergency = _contains_any(normalized, EMERGENCY_PHRASES)
    has_concern_marker = _contains_any(normalized, _CONCERN_MARKERS)
    has_symptom = _contains_any(normalized, _SYMPTOM_TERMS)
    has_personal_symptom = "عندي" in normalized and has_symptom
    out_of_scope = _contains_any(normalized, _OUT_OF_SCOPE_MARKERS)
    concern = emergency or has_concern_marker or has_personal_symptom or out_of_scope
    return SafetyResult(concern_detected=concern, emergency=emergency)
