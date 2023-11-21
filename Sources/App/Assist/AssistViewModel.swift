//
//  AssistViewModel.swift
//  App
//
//  Created by Bruno Pantaleão on 19/11/2023.
//  Copyright © 2023 Home Assistant. All rights reserved.
//

import Foundation
import Shared
import HAKit
import AVFoundation

@available(iOS 13.0, *)
final class AssistViewModel: NSObject, ObservableObject {
    @Published var chatItems: [AssistChatItem] = []
    @Published var pipelines: [Pipeline] = []
    @Published var preferredPipelineId: String = ""
    @Published var showScreenLoader = false
    @Published var inputText = "How many lights are on?"

    private var captureSession: AVCaptureSession?
    private let connection: HAConnection

    private var sttBinaryHandlerId: UInt8?
    private var cancellable: HACancellable?

    init(server: Server) {
        connection = Current.api(for: server).connection
    }

    func initialWebsocketConnection() {
        connection.delegate = self
        connection.connect()
    }

    func endProcesses() {
        connection.disconnect()
        captureSession?.stopRunning()
    }

    func assist() {
        guard !inputText.isEmpty else { return }
        let request = HARequest(type: .webSocket("assist_pipeline/run"), data: [
            "pipeline": preferredPipelineId,
            "start_stage": "intent",
            "end_stage": "intent",
            "input": [
                "text": inputText
            ]
        ])
        connection.subscribe(to: request) { [weak self] cancellable, data in
            guard let self = self else { return }
            if case .dictionary(let dictionary) = data  {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                    let assistResponse = try JSONDecoder().decode(AssistResponse.self, from: jsonData)
                    print(assistResponse)

                    if assistResponse.type == .intentEnd {
                        if let speech = assistResponse.data?.intentOutput?.response?.speech.plain.speech {
                            self.chatItems.append(.init(id: UUID().uuidString, content: speech, itemType: .output))
                        }
                    }

                } catch let error {
                    print(error)
                }
            }
        }

        chatItems.append(.init(id: UUID().uuidString, content: inputText, itemType: .input))
        inputText = ""
    }

    private func fetchPipelines() {
        showScreenLoader = true
        let request = HARequest(type: .webSocket("assist_pipeline/pipeline/list"))
        let pipelinesRequest = connection.send(request)

        pipelinesRequest.promise.pipe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .fulfilled(let data):
                switch data {
                case .dictionary(let dictionary):
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                        print(dictionary)
                        let pipelines = try JSONDecoder().decode(PipelineResponse.self, from: jsonData)
                        self.preferredPipelineId = pipelines.preferredPipeline
                        self.pipelines = pipelines.pipelines
                        print(pipelines)
                    } catch {
                        print("Error converting dictionary to data: \(error)")
                    }
                default:
                    break
                }
            case .rejected(let error):
                print(error)
            }
        }
    }

    func startStreaming() {
        if captureSession?.isRunning ?? false {
            captureSession?.stopRunning()
            cancellable?.cancel()
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        guard let captureDevice = AVCaptureDevice.default(for: .audio) else { return }

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            let audioInput = try AVCaptureDeviceInput(device: captureDevice)

            captureSession = AVCaptureSession()
            captureSession?.addInput(audioInput)

            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
            captureSession?.addOutput(audioOutput)

            DispatchQueue.global().async { [weak self] in
                self?.captureSession?.startRunning()
            }

            let request = HARequest(type: .webSocket("assist_pipeline/run"), data: [
                "pipeline": preferredPipelineId,
                "start_stage": "stt",
                "end_stage": "tts",
                "input": [
                    "sample_rate": 16000
                ]
            ])
            connection.subscribe(to: request) { [weak self] cancellable, data in
                guard let self = self else { return }
                self.cancellable = cancellable
                if case .dictionary(let dictionary) = data  {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                        let assistResponse = try JSONDecoder().decode(AssistResponse.self, from: jsonData)
                        print(assistResponse)

                        if assistResponse.type == .runStart {
                            if let sttBinaryHandlerId = assistResponse.data?.runnerData?.sttBinaryHandlerId {
                                print("sttBinaryHandlerId: \(sttBinaryHandlerId)")
                                self.sttBinaryHandlerId = UInt8(sttBinaryHandlerId)

                                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                                    let byteArrayString = String(format: "%02X", sttBinaryHandlerId) + "a"

//                                    self.connection.write(data: byteArrayString.data(using: .utf8)!)
                                }
                            }
                        }

                        print("assistResponse: \(assistResponse.type)")

                    } catch let error {
                        print(error)
                    }
                }
            }

        } catch {
            print("Error starting audio streaming: \(error.localizedDescription)")
        }
    }

    private func stopStreaming() {
        captureSession?.stopRunning()
        captureSession = nil
    }

    private func dataFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> Data? {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }

        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var data: UnsafeMutablePointer<Int8>?

        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &data)

        guard let bufferData = data else { return nil }
        let rawData = Data(bytes: bufferData, count: totalLength)

        return rawData
    }
}

@available(iOS 13.0, *)
extension AssistViewModel: HAConnectionDelegate {
    func connection(_ connection: HAConnection, didTransitionTo state: HAConnectionState) {
        switch state {
        case .disconnected(let reason):
            print(reason)
        case .connecting:
            print("connecting...")
        case .authenticating:
            print("authenticating")
        case .ready(let version):
            print(version)

            fetchPipelines()
        }
    }
}

@available(iOS 13.0, *)
extension AssistViewModel: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print(output)
//        print(sampleBuffer)
//        print(connection)
        
        guard let sttBinaryHandlerId = sttBinaryHandlerId,
              let data = dataFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }

        var byteArrayString = [UInt8](data).map({ "\($0)" }).joined()
        byteArrayString = String(format: "%02X", sttBinaryHandlerId) + byteArrayString

//        self.connection.write(data: byteArrayString.data(using: .utf8)!)

    }
}
