import ComposableArchitecture
import Foundation

struct AudioPlayerClient {
  var play: (Sound) -> Effect<Never, Never>

  enum Sound: CaseIterable {
    case ding
  }
}

extension AudioPlayerClient {
  static let failing = Self(
    play: { .failing("\(Self.self).play(\($0)) is unimplemented") }
  )
}
