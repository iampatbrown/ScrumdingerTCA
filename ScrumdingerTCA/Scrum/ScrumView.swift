import ComposableArchitecture
import SwiftUI

struct Scrum: Equatable, Identifiable {
  var attendees: [String] = []
  var color: Color = .orange
  var edit: EditState?
  var history: [History] = []
  var id = UUID()
  var lengthInMinutes: Int = 5
  var meeting: Meeting?
  var title: String = ""

  struct History: Equatable, Identifiable {
    var attendees: [String] = []
    var date = Date()
    var id = UUID()
    var lengthInMinutes: Int
    var transcript: String?
  }
}

enum ScrumAction: Equatable {
  case doneEditingButtonTapped
  case edit(EditAction)
  case meeting(MeetingAction)
  case setEditing(isPresented: Bool)
  case setMeeting(isActive: Bool)
}

struct ScrumEnvironment {
  var audioPlayerClient: AudioPlayerClient
  var date: () -> Date
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var speechClient: SpeechClient
  var uuid: () -> UUID
}

let scrumReducer = Reducer<Scrum, ScrumAction, ScrumEnvironment>.combine(
  editReducer
    .optional()
    .pullback(
      state: \Scrum.edit,
      action: /ScrumAction.edit,
      environment: { _ in }
    ),

 
  Reducer { state, action, environment in
    switch action {
    case .doneEditingButtonTapped:
      if let edit = state.edit {
        state.attendees = edit.attendees
        state.color = edit.color
        state.lengthInMinutes = Int(edit.lengthInMinutes)
        state.title = edit.title
      }
      return Effect(value: .setEditing(isPresented: false))

    case .edit:
      return .none

    case .meeting:
      return .none

    case .setEditing(isPresented: true):
      state.edit = EditState(state: state)
      return .none

    case .setEditing(isPresented: false):
      state.edit = nil
      return .none

    case .setMeeting(isActive: true):
      state.meeting = Meeting(state: state)
      return .none

    case .setMeeting(isActive: false):
      if let meeting = state.meeting {
        let id = environment.uuid()
        let date = environment.date()
        let newHistory = Scrum.History(id: id, date: date, state: meeting)
        state.history.insert(newHistory, at: 0)
        state.meeting = nil
      }
      return .none
    }
  }.presents(
    meetingReducer,
    state: \Scrum.meeting,
    action: /ScrumAction.meeting,
    environment: {
      MeetingEnvironment(
        audioPlayerClient: $0.audioPlayerClient,
        mainQueue: $0.mainQueue,
        speechClient: $0.speechClient
      )
    },
    onDisappear: .finish
  )
)

extension EditState {
  init(state: Scrum) {
    self.attendees = state.attendees
    self.color = state.color
    self.lengthInMinutes = Double(state.lengthInMinutes)
    self.title = state.title
  }
}

extension Scrum.History {
  init(id: UUID, date: Date, state: Meeting) {
    self.attendees = state.attendees
    self.date = date
    self.id = id
    self.lengthInMinutes = state.timer.secondsElapsed / 60
    self.transcript = state.speechRecognition.transcribedText
  }
}

extension Meeting {
  init(state: Scrum) {
    self.scrumColor = state.color
    self.timer = MeetingTimer(lengthInMinutes: state.lengthInMinutes)
    self.speakers = state.attendees.isEmpty ? [Speaker(name: "Someone")] : state.attendees.map { Speaker(name: $0) }
  }
}

struct ScrumView: View {
  let store: Store<Scrum, ScrumAction>

  struct ViewState: Equatable {
    let attendees: [String]
    let color: Color
    let history: [Scrum.History]
    let lengthInMinutes: Int
    let isEditingPresented: Bool
    let isMeetingActive: Bool
    let title: String

    init(state: Scrum) {
      self.attendees = state.attendees
      self.color = state.color
      self.history = state.history
      self.lengthInMinutes = state.lengthInMinutes
      self.isEditingPresented = state.edit != nil
      self.isMeetingActive = state.meeting != nil
      self.title = state.title
    }
  }

  var body: some View {
    WithViewStore(self.store.scope(state: ViewState.init)) { viewStore in
      List {
        Section(header: Text("Meeting Info")) {
          NavigationLink(
            isActive: viewStore.binding(
              get: \.isMeetingActive,
              send: ScrumAction.setMeeting(isActive:)
            ),
            destination: {
              IfLetStore(
                self.store.scope(
                  state: \Scrum.meeting,
                  action: ScrumAction.meeting
                ),
                then: MeetingView.init(store:)
              )
            },
            label: {
              Label("Start Meeting", systemImage: "timer")
                .font(.headline)
                .foregroundColor(.accentColor)
                .accessibilityLabel(Text("start meeting"))
            }
          )

          HStack {
            Label("Length", systemImage: "clock")
              .accessibilityLabel(Text("meeting length"))
            Spacer()
            Text("\(viewStore.lengthInMinutes) minutes")
          }
          HStack {
            Label("Color", systemImage: "paintpalette")
            Spacer()
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(viewStore.color)
          }
          .accessibilityElement(children: .ignore)
        }
        Section(header: Text("Attendees")) {
          ForEach(viewStore.attendees, id: \.self) { attendee in
            Label(attendee, systemImage: "person")
              .accessibilityLabel(Text("person"))
              .accessibilityValue(Text(attendee))
          }
        }

        Section(header: Text("History")) {
          if viewStore.history.isEmpty {
            Label("No meetings yet", systemImage: "calendar.badge.exclamationmark")
          }
          ForEach(viewStore.history) { history in
            NavigationLink(
              destination: HistoryView(history: history)
            ) {
              HStack {
                Image(systemName: "calendar")
                Text(history.date, style: .date)
              }
            }
          }
        }
      }
      .listStyle(InsetGroupedListStyle())
      .navigationBarItems(
        trailing: Button("Edit") { viewStore.send(.setEditing(isPresented: true)) }
      )
      .navigationTitle(viewStore.title)
      .fullScreenCover(
        isPresented: viewStore.binding(
          get: \.isEditingPresented,
          send: ScrumAction.setEditing(isPresented:)
        )
      ) {
        NavigationView {
          IfLetStore(
            self.store.scope(
              state: \Scrum.edit,
              action: ScrumAction.edit
            ),
            then: EditView.init(store:)
          )
          .navigationTitle(viewStore.title)
          .navigationBarItems(
            leading: Button("Cancel") { viewStore.send(.setEditing(isPresented: false)) },
            trailing: Button("Done") { viewStore.send(.doneEditingButtonTapped) }
          )
        }
      }
    }
  }
}
