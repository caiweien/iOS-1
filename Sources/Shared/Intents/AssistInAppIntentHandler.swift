import Intents
import ObjectMapper
import HAKit
import PromiseKit

@available(watchOS 6, *)
final class AssistInAppIntentHandler: NSObject, AssistInAppIntentHandling {
    typealias Intent = AssistInAppIntent

    private var connection: HAConnection?

    func resolveServer(for intent: Intent, with completion: @escaping (IntentServerResolutionResult) -> Void) {
        if let server = Current.servers.server(for: intent) {
            completion(.success(with: .init(server: server)))
        } else {
            completion(.needsValue())
        }
    }

    func provideServerOptions(for intent: Intent, with completion: @escaping ([IntentServer]?, Error?) -> Void) {
        completion(IntentServer.all, nil)
    }

    @available(iOS 14, watchOS 7, *)
    func provideServerOptionsCollection(
        for intent: Intent,
        with completion: @escaping (INObjectCollection<IntentServer>?, Error?) -> Void
    ) {
        completion(.init(items: IntentServer.all), nil)
    }

    func resolvePipeline(for intent: AssistInAppIntent, with completion: @escaping (IntentAssistPipelineResolutionResult) -> Void) {
        let request = HARequest(type: .webSocket("assist_pipeline/pipeline/list"))
        let server = Current.servers.server(for: intent)
        connection = Current.api(for: server!).connection
        let pipelinesRequest = connection?.send(request)

        pipelinesRequest?.promise.pipe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .fulfilled(let data):
                switch data {
                case .dictionary(let dictionary):
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                        print(dictionary)
                        let pipelines = try JSONDecoder().decode(PipelineResponse.self, from: jsonData)

//                        completion(
//                            .success(
//                                with: .init(
//                                    identifier: pipelines.pipelines.first!.id,
//                                    display: pipelines.pipelines.first!.name,
//                                    pronunciationHint: pipelines.pipelines.first!.name
//                                )
//                            )
//                        )
                        completion(.disambiguation(with: pipelines.pipelines.map({ pipeline in
                                .init(
                                    identifier: pipeline.id,
                                    display: pipeline.name,
                                    pronunciationHint: pipeline.name
                                )
                        })))
                    } catch {

                    }
                default:
                    break
                }
            case .rejected(let error):
                print(error)
            }
        }
    }
}
