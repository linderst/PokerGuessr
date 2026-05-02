import Foundation
import AVFoundation
import OSLog

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private static let logger = Logger(subsystem: "com.stefanlinder.pokerguessr", category: "Sound")

    enum Sound: String, CaseIterable {
        case tap        // Kurzer Click für Buttons
        case reveal     // Sound beim Aufdecken (Tipp / Auflösung)
        case success    // Positiver Klang (Sieger / Rangliste)
        case complete   // Finale am Spielende
    }

    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
        preload()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Self.logger.warning("AudioSession setup failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func preload() {
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3")
                    ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[sound] = player
            } catch {
                Self.logger.warning("Konnte Sound \(sound.rawValue, privacy: .public) nicht laden: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func play(_ sound: Sound) {
        let enabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        guard enabled else { return }

        guard let player = players[sound] else { return }
        let volume = UserDefaults.standard.object(forKey: "soundVolume") as? Double ?? 0.7
        player.volume = Float(volume)
        player.currentTime = 0
        player.play()
    }
}
