import ComposableArchitecture
import SwiftUI

struct SpeechRecognitionState: Equatable {
  var alert: AlertState<SpeechRecognitionAction>?
  var authorizationStatus = SpeechClient.AuthorizationStatus.notDetermined
  var isRecording = false
  var transcribedText = ""
}

enum SpeechRecognitionAction: Equatable {
  case alertDismissed
  case authorizationStatusResponse(SpeechClient.AuthorizationStatus)
  case speech(Result<SpeechClient.Action, SpeechClient.Error>)
  case start
  case stop
}

struct SpeechRecognitionEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var speechClient: SpeechClient
}

let speechRecognitionReducer = Reducer<
  SpeechRecognitionState,
  SpeechRecognitionAction,
  SpeechRecognitionEnvironment
> { state, action, environment in
  struct TaskId: Hashable {}

  switch action {
  case .alertDismissed:
    state.alert = nil
    return .none

  case let .authorizationStatusResponse(status):
    state.authorizationStatus = status == .notDetermined ? .unknown : status
    return Effect(value: .start)

  case let .speech(.success(.availabilityDidChange(isAvailable))):
    // TODO: Test this out
    return .none

  case let .speech(.success(.taskResult(result))):
    state.transcribedText = result.bestTranscription.formattedString
    return result.isFinal ? Effect(value: .stop) : .none

  case let .speech(.failure(error)):
    state.alert = .failure
    return Effect(value: .stop)

  case .stop:
    guard state.isRecording else { return .none }
    state.isRecording = false
    return .merge(
      environment.speechClient.finishTask()
        .fireAndForget(),
      Effect.cancel(id: TaskId())
    )

  case .start:
    guard !state.isRecording else {
      state.alert = .isRecording
      return .none
    }

    switch state.authorizationStatus {
    case .authorized:
      state.isRecording = true
      return environment.speechClient
        .recognitionTask(.init(shouldReportPartialResults: true))
        .catchToEffect(SpeechRecognitionAction.speech)
        .cancellable(id: TaskId())

    case .deniedRecordPermission:
      state.alert = .recordPermissionDenied
      return .none

    case .denied:
      state.alert = .speechRecognitionDenied
      return .none

    case .restricted:
      state.alert = .speechRecognitionRestricted
      return .none

    case .notDetermined:
      return environment.speechClient.requestAuthorization()
        .receive(on: environment.mainQueue)
        .map(SpeechRecognitionAction.authorizationStatusResponse)
        .eraseToEffect()

    case .unknown:
      state.alert = .unknown
      return .none
    }
  }
}

extension AlertState where Action == SpeechRecognitionAction {
  static var failure: Self { .init(title: .init("An error occured while transcribing. Please try again.")) }
  static var isRecording: Self { .init(title: .init("Speech recognition task already in progress.")) }
  static var recordPermissionDenied: Self {
    .init(title: .init("Access to microphone was denied. This app needs access to transcribe your speech."))
  }

  static var speechRecognitionDenied: Self {
    .init(title: .init("Access to speech recognition was denied. This app needs access to transcribe your speech."))
  }

  static var speechRecognitionRestricted: Self { .init(title: .init("Your device does not allow speech recognition.")) }
  static var unknown: Self { .init(title: .init("Speech recognition permissions were unable to be determined.")) }
}
