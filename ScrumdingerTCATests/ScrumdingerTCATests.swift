import ComposableArchitecture
@testable import ScrumdingerTCA
import XCTest

class ScrumdingerTCATests: XCTestCase {
  let scheduler = DispatchQueue.test

  func testAddScrum() throws {
    let store = TestStore(
      initialState: Scrums(),
      reducer: scrumsReducer,
      environment: ScrumsEnvironment(
        audioPlayerClient: .failing,
        date: { Date(timeIntervalSince1970: 0) },
        mainQueue: scheduler.eraseToAnyScheduler(),
        randomColor: { .orange },
        speechClient: .failing, uuid: UUID.incrementing
      )
    )

    store.send(.setNewScrumSheet(isPresented: true)) {
      $0.newScrum = EditState(color: .orange)
    }

    store.send(.addScrumButtonTapped) {
      $0.scrums.append(
        Scrum(
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          state: $0.newScrum!
        )
      )
      $0.newScrum = nil
    }

    store.send(.setNewScrumSheet(isPresented: true)) {
      $0.newScrum = EditState(color: .orange)
    }

    store.send(.addScrumButtonTapped) {
      $0.scrums.append(
        Scrum(
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          state: $0.newScrum!
        )
      )
      $0.newScrum = nil
    }
  }

  func testEditScrum() throws {
    let store = TestStore(
      initialState: EditState(),
      reducer: editReducer,
      environment: ()
    )

    store.send(.set(\.$title, "Test Meeting")) {
      $0.title = "Test Meeting"
    }

    store.send(.set(\.$newAttendee, "Blob")) {
      $0.newAttendee = "Blob"
    }

    store.send(.addNewAttendeeButtonTapped) {
      $0.attendees.append("Blob")
      $0.newAttendee = ""
    }

    store.send(.deleteAttendee(.init(integer: 0))) {
      $0.attendees.remove(at: 0)
    }
  }

  func testMeeting() {
    let store = TestStore(
      initialState: Meeting(
        speakers: [
          .init(name: "Blob"),
          .init(name: "Alice"),
        ],
        speechRecognition: .init(authorizationStatus: .authorized),
        timer: .init(lengthInMinutes: 2)
      ),
      reducer: meetingReducer,
      environment: MeetingEnvironment(
        audioPlayerClient: .noop,
        mainQueue: scheduler.eraseToAnyScheduler(),
        speechClient: .mock
      )
    )

    store.send(.onAppear)

    store.receive(.timer(.start)) {
      $0.timer.isActive = true
    }

    store.receive(.speechRecognition(.start)) {
      $0.speechRecognition.isRecording = true
    }

    self.scheduler.advance(by: 59)

    for secondsElapsed in 1..<60 {
      store.receive(.timer(.tick)) {
        $0.timer.secondsElapsed = secondsElapsed
      }
    }

    self.scheduler.advance(by: 1)

    store.receive(.timer(.tick)) {
      $0.timer.secondsElapsed = 60
    }

    store.receive(.nextSpeaker) {
      $0.speakers[0].isCompleted = true
      $0.activeSpeakerIndex = 1
    }

    self.scheduler.advance(by: 59)

    for secondsElapsed in 61..<120 {
      store.receive(.timer(.tick)) {
        $0.timer.secondsElapsed = secondsElapsed
      }
    }

    self.scheduler.advance(by: 1)

    store.receive(.timer(.tick)) {
      $0.timer.secondsElapsed = 120
    }

    store.receive(.timer(.stop)) {
      $0.timer.isActive = false
    }

    store.receive(.nextSpeaker) {
      $0.speakers[1].isCompleted = true
    }

    store.receive(.finish)

    store.receive(.speechRecognition(.stop)) {
      $0.speechRecognition.isRecording = false
    }
  }
}

extension UUID {
  // A deterministic, auto-incrementing "UUID" generator for testing.
  static var incrementing: () -> UUID {
    var uuid = 0
    return {
      defer { uuid += 1 }
      return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
    }
  }
}
