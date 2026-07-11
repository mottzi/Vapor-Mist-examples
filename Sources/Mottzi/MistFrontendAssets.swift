import Foundation
import Mist
import Vapor

extension Application {

    /// Publishes the browser runtime embedded in the selected Mist revision.
    func useMistFrontendAssets() {
        for asset in MistAsset.allCases {
            let metadata = MistAssets.metadata(for: asset)
            let path = PathComponent(stringLiteral: metadata.filename)

            for method in [HTTPMethod.GET, .HEAD] {
                on(method, path) { request -> Response in
                    self.mistAssetResponse(for: request, metadata: metadata)
                }
            }
        }
    }

    private func mistAssetResponse(for request: Request, metadata: MistAssetMetadata) -> Response {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentType, value: metadata.mediaType)
        headers.replaceOrAdd(name: .cacheControl, value: "no-cache")
        headers.replaceOrAdd(name: .eTag, value: metadata.etag)

        guard !request.headers.ifNoneMatch(metadata.etag) else {
            return Response(status: .notModified, headers: headers)
        }

        return Response(
            status: .ok,
            headers: headers,
            body: .init(data: Data(metadata.bytes))
        )
    }

}

extension HTTPHeaders {

    fileprivate func ifNoneMatch(_ etag: String) -> Bool {
        let expected = weakETagValue(etag)

        return self[.ifNoneMatch]
            .flatMap { $0.split(separator: ",") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .contains { value in
                value == "*" || weakETagValue(value) == expected
            }
    }

    private func weakETagValue(_ value: String) -> String {
        value.hasPrefix("W/") ? String(value.dropFirst(2)) : value
    }

}
