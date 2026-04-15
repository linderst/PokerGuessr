#!/usr/bin/env python3
"""
Löscht ALLE Dokumente aus der Firestore 'questions' Collection.
"""

from firestore_client import _get_db


def delete_all_questions():
    db = _get_db()
    docs = db.collection("questions").stream()

    count = 0
    batch = db.batch()
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        # Firestore batch limit: 500
        if count % 500 == 0:
            batch.commit()
            print(f"  🗑️  {count} Dokumente gelöscht...")
            batch = db.batch()

    if count % 500 != 0:
        batch.commit()

    print(f"\n✅ Fertig: {count} Dokumente aus 'questions' gelöscht.")
    return count


if __name__ == "__main__":
    print("⚠️  ACHTUNG: Lösche ALLE Fragen aus Firestore...\n")
    delete_all_questions()
