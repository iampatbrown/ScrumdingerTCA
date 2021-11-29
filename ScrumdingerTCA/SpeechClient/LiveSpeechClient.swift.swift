import AVFoundation
import Combine
import ComposableArchitecture
import Speech

extension SpeechClient {
  static var live: Self {
    var audioEngine: AVAudioEngine?
    var inputNode: AVAudioInputNode?
    var recognitionTask: SFSpeechRecognitionTask?

    return Self(
      finishTask: {
        .fireAndForget {
          audioEngine?.stop()
          inputNode?.removeTap(onBus: 0)
          recognitionTask?.finish()
        }
      },
      recognitionTask: { request in
        Effect.run { subscriber in
          let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
          let speechRecognizerDelegate = SpeechRecognizerDelegate {
            subscriber.send(.availabilityDidChange(isAvailable: $0))
          }

          speechRecognizer.delegate = speechRecognizerDelegate

          let cancellable = AnyCancellable {
            audioEngine?.stop()
            inputNode?.removeTap(onBus: 0)
            recognitionTask?.cancel()
            _ = speechRecognizer
            _ = speechRecognizerDelegate
          }

          audioEngine = AVAudioEngine()
          let audioSession = AVAudioSession.sharedInstance()
          do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
          } catch {
            subscriber.send(completion: .failure(.couldntConfigureAudioSession))
            return cancellable
          }
          inputNode = audioEngine!.inputNode

          recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            switch (result, error) {
            case let (.some(result), _):
              subscriber.send(.taskResult(SpeechRecognitionResult(result)))
              if result.isFinal { subscriber.send(completion: .finished) }
            case let (_, .some(error as NSError)):
              subscriber.send(completion: .failure(.taskError(error)))
            case (.none, .none):
              fatalError("It should not be possible to have both a nil result and nil error.")
            }
          }

          inputNode!.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputNode!.outputFormat(forBus: 0)
          ) { buffer, _ in
            request.append(buffer)
          }

          audioEngine!.prepare()
          do {
            try audioEngine!.start()
          } catch {
            subscriber.send(completion: .failure(.couldntStartAudioEngine))
            return cancellable
          }

          return cancellable
        }
      },
      requestAuthorization: {
        .future { callback in
          AVAudioSession.sharedInstance().requestRecordPermission { isAuthorized in
            guard isAuthorized else { return callback(.success(.deniedRecordPermission)) }
            SFSpeechRecognizer.requestAuthorization { callback(.success(.init($0))) }
          }
        }
      }
    )
  }
}

extension SpeechClient.AuthorizationStatus {
  init(_ status: SFSpeechRecognizerAuthorizationStatus) {
    switch status {
    case .notDetermined:
      self = .notDetermined
    case .denied:
      self = .denied
    case .restricted:
      self = .restricted
    case .authorized:
      self = .authorized
    @unknown default:
      self = .unknown
    }
  }
}

private class SpeechRecognizerDelegate: NSObject, SFSpeechRecognizerDelegate {
  var availabilityDidChange: (Bool) -> Void

  init(availabilityDidChange: @escaping (Bool) -> Void) {
    self.availabilityDidChange = availabilityDidChange
  }

  func speechRecognizer(
    _ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool
  ) {
    self.availabilityDidChange(available)
  }
}
