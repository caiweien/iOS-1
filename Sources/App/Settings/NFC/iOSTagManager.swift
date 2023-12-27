import CoreNFC
import Foundation
import PromiseKit
import Shared

class iOSTagManager: TagManager {
    var isNFCAvailable: Bool {
        // We need both iOS 13 and NFC
        if Current.isCatalyst {
            // NFC doesn't work on Catalyst but _does_ crash occasionally asking
            return false
        } else {
            return NFCNDEFReaderSession.readingAvailable
        }
    }

    func readNFC() -> Promise<String> {
        let reader = NFCReader()
        var readerRetain: NFCReader? = reader

        return firstly {
            reader.promise
        }.ensure {
            withExtendedLifetime(readerRetain) {
                readerRetain = nil
            }
        }.then {
            Self.identifier(from: $0)
        }
    }

    func writeNFC(value: String) -> Promise<String> {
        guard let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: Self.url(for: value)),
              let aarPayload = NFCNDEFPayload.androidPackage(payload: "io.homeassistant.companion.android") else {
            return .init(error: TagManagerError.notHomeAssistantTag)
        }

        let writer = NFCWriter(requiredPayload: [uriPayload], optionalPayload: [aarPayload])
        var writerRetain: NFCWriter? = writer

        return firstly {
            writer.promise
        }.ensure {
            withExtendedLifetime(writerRetain) {
                writerRetain = nil
            }
        }.then { message in
            // we use the same logic as reading, so we can be sure the identifier is right
            Self.identifier(from: message)
        }
    }

    func handle(userActivity: NSUserActivity) -> TagManagerHandleResult {
        guard let url = userActivity.webpageURL else {
            return .unhandled
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let tag = Self.identifier(from: url) {
            fireEvent(tag: tag).cauterize()
            let ndefRecord = userActivity.ndefMessagePayload.records.first
            if ndefRecord == nil || ndefRecord?.typeNameFormat == .empty {
                /*
                 For user activities not generated by background tag reading, ndefMessagePayload returns a message
                 that contains only one NFCNDEFPayload record. That record has a typeNameFormat of NFCTypeNameFormat
                 */
                return .handled(.generic)
            } else {
                return .handled(.nfc)
            }
        }

        if let urlString = components?.queryItems?.first(where: { $0.name.lowercased() == "url" })?.value,
           let url = URL(string: urlString) {
            return .open(url)
        }

        return .unhandled
    }

    private static func url(for identifier: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.home-assistant.io"
        components.path = "/tag/" + identifier
        return components.url!
    }

    private static func identifier(from url: URL) -> String? {
        if url.pathComponents.starts(with: ["/", "tag"]) {
            // ["/", "tag", "5f0ba733-172f-430d-a7f8-e4ad940c88d7"] for example
            let value = url.pathComponents.dropFirst(2).joined(separator: "/")
            if !value.isEmpty {
                return value
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    private static func identifier(from message: NFCNDEFMessage) -> Promise<String> {
        firstly {
            .value(message.records)
        }.compactMapValues { payload in
            payload.wellKnownTypeURIPayload()
        }.compactMapValues { url -> String? in
            Self.identifier(from: url)
        }.map {
            if let value = $0.first {
                return value
            } else {
                throw TagManagerError.notHomeAssistantTag
            }
        }
    }
}
