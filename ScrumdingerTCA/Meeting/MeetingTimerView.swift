import ComposableArchitecture
import SwiftUI

struct SpeakerArc: Shape {
  let speakerIndex: Int
  let totalSpeakers: Int
  private var degreesPerSpeaker: Double {
    360.0 / Double(totalSpeakers)
  }

  private var startAngle: Angle {
    Angle(degrees: degreesPerSpeaker * Double(speakerIndex) + 1.0)
  }

  private var endAngle: Angle {
    Angle(degrees: startAngle.degrees + degreesPerSpeaker - 1.0)
  }

  func path(in rect: CGRect) -> Path {
    let diameter = min(rect.size.width, rect.size.height) - 24.0
    let radius = diameter / 2.0
    let center = CGPoint(
      x: rect.origin.x + rect.size.width / 2.0,
      y: rect.origin.y + rect.size.height / 2.0
    )
    return Path { path in
      path.addArc(
        center: center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: false
      )
    }
  }
}

struct MeetingTimerView: View {
  let store: Store<Meeting, MeetingAction>

  struct ViewState: Equatable {
    let currentSpeaker: String?
    let isRecording: Bool
    let scrumColor: Color
    let speakers: [Meeting.Speaker]
    let timerTrim: Double

    init(state: Meeting) {
      self.currentSpeaker = state.speakers.first(where: { !$0.isCompleted })?.name
      self.isRecording = state.speechRecognition.isRecording
      self.scrumColor = state.scrumColor
      self.speakers = state.speakers
      let tickOffset = state.timer.isActive ? 1 : 0
      self.timerTrim = Double(state.timer.secondsElapsed + tickOffset) / Double(state.timer.lengthInSeconds)
    }
  }

  var body: some View {
    WithViewStore(self.store.scope(state: ViewState.init).actionless) { viewStore in
      ZStack {
        Circle()
          .strokeBorder(lineWidth: 24, antialiased: true)
        VStack {
          if let currentSpeaker = viewStore.currentSpeaker {
            Text(currentSpeaker)
              .font(.title)
            Text("is speaking")

            Image(systemName: viewStore.isRecording ? "mic" : "mic.slash")
              .font(.title)
              .padding(.top)
              .accessibilityLabel(viewStore.isRecording ? "with transcription" : "without transcription")
          } else {
            Text("Finished")
              .font(.title)
          }
        }
        .accessibilityElement(children: .combine)
        .foregroundColor(viewStore.scrumColor.accessibleFontColor)

        Circle()
          .inset(by: 12)
          .trim(from: 0, to: viewStore.timerTrim)
          .rotation(Angle(degrees: -90))
          .stroke(viewStore.scrumColor, lineWidth: 4)
          .animation(.linear(duration: 1), value: viewStore.timerTrim)

        ForEach(viewStore.speakers) { speaker in
          if speaker.isCompleted, let index = viewStore.speakers.firstIndex(where: { $0.id == speaker.id }) {
            SpeakerArc(speakerIndex: index, totalSpeakers: viewStore.speakers.count)
              .rotation(Angle(degrees: -90))
              .stroke(viewStore.scrumColor, lineWidth: 12)
          }
        }
      }.padding(.horizontal)
    }
  }
}
