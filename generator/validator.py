"""
Validation logic for generated quiz questions.
"""

import re
from difflib import SequenceMatcher
from prompts import VALID_CATEGORIES, VALID_DIMENSIONS, VALID_DIFFICULTIES


# Plausibility ranges for answerBaseValue per dimension
PLAUSIBILITY_RANGES: dict[str, tuple[float, float]] = {
    "weight":   (0.000_001, 100_000_000_000),    # 1 mg to 100M tonnes (in kg)
    "length":   (0.000_001, 1_000_000_000_000),   # 1 µm to 1 trillion m
    "time":     (0.001, 1_000_000_000_000),        # 1 ms to ~31,700 years (in s)
    "volume":   (0.000_001, 1_000_000_000_000),    # 1 µL to 1 trillion L
    "count":    (1, 1e15),                          # 1 to 1 quadrillion
    "currency": (0.01, 1e15),                       # 1 cent to 1 quadrillion
    "none":     (None, None),                        # No range check
}

MIN_TIP_LENGTH = 20
DUPLICATE_THRESHOLD = 0.75


class ValidationError:
    """Represents a single validation failure."""

    def __init__(self, field: str, message: str):
        self.field = field
        self.message = message

    def __repr__(self):
        return f"ValidationError({self.field}: {self.message})"


def validate_question(question: dict, category: str, difficulty: str) -> list[ValidationError]:
    """
    Validate a single generated question dict against schema and plausibility rules.
    Returns a list of ValidationErrors (empty = valid).
    """
    errors: list[ValidationError] = []

    # --- Schema checks ---
    required_fields = ["question", "answerBaseValue", "dimension", "defaultUnitText", "tip1", "tip2", "tip3"]
    for field in required_fields:
        if field not in question or question[field] is None:
            errors.append(ValidationError(field, f"Feld '{field}' fehlt oder ist None"))

    if errors:
        return errors  # Can't validate further if fields are missing

    # --- Type checks ---
    if not isinstance(question["question"], str) or len(question["question"].strip()) < 10:
        errors.append(ValidationError("question", "Fragetext zu kurz (< 10 Zeichen)"))

    if not isinstance(question["answerBaseValue"], (int, float)):
        errors.append(ValidationError("answerBaseValue", f"Muss eine Zahl sein, ist {type(question['answerBaseValue'])}"))

    # --- Category check ---
    if category not in VALID_CATEGORIES:
        errors.append(ValidationError("category", f"'{category}' ist keine gültige Kategorie"))

    # --- Difficulty check ---
    if difficulty not in VALID_DIFFICULTIES:
        errors.append(ValidationError("difficulty", f"'{difficulty}' ist kein gültiger Schwierigkeitsgrad"))

    # --- Dimension check ---
    dim = question["dimension"]
    if dim not in VALID_DIMENSIONS:
        errors.append(ValidationError("dimension", f"'{dim}' ist keine gültige Dimension"))

    # --- Plausibility range check ---
    if dim in PLAUSIBILITY_RANGES and isinstance(question["answerBaseValue"], (int, float)):
        min_val, max_val = PLAUSIBILITY_RANGES[dim]
        if min_val is not None and max_val is not None:
            val = question["answerBaseValue"]
            if val <= 0:
                errors.append(ValidationError("answerBaseValue", f"Wert muss positiv sein, ist {val}"))
            elif val < min_val or val > max_val:
                errors.append(ValidationError(
                    "answerBaseValue",
                    f"Wert {val} außerhalb des plausiblen Bereichs [{min_val}, {max_val}] für dimension '{dim}'"
                ))

    # --- Tip quality checks ---
    tips = [question.get("tip1", ""), question.get("tip2", ""), question.get("tip3", "")]
    for i, tip in enumerate(tips, 1):
        if not isinstance(tip, str) or len(tip.strip()) < MIN_TIP_LENGTH:
            errors.append(ValidationError(f"tip{i}", f"Tipp {i} zu kurz (< {MIN_TIP_LENGTH} Zeichen): '{tip}'"))

    # --- Tip progression check ---
    tip3 = question.get("tip3", "")
    if isinstance(tip3, str) and not re.search(r"\d", tip3):
        errors.append(ValidationError("tip3", "Tipp 3 sollte Zahlen/Vergleiche enthalten (keine gefunden)"))

    # --- Unit text in question check ---
    q_text = question.get("question", "").lower()
    unit_leaks = ["kilometer", "kilogramm", "millionen", "milliarden", "tonnen", "liter", "stunden", "minuten",
                  "kilometers", "kilograms", "millions", "billions", "tons", "liters", "hours", "minutes"]
    for unit in unit_leaks:
        if unit in q_text:
            errors.append(ValidationError("question", f"Frage enthält Einheit '{unit}' — soll sie nicht!"))
            break

    return errors


def is_duplicate(
    new_question_text: str,
    existing_questions: list[str],
    threshold: float = DUPLICATE_THRESHOLD,
) -> bool:
    """
    Check if a new question is too similar to existing ones using fuzzy matching.
    Returns True if a duplicate is detected.
    """
    new_lower = new_question_text.lower().strip()
    for existing in existing_questions:
        ratio = SequenceMatcher(None, new_lower, existing.lower().strip()).ratio()
        if ratio >= threshold:
            return True
    return False


def is_value_duplicate(
    new_value: float,
    new_dimension: str,
    new_category: str,
    existing_questions: list[dict],
) -> bool:
    """
    Check if an identical answerBaseValue already exists for the same category + dimension.
    """
    for q in existing_questions:
        if (
            q.get("category") == new_category
            and q.get("dimension") == new_dimension
            and q.get("answerBaseValue") == new_value
        ):
            return True
    return False
