import AVFoundation
import ComposableArchitecture

extension AudioPlayerClient {
  static var live: Self {
    for sound in Sound.allCases {
      guard let url = Bundle.main.url(forResource: sound.name, withExtension: "wav")
      else { fatalError("Failed to find sound file for \(sound.name).") }
      soundPlayers[sound] = AVPlayer(url: url)
    }

    return Self(
      play: { sound in
        .fireAndForget {
          guard let player = soundPlayers[sound] else { return }
          player.seek(to: .zero)
          player.play()
        }
      }
    )
  }
}

extension AudioPlayerClient.Sound {
  fileprivate var name: String {
    switch self {
    case .ding: return "ding"
    }
  }
}

private var soundPlayers: [AudioPlayerClient.Sound: AVPlayer] = [:]
