import ComposableArchitecture

struct MeetingTimer: Equatable {
  var lengthInMinutes: Int = 5
  var isActive: Bool = false
  var secondsElapsed: Int = 0

  var lengthInSeconds: Int { lengthInMinutes * 60 }
  var secondsRemaining: Int { max(lengthInSeconds - secondsElapsed, 0) }
}

enum MeetingTimerAction: Equatable {
  case reset
  case start
  case stop
  case tick
}

struct MeetingTimerEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
}

let meetingTimerReducer = Reducer<
  MeetingTimer,
  MeetingTimerAction,
  MeetingTimerEnvironment
> { state, action, environment in
  struct TimerId: Hashable {}

  switch action {
  case .reset:
    state.secondsElapsed = 0
    return Effect(value: .stop)

  case .start:
    guard !state.isActive else { return .none }
    state.isActive = true
    return Effect.timer(id: TimerId(), every: 1, tolerance: .zero, on: environment.mainQueue)
      .map { _ in .tick }

  case .stop:
    guard state.isActive else { return .none }
    state.isActive = false
    return Effect.cancel(id: TimerId())

  case .tick:
    guard state.isActive else { return .none } // TODO: Check this. Can tick occur after reset?
    state.secondsElapsed = min(state.secondsElapsed + 1, state.lengthInSeconds)
    return state.secondsRemaining > 0 ? .none : Effect(value: .stop)
  }
}
