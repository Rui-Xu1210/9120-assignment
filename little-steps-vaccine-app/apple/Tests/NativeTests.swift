import Foundation

final class StubProtocol: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

@main
struct NativeTests {
    static func require(_ value: Bool, _ message: String) throws {
        if !value { throw AppFailure(message: "FAIL: " + message) }
        print("PASS: " + message)
    }

    @MainActor
    static func main() async throws {
        let date = LocalDate.date("2026-04-20")!
        try require(LocalDate.day(date) == "2026-04-20", "date-only round trip")
        let timestamp = "2026-10-24T09:30:00"
        try require(LocalDate.timestamp(LocalDate.date(timestamp)!) == timestamp, "naive timestamp round trip without Z or offset")
        try require(LocalDate.date("not-a-date") == nil, "invalid date rejected")
        let recommendation = Recommendation(vaccineId: "V00001", doseNumber: 1, recommendedMonths: 2, recommendedDays: 0)
        try require(recommendation.title == "2 months", "calendar-month age grouping")
        try require(Recommendation(vaccineId: "V00001", doseNumber: 1, recommendedMonths: 12, recommendedDays: 0).title == "1 year", "one-year age grouping")
        try require(Recommendation(vaccineId: "V00001", doseNumber: 1, recommendedMonths: 18, recommendedDays: 0).title == "1 year, 6 months", "year-and-month age grouping")
        try require(Recommendation(vaccineId: "V00001", doseNumber: 1, recommendedMonths: 25, recommendedDays: 2).title == "2 years, 1 month, 2 days", "mixed year-month-day age grouping")
        try require(Recommendation(vaccineId: "V00001", doseNumber: 1, recommendedMonths: 0, recommendedDays: 0).title == "At birth", "birth age grouping")
        for address in ["file:///tmp/data", "http://user:password@localhost:8000", "http://localhost:8000/records", "garbage"] {
            do {
                _ = try APIClient(address: address)
                throw AppFailure(message: "Accepted invalid address")
            } catch let error as AppFailure {
                try require(error.message != "Accepted invalid address", "reject invalid/credential-bearing server URL")
            }
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        let client = try APIClient(address: "http://127.0.0.1:8000/", session: URLSession(configuration: config))
        StubProtocol.handler = { request in
            try require(request.url?.path == "/children", "API path assembly")
            try require(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value == "P00001", "query encoding")
            return (200, Data("[{\"child_id\":\"C00001\",\"name\":\"Demo\",\"date_of_birth\":\"2026-04-20\",\"parent_id\":\"P00001\",\"age\":15552000}]".utf8))
        }
        let children: [Child] = try await client.get("children", query: [URLQueryItem(name: "parent_id", value: "P00001")])
        try require(children.first?.id == "C00001", "decode snake_case and ignore interval representation")
        for (status, body, expected) in [(409, "{\"detail\":\"Already recorded\"}", "Already recorded"), (422, "{\"detail\":[{\"msg\":\"Invalid date\"}]}", "Invalid date"), (503, "unavailable", "HTTP 503")] {
            StubProtocol.handler = { _ in (status, Data(body.utf8)) }
            do {
                _ = try await client.request("records", method: "POST", body: ["name": "Test"])
                throw AppFailure(message: "Expected HTTP failure")
            } catch let error as AppFailure {
                try require(error.message.contains(expected), "handle HTTP \(status) error")
            }
        }
        let suite = "LittleStepsTests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("http://127.0.0.1:8000", forKey: "apiAddress")
        let stubSession = URLSession(configuration: config)
        let stubStore = AppStore(defaults: defaults, session: stubSession)
        StubProtocol.handler = { _ in (200, Data("[]".utf8)) }
        let loaded = await stubStore.reload()
        try require(loaded && stubStore.connected, "store connects with empty family")
        StubProtocol.handler = { request in
            if request.httpMethod == "POST" { return (201, Data("{\"parent_id\":\"P00002\",\"name\":\"Demo\"}".utf8)) }
            return (503, Data("{\"detail\":\"Refresh unavailable\"}".utf8))
        }
        let saved = await stubStore.save("parents", body: ["name": "Demo"], message: "Parent added.")
        try require(saved && stubStore.notice?.contains("Saved successfully, but refresh failed") == true, "successful mutation is not misreported when refresh fails")
        try require(!stubStore.saving && !stubStore.loading, "loading and save state reset on failed refresh")
        StubProtocol.handler = { _ in (200, Data("[]".utf8)) }
        _ = await stubStore.reload()
        StubProtocol.handler = { _ in (409, Data("{\"detail\":\"Already recorded\"}".utf8)) }
        let duplicate = await stubStore.save("records", body: [:], message: "Saved")
        try require(!duplicate && stubStore.error == "Already recorded" && stubStore.notice == nil, "duplicate save stays open with actionable error")
        // Deletion tests use the stub server only; no real data is deleted.
        for kind in [DeletionTarget.Kind.child, .record, .parent] {
            StubProtocol.handler = { _ in (200, Data("[]".utf8)) }
            _ = await stubStore.reload()
            let target = DeletionTarget(kind: kind, identifier: "X00001", name: "Demo")
            var deleteCount = 0
            StubProtocol.handler = { request in
                if request.httpMethod == "DELETE" {
                    deleteCount += 1
                    try require(request.url?.path == "/" + target.id, "correct deletion endpoint")
                    try require(request.httpBody == nil && request.httpBodyStream == nil, "DELETE sends no body")
                    return (200, Data("{\"deleted\":true}".utf8))
                }
                return (200, Data("[]".utf8))
            }
            let deleted = await stubStore.delete(target)
            try require(deleted && deleteCount == 1, "one DELETE request for \(kind.rawValue)")
            try require(stubStore.childID.isEmpty && stubStore.parentID.isEmpty, "empty family selection refreshed")
            try require(defaults.string(forKey: "childID") == "" && defaults.string(forKey: "parentID") == "", "selection persisted after deletion")
            try require(!stubStore.saving && stubStore.notice == target.successMessage, "delete feedback and busy state")
        }
        let deleteTarget = DeletionTarget(kind: .child, identifier: "C00001", name: "Demo")
        StubProtocol.handler = { _ in (404, Data("{\"detail\":\"Child not found\"}".utf8)) }
        let missingDelete = await stubStore.delete(deleteTarget)
        try require(!missingDelete && stubStore.error == "Child not found", "failed deletion shows error")
        StubProtocol.handler = { _ in throw URLError(.timedOut) }
        let uncertainDelete = await stubStore.delete(deleteTarget)
        try require(!uncertainDelete && stubStore.error?.contains("may have been saved") == true, "timeout does not claim rollback or retry")
        StubProtocol.handler = { request in
            if request.httpMethod == "DELETE" { return (200, Data("{\"deleted\":true}".utf8)) }
            return (503, Data("{\"detail\":\"Refresh unavailable\"}".utf8))
        }
        let deleteRefreshFailure = await stubStore.delete(deleteTarget)
        try require(deleteRefreshFailure && stubStore.notice?.contains("refresh failed") == true, "committed deletion is distinguished from failed refresh")
        try require(stubStore.records.isEmpty && stubStore.doses.isEmpty && stubStore.reminders.isEmpty, "stale child details cleared after deletion")
        if CommandLine.arguments.contains("--live") {
            let live = try APIClient(address: "http://127.0.0.1:8000")
            let health = try await live.request("health")
            let details = try JSONSerialization.jsonObject(with: health) as! [String: Any]
            try require(details["database"] as? String == "9120assignment_demo", "real API uses only authorized database")
            let parents: [Parent] = try await live.get("parents")
            let children: [Child] = try await live.get("children")
            let vaccines: [Vaccine] = try await live.get("vaccines")
            let recommendations: [Recommendation] = try await live.get("schedules/recommended")
            try require(!parents.isEmpty && !children.isEmpty && vaccines.count == 22 && recommendations.count == 31, "decode all real catalog/family responses")
            if let child = children.first {
                let query = [URLQueryItem(name: "child_id", value: child.id)]
                let doses: [Dose] = try await live.get("schedules", query: query)
                let records: [Vaccination] = try await live.get("records", query: query)
                let reminders: [Reminder] = try await live.get("reminders", query: query)
                try require(doses.count == 31 && reminders.count == 31, "decode real schedules and vaccine_reminder")
                try require(!records.isEmpty && doses.contains(where: \.completed) && reminders.contains(where: \.completed), "decode real recorded dose and linked completion")
            }
            let store = AppStore(defaults: defaults)
            let success = await store.reload()
            try require(success && store.connected && store.child != nil && !store.doses.isEmpty, "native observable store loads real API")
        }
        print("Native tests completed. Live checks are read-only; no database rows were changed.")
    }
}
