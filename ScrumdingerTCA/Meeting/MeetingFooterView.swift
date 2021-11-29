import ComposableArchitecture
import SwiftUI

struct MeetingFooterView: View {
  let store: Store<Meeting, MeetingAction>

  struct ViewState: Equatable {
    let speakers: [Meeting.Speaker]

    init(state: Meeting) {
      self.speakers = state.speakers
    }

    var speakerNumber: Int? { speakers.firstIndex(where: { !$0.isCompleted }).map { $0 + 1 } }
    var hasNextSpeaker: Bool { speakerNumber ?? speakers.count < speakers.count }
    var isLastSpeaker: Bool { speakerNumber == speakers.count }
    var speakerText: String { speakerNumber.map {  isLastSpeaker ? "Last Speaker" : "Speaker \($0) of \(speakers.count)" } ?? "No more speakers" }
  }

  var body: some View {
    WithViewStore(self.store.scope(state: ViewState.init)) { viewStore in
      VStack {
        HStack {
          Text(viewStore.speakerText)
          if viewStore.hasNextSpeaker {
            Spacer()
            Button(action: { viewStore.send(.nextSpeaker) }) {
              Image(systemName: "forward.fill")
            }
            .accessibility(label: Text("Next speaker"))
          }
        }
      }
      .padding([.bottom, .horizontal])
    }
  }
}
