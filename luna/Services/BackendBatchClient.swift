import Foundation

protocol BackendBatchClient {
    func submit(_ request: LogBatchRequest) async throws -> LogBatchResponse
}

struct LogBatchRequest: Codable, Sendable {
    var appVersion: String
    var generatedAt: Date
    var cycleLength: Int
    var periodLength: Int
    var entries: [LogBatchEntry]
}

struct LogBatchEntry: Codable, Sendable {
    var id: UUID
    var createdAt: Date
    var text: String
    var cycleDay: Int
    var phase: CyclePhase
}

struct LogBatchResponse: Codable, Sendable {
    var acceptedCount: Int
    var requestId: String?
}

enum BackendBatchError: LocalizedError {
    case notConfigured
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Backend endpoint is not configured."
        case .badStatus(let code):
            return "Backend returned HTTP \(code)."
        }
    }
}

struct HTTPBackendBatchClient: BackendBatchClient {
    var endpoint: URL?
    var session: URLSession

    init(endpoint: URL?, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func submit(_ request: LogBatchRequest) async throws -> LogBatchResponse {
        guard let endpoint else {
            throw BackendBatchError.notConfigured
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

        guard 200..<300 ~= statusCode else {
            throw BackendBatchError.badStatus(statusCode)
        }

        if data.isEmpty {
            return LogBatchResponse(
                acceptedCount: request.entries.count,
                requestId: nil
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LogBatchResponse.self, from: data)
    }
}

actor LLMBatchProcessor {
    private var pendingEntries: [CycleLogEntry] = []
    private let client: BackendBatchClient

    init(client: BackendBatchClient) {
        self.client = client
    }

    func enqueue(_ entry: CycleLogEntry) {
        pendingEntries.append(entry)
    }

    func flush(profile: CycleProfile) async throws -> LogBatchResponse {
        let entries = pendingEntries

        guard !entries.isEmpty else {
            return LogBatchResponse(acceptedCount: 0, requestId: nil)
        }

        let request = LogBatchRequest(
            appVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "0",
            generatedAt: Date(),
            cycleLength: profile.normalized().cycleLength,
            periodLength: profile.normalized().periodLength,
            entries: entries.map {
                LogBatchEntry(
                    id: $0.id,
                    createdAt: $0.createdAt,
                    text: $0.text,
                    cycleDay: $0.cycleDay,
                    phase: $0.phase
                )
            }
        )
        let response = try await client.submit(request)
        pendingEntries.removeAll()

        return response
    }
}
