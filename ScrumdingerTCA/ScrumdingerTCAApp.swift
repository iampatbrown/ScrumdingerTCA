import SwiftUI
import ComposableArchitecture

@main
struct ScrumdingerTCAApp: App {
    var body: some Scene {
        WindowGroup {
          AppView(
            store: Store(
              initialState: AppState(),
              reducer: appReducer.debug(actionFormat: .labelsOnly),
              environment: AppEnvironment(
                audioPlayerClient: .live,
                backgroundQueue: DispatchQueue.global(qos: .background).eraseToAnyScheduler(),
                date: Date.init,
                fileClient: .live,
                mainQueue: .main,
                speechClient: .live,
                uuid: UUID.init
              )
            )
          )
        }
    }
}
