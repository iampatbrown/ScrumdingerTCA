import ComposableArchitecture
import SwiftUI

extension Reducer {
  public func presents<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, LocalState?>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onDisappear: LocalAction
  ) -> Self {
    let presentedReducer = localReducer
      .optional()
      .pullback(
        state: toLocalState,
        action: toLocalAction,
        environment: toLocalEnvironment
      )

    return Self { state, action, environment in
      let localEffects = presentedReducer.run(&state, action, environment)
      let initialState = state[keyPath: toLocalState]
      let globalEffects = self.run(&state, action, environment)

      if
        var localState = initialState,
        state[keyPath: toLocalState] == nil
      { // global action has set state to nil
        _ = localReducer.runAndPerformEffects(
          &localState,
          onDisappear,
          toLocalEnvironment(environment)
        )
        // Could breakpoint here and check !didComplete or diff(state[keyPath: toLocalState], initialState)
        // in this case I don't care about state changes after onDisappear
      }

      return .merge(
        localEffects,
        globalEffects
      )
    }
  }
}

extension Reducer {
  private func runAndPerformEffects(
    _ state: inout State,
    _ action: Action,
    _ environment: Environment
  ) -> Bool {
    let effects = self.run(&state, action, environment)
    var actions: [Action] = []

    var didComplete = false
    _ = effects.sink(
      receiveCompletion: { _ in didComplete = true },
      receiveValue: { actions.append($0) }
    )

    guard didComplete else { return false }

    for action in actions {
      let didComplete = self.runAndPerformEffects(&state, action, environment)
      if !didComplete { return false }
    }

    return true
  }
}
