import Foundation

struct Parent: Codable, Identifiable {
    let parentId: String
    let name: String
    var id: String { parentId }
}

struct Child: Codable, Identifiable {
    let childId: String
    let name: String
    let dateOfBirth: String
    let parentId: String
    var id: String { childId }
}

struct Vaccine: Codable, Identifiable {
    let vaccineId: String
    let vaccineName: String
    let description: String?
    let diseases: [String]?
    var id: String { vaccineId }
}

struct Recommendation: Codable {
    let vaccineId: String
    let doseNumber: Int
    let recommendedMonths: Int
    let recommendedDays: Int
    var key: String { "\(vaccineId)-\(doseNumber)" }
    var sortOrder: Int { recommendedMonths * 31 + recommendedDays }
    var title: String {
        if recommendedMonths == 0 && recommendedDays == 0 { return "At birth" }
        let months: String
        if recommendedMonths >= 12 {
            let years = recommendedMonths / 12
            let remainingMonths = recommendedMonths % 12
            let yearText = "\(years) year\(years == 1 ? "" : "s")"
            let monthText = remainingMonths > 0 ? "\(remainingMonths) month\(remainingMonths == 1 ? "" : "s")" : ""
            months = [yearText, monthText].filter { !$0.isEmpty }.joined(separator: ", ")
        } else {
            months = recommendedMonths > 0 ? "\(recommendedMonths) month\(recommendedMonths == 1 ? "" : "s")" : ""
        }
        let days = recommendedDays > 0 ? "\(recommendedDays) day\(recommendedDays == 1 ? "" : "s")" : ""
        return [months, days].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

struct Dose: Codable, Identifiable {
    let scheduleId: String
    let childId: String
    let vaccineId: String
    let vaccineName: String
    let doseNumber: Int
    let scheduledDate: String
    let provider: String?
    let status: String
    let isOverdue: Bool
    var id: String { scheduleId }
    var key: String { "\(vaccineId)-\(doseNumber)" }
    var completed: Bool { status == "completed" }
}

struct Vaccination: Codable, Identifiable {
    let recordId: String
    let childId: String
    let vaccineName: String
    let doseNumber: Int
    let vaccinationDate: String
    let provider: String?
    var id: String { recordId }
}

struct Reminder: Codable, Identifiable {
    let reminderId: String
    let scheduleId: String
    let childId: String
    let vaccineName: String
    let doseNumber: Int
    let reminderDate: String
    let reminderStatus: String
    var id: String { reminderId }
    var completed: Bool { reminderStatus == "completed" }
}

enum LocalDate {
    static func formatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern
        formatter.isLenient = false
        return formatter
    }

    static func date(_ text: String) -> Date? {
        let normalized = String(text.prefix(19))
        return formatter(normalized.contains("T") ? "yyyy-MM-dd'T'HH:mm:ss" : "yyyy-MM-dd").date(from: normalized)
    }

    static func day(_ date: Date) -> String { formatter("yyyy-MM-dd").string(from: date) }
    static func timestamp(_ date: Date) -> String { formatter("yyyy-MM-dd'T'HH:mm:ss").string(from: date) }
    static func display(_ text: String, time: Bool = false) -> String {
        guard let date = date(text) else { return text }
        return formatter(time ? "d MMM yyyy, h:mm a" : "d MMM yyyy").string(from: date)
    }
}

struct AppFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct APIClient {
    static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
    let baseURL: URL
    let session: URLSession

    init(address: String, session: URLSession = APIClient.defaultSession) throws {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parts = URLComponents(string: trimmed),
              ["http", "https"].contains(parts.scheme?.lowercased() ?? ""),
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              parts.query == nil, parts.fragment == nil,
              parts.path.isEmpty || parts.path == "/",
              let url = parts.url else {
            throw AppFailure(message: "Enter the server address only, such as http://192.168.1.10:8000. Do not include a page path or password.")
        }
        self.baseURL = url
        self.session = session
    }

    func request(_ path: String, method: String = "GET", body: [String: Any]? = nil,
                 query: [URLQueryItem] = []) async throws -> Data {
        var parts = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { parts.queryItems = query }
        var request = URLRequest(url: parts.url!)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw AppFailure(message: "The server returned an unexpected response.")
        }
        guard (200..<300).contains(response.statusCode) else {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let detail = json?["detail"] as? String
            let validation = (json?["detail"] as? [[String: Any]])?.compactMap { $0["msg"] as? String }.joined(separator: "\n")
            throw AppFailure(message: detail ?? validation ?? "The request could not be completed (HTTP \(response.statusCode)).")
        }
        return data
    }

    func get<Value: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Value {
        let data = try await request(path, query: query)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Value.self, from: data)
    }
}


// A confirmation captures the exact target, even if the selected family changes.
struct DeletionTarget: Identifiable {
    enum Kind: String { case child = "children", record = "records", parent = "parents" }
    let kind: Kind
    let identifier: String
    let name: String
    var id: String { "\(kind.rawValue)/\(identifier)" }
    var explanation: String {
        switch kind {
        case .child: return "This deletes the child and all their vaccination records, schedules and reminders."
        case .record: return "This deletes the vaccination record and resets its schedule and reminders to pending. You can then add a corrected record."
        case .parent: return "This deletes the parent, all their children, and every related vaccination record, schedule and reminder."
        }
    }
    var successMessage: String {
        switch kind {
        case .child: return "Child and related data deleted."
        case .record: return "Record deleted. Schedule and reminders reset to pending."
        case .parent: return "Parent and all their children deleted."
        }
    }
}
