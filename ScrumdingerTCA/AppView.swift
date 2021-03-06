import ComposableArchitecture
import SwiftUI

struct AppState: Equatable {
  var scrums = Scrums()
}

enum AppAction {
  case scrums(ScrumsAction)
  case onAppear
  case scenePhaseChanged(ScenePhase)
  case scrumsLoaded(Result<Scrums, NSError>)
}

struct AppEnvironment {
  var audioPlayerClient: AudioPlayerClient = .noop
  var backgroundQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue.global(qos: .background)
    .eraseToAnyScheduler()
  var date: () -> Date = Date.init
  var fileClient: FileClient = .mock
  var mainQueue: AnySchedulerOf<DispatchQueue> = .main
  var randomColor: () -> Color = { .random }
  var speechClient: SpeechClient = .mock
  var uuid: () -> UUID = UUID.init
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  scrumsReducer.pullback(
    state: \AppState.scrums,
    action: /AppAction.scrums,
    environment: {
      ScrumsEnvironment(
        audioPlayerClient: $0.audioPlayerClient,
        date: $0.date,
        mainQueue: $0.mainQueue,
        randomColor: $0.randomColor,
        speechClient: $0.speechClient,
        uuid: $0.uuid
      )
    }
  ),

  Reducer { state, action, environment in
    switch action {
    case .onAppear:
      return environment.fileClient.loadScrums()
        .subscribe(on: environment.backgroundQueue)
        .receive(on: environment.mainQueue.animation())
        .eraseToEffect()
        .map(AppAction.scrumsLoaded)

    case .scenePhaseChanged(.inactive):
      return environment.fileClient.saveScrums(state.scrums)
        .subscribe(on: environment.backgroundQueue)
        .receive(on: environment.mainQueue)
        .fireAndForget()

    case .scenePhaseChanged:
      return .none

    case .scrums:
      return .none

    case let .scrumsLoaded(.success(scrums)):
      state.scrums = scrums
      return .none

    case let .scrumsLoaded(.failure(error)):
      if error.code == NSFileReadNoSuchFileError {
        state.scrums.scrums = .placeholder
      }
      return .none
    }
  }
)

struct AppView: View {
  let store: Store<AppState, AppAction>
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    WithViewStore(self.store.stateless) { viewStore in
      NavigationView {
        ScrumsView(
          store: self.store.scope(
            state: \AppState.scrums,
            action: AppAction.scrums
          )
        )
      }
      .navigationViewStyle(.stack)
      .onAppear { viewStore.send(.onAppear) }
      .onChange(of: scenePhase) { viewStore.send(.scenePhaseChanged($0)) }
    }
  }
}
