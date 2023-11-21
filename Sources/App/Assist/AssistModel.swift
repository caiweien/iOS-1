//
//  AssistModel.swift
//  App
//
//  Created by Bruno Pantaleão on 20/11/2023.
//  Copyright © 2023 Home Assistant. All rights reserved.
//

import Foundation

struct PipelineResponse: Codable {
    let preferredPipeline: String
    let pipelines: [Pipeline]

    private enum CodingKeys: String, CodingKey {
        case preferredPipeline = "preferred_pipeline"
        case pipelines
    }
}

struct Pipeline: Codable {
    let conversationEngine: String?
    let conversationLanguage: String?
    let id: String
    let language: String?
    let name: String
    let sttEngine: String?
    let sttLanguage: String?
    let ttsEngine: String?
    let ttsLanguage: String?
    let ttsVoice: String?
    let wakeWordEntity: String?
    let wakeWordId: String?

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

struct AssistResponse: Codable {
    struct AssistData: Codable {
        let pipeline: String?
        let language: String?
        let intentOutput: IntentOutput?
        let runnerData: RunnerData?

        enum CodingKeys: String, CodingKey {
            case pipeline, language
            case intentOutput = "intent_output"
            case runnerData = "runner_data"
        }

        struct RunnerData: Codable {
            let sttBinaryHandlerId: Int?
            let timeout: Int?

            enum CodingKeys: String, CodingKey {
                case timeout
                case sttBinaryHandlerId = "stt_binary_handler_id"
            }
        }

        struct IntentOutput: Codable {
            let response: Response?
        }

        struct Response: Codable {
            let speech: Speech
        }

        struct Speech: Codable {
            let plain: Plain
        }

        struct Plain: Codable {
            let speech: String
        }
    }

    let type: AssistEvent
    let data: AssistData?
    let timestamp: String
}

enum AssistEvent: String, Codable {
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
