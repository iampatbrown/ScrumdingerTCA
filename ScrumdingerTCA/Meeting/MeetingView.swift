import ComposableArchitecture
import SwiftUI

struct Meeting: Equatable {
  var activeSpeakerIndex: Int = 0
  var scrumColor: Color = .orange
  var speakers: [Speaker] = []
  var speechRecognition: SpeechRecognitionState = .init()
  var timer: MeetingTimer = .init()

  var attendees: [String] { speakers.map(\.name) }
  var secondsElapsedForSpeaker: Int { timer.secondsElapsed - Int(secondsPerSpeaker * Double(activeSpeakerIndex)) }
  var secondsPerSpeaker: Double { Double(timer.lengthInMinutes * 60) / Double(max(speakers.count, 1)) }

  struct Speaker: Equatable, Identifiable {
    let name: String
    var isCompleted: Bool = false
    let id = UUID()
  }
}

enum MeetingAction: Equatable {
  case onAppear
  case nextSpeaker
  case finish
  case speechRecognition(SpeechRecognitionAction)
  case timer(MeetingTimerAction)
}

struct MeetingEnvironment {
  var audioPlayerClient: AudioPlayerClient
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var speechClient: SpeechClient
}

let meetingReducer = Reducer<Meeting, MeetingAction, MeetingEnvironment>.combine(
  speechRecognitionReducer.pullback(
    state: \Meeting.speechRecognition,
    action: /MeetingAction.speechRecognition,
    environment: { SpeechRecognitionEnvironment(mainQueue: $0.mainQueue, speechClient: $0.speechClient) }
  ),

  meetingTimerReducer.pullback(
    state: \Meeting.timer,
    action: /MeetingAction.timer,
    environment: { MeetingTimerEnvironment(mainQueue: $0.mainQueue) }
  ),

  Reducer { state, action, environment in
    switch action {
    case .finish:
      return .merge(
        Effect(value: .timer(.stop)),
        Effect(value: .speechRecognition(.stop))
      )

    case .onAppear:
      return .merge(
        Effect(value: .timer(.start)),
        Effect(value: .speechRecognition(.start))
      )

    case .nextSpeaker:
      state.speakers[state.activeSpeakerIndex].isCompleted = true
      let nextIndex = state.activeSpeakerIndex + 1
      state.timer.secondsElapsed = Int(state.secondsPerSpeaker * Double(nextIndex))
      if nextIndex < state.speakers.count {
        state.activeSpeakerIndex = nextIndex
        return .none
      } else {
        return Effect(value: .finish)
      }

    case .speechRecognition:
      return .none

    case .timer(.tick):
      if state.secondsElapsedForSpeaker >= Int(state.secondsPerSpeaker) {
        return .merge(
          Effect(value: .nextSpeaker),
          environment.audioPlayerClient.play(.ding).fireAndForget()
        )
      } else {
        return .none
      }

    case .timer:
      return .none
    }
  }
)

struct MeetingView: View {
  let store: Store<Meeting, MeetingAction>

  struct ViewState: Equatable {
    let scrumColor: Color

    init(state: Meeting) {
      self.scrumColor = state.scrumColor
    }
  }

  var body: some View {
    WithViewStore(self.store.scope(state: ViewState.init)) { viewStore in
      ZStack {
        RoundedRectangle(cornerRadius: 16.0)
          .fill(viewStore.scrumColor)
        VStack {
          MeetingHeaderView(store: self.store)
          MeetingTimerView(store: self.store)
          MeetingFooterView(store: self.store)
        }
      }
      .padding()
      .foregroundColor(viewStore.scrumColor.accessibleFontColor)
      .onAppear { viewStore.send(.onAppear) }
    }
  }
}
