# 🎯 Poker Guessr

**Das Wissens-Quiz mit Bluff-Elementen** — Schätze Zahlen, nutze Tipps und pokere dich zum Sieg!

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2026+-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-✓-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Firebase-Firestore-yellow?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/License-Private-lightgrey" alt="License">
</p>

---

## 📖 Was ist Poker Guessr?

Poker Guessr ist ein Multiplayer-Schätzspiel für iOS. Spieler bekommen Wissensfragen mit numerischen Antworten und müssen schätzen — unterstützt durch progressive Tipps. Wer am nächsten dran ist, gewinnt die Runde!

### 🎮 Features

- **🧠 Wissensfragen** — Hunderte Fragen aus 11 Kategorien, von Sport bis Wissenschaft
- **👥 Multiplayer** — 2+ Spieler auf einem Gerät, mit Rangliste und Punkteverfolgung
- **💡 Progressive Tipps** — 3 aufeinander aufbauende Hinweise pro Frage
- **📏 Einheitensystem** — Dynamische Einheiten-Picker (km, m, kg, Tonnen, etc.)
- **🎨 4 Themes** — Ocean Blue, Sunset Burst, Midnight Purple, Forest Green
- **📳 Haptisches Feedback** — Taktile Rückmeldung bei Interaktionen
- **⚙️ Konfigurierbar** — Rundenanzahl, Schwierigkeit, Tipps ein/aus, separates Ranking

---

## 🏗️ Architektur

Das Projekt folgt einer **MVVM-Architektur** mit klarer Trennung:

```
Poker Guessr/
├── Model/                    # Datenmodelle
│   ├── QuizItem.swift        # Quiz-Frage mit Einheitensystem
│   ├── Player.swift          # Spieler mit Score
│   ├── Difficulty.swift      # Easy / Medium / Hard
│   ├── QuizDimension.swift   # Einheiten & Umrechnungen
│   ├── QuizState.swift       # State-Machine-Zustände
│   ├── QuestionCategory.swift # 11 Fragen-Kategorien
│   └── String+Parsing.swift  # Zahlen-Extraktion
│
├── ViewModel/                # Business-Logik
│   ├── GameViewModel.swift   # Spiel-Logik & State-Machine
│   └── RankingService.swift  # Ranking-Berechnung (stateless)
│
├── View/                     # UI-Komponenten
│   ├── MenuView.swift        # Hauptmenü
│   ├── GameView.swift        # Spiel-Screen
│   ├── SettingsView.swift    # Einstellungen
│   ├── CategorySheet.swift   # Kategorie-Auswahl
│   ├── PlayersSection.swift  # Spielerliste mit Edit
│   ├── MenuComponents.swift  # Titel, Chip-Animation, Difficulty-Selector
│   ├── EndOfQuestionsView.swift
│   ├── DesignSettingsView.swift
│   └── View+Extensions.swift # neonGlow, conditional modifier
│
├── Data/                     # Datenzugriff
│   └── FirestoreService.swift # Firestore-Abfragen
│
├── ThemeManager.swift        # 4 Themes mit Farbpaletten
├── ThemePalette.swift        # Farbdefinitionen
├── HapticsManager.swift      # Haptisches Feedback
└── Poker_GuessrApp.swift     # App Entry Point
```

---

## 🚀 Setup

### Voraussetzungen

- **Xcode 26+**
- **iOS 26+ Deployment Target**
- **Firebase-Projekt** mit Firestore

### 1. Repository klonen

```bash
git clone https://github.com/linderst/PokerGuessr.git
cd PokerGuessr
```

### 2. Firebase einrichten

Die App benötigt eine `GoogleService-Info.plist` im Root-Verzeichnis. Diese Datei ist aus Sicherheitsgründen nicht im Repository enthalten.

```bash
# Template kopieren und mit eigenen Werten befüllen
cp GoogleService-Info.plist.template GoogleService-Info.plist
```

Dann die Platzhalter durch deine Firebase-Konfiguration ersetzen. Du findest die Werte in der [Firebase Console](https://console.firebase.google.com/) → Projekteinstellungen → iOS-App.

### 3. In Xcode öffnen

```bash
open "Poker Guessr.xcodeproj"
```

Swift Package Dependencies (Firebase SDK) werden automatisch aufgelöst.

---

## 🤖 Fragen-Generator

Im `generator/`-Ordner befindet sich ein Python-Tool zur automatisierten Generierung von Quiz-Fragen mittels **Google Gemini AI**.

### Setup

```bash
cd generator
pip3 install -r requirements.txt
```

### Verwendung

```bash
export GEMINI_API_KEY='dein-api-key'

# 10 leichte Sport-Fragen generieren
python3 generator.py --count 10 --difficulty easy --category "Sport"

# 5 schwere Geografie-Fragen
python3 generator.py --count 5 --difficulty hard --category "Geografie"
```

### Verfügbare Kategorien

| Kategorie | Kategorie | Kategorie |
|---|---|---|
| Sport | Geografie | Geschichte |
| Mensch | Wissenschaft | Technik |
| Essen & Trinken | Sprachen | Popkultur |
| Allgemeinwissen | Mensch & Körper | |

### Features des Generators

- **Gemini AI** — Nutzt `gemini-3-flash-preview` mit Fallback auf `gemini-2.5-flash-lite`
- **Validierung** — Automatische Schema-, Plausibilitäts- und Duplikat-Prüfung
- **Progressive Tipps** — 3-stufige Tipp-Strategie (indirekt → direkt → stark)
- **Rate-Limit-Handling** — Automatisches Retry mit exponentiellem Backoff
- **Firestore-Upload** — Generierte Fragen werden direkt in die Datenbank geschrieben

> ⚠️ Der Generator benötigt eine `serviceAccountKey.json` im `generator/`-Ordner. Diese ist ebenfalls nicht im Repository enthalten.

---

## 🔒 Sicherheit

Sensible Dateien sind via `.gitignore` geschützt:

| Datei | Inhalt | Status |
|---|---|---|
| `GoogleService-Info.plist` | Firebase API-Keys | 🔒 Nur lokal |
| `generator/serviceAccountKey.json` | Firebase Service Account | 🔒 Nur lokal |
| `*.env` | Umgebungsvariablen | 🔒 Nur lokal |

Template-Dateien (`*.template`) sind im Repository verfügbar, um die Einrichtung zu erleichtern.

---

## 📱 Screenshots

*Kommt bald — App wird derzeit für den App Store vorbereitet.*

---

## 🛠️ Tech Stack

| Technologie | Verwendung |
|---|---|
| **SwiftUI** | Gesamte UI |
| **Firebase Firestore** | Fragen-Datenbank |
| **Google Gemini AI** | Fragen-Generierung |
| **Python + Pydantic** | Generator-Backend |
| **MVVM** | Architektur-Pattern |

---

## 📄 Datenschutz

Poker Guessr sammelt **keine persönlichen Daten**. Spielernamen werden nur lokal während der Session gespeichert. Die vollständige Datenschutzerklärung ist verfügbar unter der App-Website.

---

<p align="center">
  Made with ❤️ by Stefan Linder
</p>
