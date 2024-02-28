import Foundation

public struct PipelineResponse: Codable {
    public let preferredPipeline: String
    public let pipelines: [Pipeline]

    private enum CodingKeys: String, CodingKey {
        case preferredPipeline = "preferred_pipeline"
        case pipelines
    }
}

public struct Pipeline: Codable {
    public let conversationEngine: String?
    public let conversationLanguage: String?
    public let id: String
    public let language: String?
    public let name: String
    public let sttEngine: String?
    public let sttLanguage: String?
    public let ttsEngine: String?
    public let ttsLanguage: String?
    public let ttsVoice: String?
    public let wakeWordEntity: String?
    public let wakeWordId: String?

    private enum CodingKeys: String, CodingKey {
        case conversationEngine = "conversation_engine"
        case conversationLanguage = "conversation_language"
        case id
        case language
        case name
        case sttEngine = "stt_engine"
        case sttLanguage = "stt_language"
        case ttsEngine = "tts_engine"
        case ttsLanguage = "tts_language"
        case ttsVoice = "tts_voice"
        case wakeWordEntity = "wake_word_entity"
        case wakeWordId = "wake_word_id"
    }
}

public struct AssistResponse: Codable {
    public struct AssistData: Codable {
        public let pipeline: String?
        public let language: String?
        public let intentOutput: IntentOutput?
        public let runnerData: RunnerData?

        enum CodingKeys: String, CodingKey {
            case pipeline, language
            case intentOutput = "intent_output"
            case runnerData = "runner_data"
        }

        public struct RunnerData: Codable {
            public let sttBinaryHandlerId: Int?
            public let timeout: Int?

            enum CodingKeys: String, CodingKey {
                case timeout
                case sttBinaryHandlerId = "stt_binary_handler_id"
            }
        }

        public struct IntentOutput: Codable {
            public let response: Response?
        }

        public struct Response: Codable {
            public let speech: Speech
        }

        public struct Speech: Codable {
            public let plain: Plain
        }

        public struct Plain: Codable {
            public let speech: String
        }
    }

    public let type: AssistEvent
    public let data: AssistData?
    public let timestamp: String
}

public enum AssistEvent: String, Codable {
    case runStart = "run-start"
    case runEnd = "run-end"
    case wakeWordStart = "wake_word-start"
    case wakeWordEnd = "wake_word-end"
    case sttStart = "stt-start"
    case sttVadStart = "stt-vad-start"
    case sttVadEnd = "stt-vad-end"
    case sttEnd = "stt-end"
    case intentStart = "intent-start"
    case intentEnd = "intent-end"
    case ttsStart = "tts-start"
    case ttsEnd = "tts-end"
    case error = "error"
}
