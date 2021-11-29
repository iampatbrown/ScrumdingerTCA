import Speech

extension SFSpeechAudioBufferRecognitionRequest {
  convenience init(
    requiresOnDeviceRecognition: Bool = false,
    shouldReportPartialResults: Bool = true,
    contextualStrings: [String] = [],
    taskHint: SFSpeechRecognitionTaskHint = .unspecified
  ) {
    self.init()
    self.requiresOnDeviceRecognition = requiresOnDeviceRecognition
    self.shouldReportPartialResults = shouldReportPartialResults
    self.contextualStrings = contextualStrings
    self.taskHint = taskHint
  }
}

struct SpeechRecognitionResult: Equatable {
  var bestTranscription: Transcription
  var transcriptions: [Transcription]
  var isFinal: Bool
  var speechRecognitionMetadata: SpeechRecognitionMetadata?
}

struct Transcription: Equatable {
  var formattedString: String
  var segments: [TranscriptionSegment]
}

struct TranscriptionSegment: Equatable {
  var alternativeSubstrings: [String]
  var confidence: Float
  var duration: TimeInterval
  var substring: String
  var substringRange: NSRange
  var timestamp: TimeInterval
}

struct SpeechRecognitionMetadata: Equatable {
  var averagePauseDuration: TimeInterval
  var speakingRate: Double
  var speechDuration: TimeInterval
  var speechStartTimestamp: TimeInterval
  var voiceAnalytics: VoiceAnalytics?
}

struct VoiceAnalytics: Equatable {
  var jitter: AcousticFeature
  var pitch: AcousticFeature
  var shimmer: AcousticFeature
  var voicing: AcousticFeature
}

struct AcousticFeature: Equatable {
  var acousticFeatureValuePerFrame: [Double]
  var frameDuration: TimeInterval
}

extension SpeechRecognitionResult {
  init(_ speechRecognitionResult: SFSpeechRecognitionResult) {
    self.bestTranscription = Transcription(speechRecognitionResult.bestTranscription)
    self.transcriptions = speechRecognitionResult.transcriptions.map(Transcription.init)
    self.isFinal = speechRecognitionResult.isFinal
    self.speechRecognitionMetadata = speechRecognitionResult.speechRecognitionMetadata
      .map(SpeechRecognitionMetadata.init)
  }
}

extension Transcription {
  init(_ transcription: SFTranscription) {
    self.formattedString = transcription.formattedString
    self.segments = transcription.segments.map(TranscriptionSegment.init)
  }
}

extension TranscriptionSegment {
  init(_ transcriptionSegment: SFTranscriptionSegment) {
    self.alternativeSubstrings = transcriptionSegment.alternativeSubstrings
    self.confidence = transcriptionSegment.confidence
    self.duration = transcriptionSegment.duration
    self.substring = transcriptionSegment.substring
    self.substringRange = transcriptionSegment.substringRange
    self.timestamp = transcriptionSegment.timestamp
  }
}

extension SpeechRecognitionMetadata {
  init(_ speechRecognitionMetadata: SFSpeechRecognitionMetadata) {
    self.averagePauseDuration = speechRecognitionMetadata.averagePauseDuration
    self.speakingRate = speechRecognitionMetadata.speakingRate
    self.speechDuration = speechRecognitionMetadata.speechDuration
    self.speechStartTimestamp = speechRecognitionMetadata.speechStartTimestamp
    self.voiceAnalytics = speechRecognitionMetadata.voiceAnalytics.map(VoiceAnalytics.init)
  }
}

extension VoiceAnalytics {
  init(_ voiceAnalytics: SFVoiceAnalytics) {
    self.jitter = AcousticFeature(voiceAnalytics.jitter)
    self.pitch = AcousticFeature(voiceAnalytics.pitch)
    self.shimmer = AcousticFeature(voiceAnalytics.shimmer)
    self.voicing = AcousticFeature(voiceAnalytics.voicing)
  }
}

extension AcousticFeature {
  init(_ acousticFeature: SFAcousticFeature) {
    self.acousticFeatureValuePerFrame = acousticFeature.acousticFeatureValuePerFrame
    self.frameDuration = acousticFeature.frameDuration
  }
}
