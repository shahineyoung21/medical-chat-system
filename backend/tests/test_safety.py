from backend.app.safety import classify_message, normalize_arabic


def test_arabic_normalization_removes_diacritics_and_normalizes_alef():
    assert normalize_arabic("إِنْفِلُونْزَا") == "انفلونزا"


def test_general_health_education_question_is_not_personal_complaint():
    result = classify_message("ما أعراض مرض السكري؟")
    assert result.concern_detected is False
    assert result.emergency is False


def test_personal_symptom_triggers_clinician_escalation():
    result = classify_message("أنا أعاني من دوخة")
    assert result.concern_detected is True
    assert result.emergency is False


def test_diagnosis_or_dose_request_is_out_of_scope():
    assert classify_message("شخّصني، ما جرعة الدواء؟").concern_detected is True


def test_emergency_phrase_is_flagged():
    result = classify_message("عندي صعوبة في التنفس")
    assert result.concern_detected is True
    assert result.emergency is True
