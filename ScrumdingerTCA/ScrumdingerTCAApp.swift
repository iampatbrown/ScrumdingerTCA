import ComposableArchitecture
import SwiftUI

@main
struct ScrumdingerTCAApp: App {
  var body: some Scene {
    WindowGroup {
      AppView(
        store: Store(
          initialState: AppState(),
          reducer: appReducer,
          environment: AppEnvironment(
            audioPlayerClient: .live,
            fileClient: .live,
            speechClient: .live
          )
        )
      )
    }
  }
}
