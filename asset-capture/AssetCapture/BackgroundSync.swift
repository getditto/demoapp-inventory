import Foundation
import AVFoundation

/// Plays a silent audio loop to keep the app (and Ditto sync) alive when backgrounded.
final public class BackgroundSync {
    public static let shared = BackgroundSync()
    private let player: AVAudioPlayer
    private let base64AudioString = "UklGRiYAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQIAAAD8/w=="

    public var isOn = false

    private init() {
        let audioData = Data(base64Encoded: base64AudioString)!
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        try! AVAudioSession.sharedInstance().setActive(true)
        player = try! AVAudioPlayer(data: audioData, fileTypeHint: "wav")
        player.numberOfLoops = -1
        player.volume = 0.01
        player.prepareToPlay()
    }

    public func start() {
        guard isOn else { return }
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        player.play()
    }

    public func stop() {
        NotificationCenter.default.removeObserver(
            self, name: AVAudioSession.interruptionNotification, object: nil
        )
        if player.isPlaying { player.stop() }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        if type == .ended { player.play() }
    }
}
