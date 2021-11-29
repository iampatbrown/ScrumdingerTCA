import ComposableArchitecture
import SwiftUI

struct EditState: Equatable {
  var attendees: [String] = []
  @BindableState var color: Color = .random
  @BindableState var lengthInMinutes: Double = 5.0
  @BindableState var newAttendee: String = ""
  @BindableState var title: String = ""
}

enum EditAction: Equatable, BindableAction {
  case addNewAttendeeButtonTapped
  case binding(BindingAction<EditState>)
  case deleteAttendee(IndexSet)
}

let editReducer = Reducer<EditState, EditAction, Void> { state, action, _ in
  switch action {
  case .addNewAttendeeButtonTapped:
    state.attendees.append(state.newAttendee)
    state.newAttendee = ""
    return .none

  case .binding:
    return .none

  case let .deleteAttendee(indexSet):
    state.attendees.remove(atOffsets: indexSet)
    return .none
  }
}.binding()

struct EditView: View {
  let store: Store<EditState, EditAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      List {
        Section(header: Text("Meeting Info")) {
          TextField("Title", text: viewStore.binding(\.$title))
          HStack {
            Slider(
              value: viewStore.binding(\.$lengthInMinutes),
              in: 5...30,
              step: 1.0,
              label: { Text("Length") }
            )
            .accessibilityValue(Text("\(Int(viewStore.lengthInMinutes)) minutes"))
            Spacer()
            Text("\(Int(viewStore.lengthInMinutes)) minutes")
              .accessibilityHidden(true)
          }
          ColorPicker("Color", selection: viewStore.binding(\.$color))
            .accessibilityLabel(Text("Color picker"))
        }
        Section(header: Text("Attendees")) {
          ForEach(viewStore.attendees, id: \.self, content: Text.init)
            .onDelete { viewStore.send(.deleteAttendee($0)) }
          HStack {
            TextField("New Attendee", text: viewStore.binding(\.$newAttendee))
            Button(action: { viewStore.send(.addNewAttendeeButtonTapped, animation: .default) }) {
              Image(systemName: "plus.circle.fill")
                .accessibilityLabel(Text("Add attendee"))
            }
            .disabled(viewStore.newAttendee.isEmpty)
          }
        }
      }
      .listStyle(.insetGrouped)
    }
  }
}

struct EditView_Previews: PreviewProvider {
  static var previews: some View {
    EditView(
      store: Store(
        initialState: EditState(),
        reducer: editReducer,
        environment: ()
      )
    )
  }
}
