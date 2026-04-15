"""
Firestore client for loading existing questions and pushing new ones.
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore

# Will be initialized on first use
_db = None


def _get_db():
    """Initialize Firebase Admin SDK and return Firestore client (singleton)."""
    global _db
    if _db is not None:
        return _db

    # Look for service account key in the same directory as this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    key_path = os.path.join(script_dir, "serviceAccountKey.json")

    if not os.path.exists(key_path):
        raise FileNotFoundError(
            f"Firebase service account key nicht gefunden: {key_path}\n"
            "Bitte lade den Schlüssel von Firebase Console herunter:\n"
            "  Projekteinstellungen → Dienstkonten → Neuen privaten Schlüssel generieren\n"
            f"  und speichere ihn als: {key_path}"
        )

    cred = credentials.Certificate(key_path)
    firebase_admin.initialize_app(cred)
    _db = firestore.client()
    return _db


def load_existing_questions() -> list[dict]:
    """
    Load all existing questions from Firestore.
    Returns a list of dicts with all document fields + 'id'.
    """
    db = _get_db()
    docs = db.collection("questions").stream()
    questions = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        questions.append(data)
    return questions


def push_question(question_doc: dict) -> str:
    """
    Push a single question document to Firestore.
    Returns the generated document ID.
    """
    db = _get_db()
    _, doc_ref = db.collection("questions").add(question_doc)
    return doc_ref.id


def push_questions_batch(questions: list[dict]) -> list[str]:
    """
    Push multiple questions using batched writes for efficiency.
    Firestore batches are limited to 500 operations.
    Returns list of generated document IDs.
    """
    db = _get_db()
    doc_ids = []

    # Process in chunks of 500 (Firestore batch limit)
    for i in range(0, len(questions), 500):
        chunk = questions[i : i + 500]
        batch = db.batch()
        refs = []
        for q in chunk:
            ref = db.collection("questions").document()
            batch.set(ref, q)
            refs.append(ref)
        batch.commit()
        doc_ids.extend(ref.id for ref in refs)

    return doc_ids
