import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var parents: [Parent] = []
    @Published var children: [Child] = []
    @Published var vaccines: [Vaccine] = []
    @Published var recommendations: [Recommendation] = []
    @Published var doses: [Dose] = []
    @Published var records: [Vaccination] = []
    @Published var reminders: [Reminder] = []
    @Published var loading = false
    @Published var saving = false
    @Published var connected = false
    @Published var error: String?
    @Published var notice: String?
    @Published private(set) var childID: String
    @Published private(set) var parentID: String
    @Published private(set) var address: String
    private var revision = 0
    private let defaults: UserDefaults
    private let session: URLSession

    init(defaults: UserDefaults = .standard, session: URLSession = APIClient.defaultSession) {
        self.defaults = defaults
        self.session = session
        #if os(macOS)
        let defaultAddress = "http://127.0.0.1:8000"
        #else
        let defaultAddress = ""
        #endif
        address = defaults.string(forKey: "apiAddress") ?? defaultAddress
        childID = defaults.string(forKey: "childID") ?? ""
        parentID = defaults.string(forKey: "parentID") ?? ""
    }

    var child: Child? { children.first { $0.id == childID } }
    var familyChildren: [Child] { children.filter { $0.parentId == parentID } }
    var parentName: String { parents.first { $0.id == parentID }?.name ?? "Your family" }

    func chooseChild(_ identifier: String) {
        guard !saving else { return }
        childID = identifier
        if let child { parentID = child.parentId }
        clearChildData()
        persistSelection()
        Task { await reload() }
    }

    func chooseParent(_ identifier: String) {
        guard !saving else { return }
        parentID = identifier
        childID = familyChildren.first?.id ?? ""
        clearChildData()
        persistSelection()
        Task { await reload() }
    }

    private func clearChildData() {
        revision += 1
        doses = []
        records = []
        reminders = []
    }

    private func persistSelection() {
        defaults.set(childID, forKey: "childID")
        defaults.set(parentID, forKey: "parentID")
    }

    func connect(_ value: String) async -> Bool {
        guard !saving else { return false }
        do {
            let client = try APIClient(address: value, session: session)
            _ = try await client.request("health")
            address = client.baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            defaults.set(address, forKey: "apiAddress")
            clearChildData()
            parents = []
            children = []
            vaccines = []
            recommendations = []
            childID = ""
            parentID = ""
            notice = "Connected to your local demo server."
            return await reload()
        } catch {
            self.error = friendly(error)
            return false
        }
    }

    @discardableResult
    func reload() async -> Bool {
        revision += 1
        let current = revision
        loading = true
        error = nil
        defer { if current == revision { loading = false } }
        guard !address.isEmpty else {
            connected = false
            return false
        }
        do {
            let client = try APIClient(address: address, session: session)
            async let fetchedParents: [Parent] = client.get("parents")
            async let fetchedChildren: [Child] = client.get("children")
            async let fetchedVaccines: [Vaccine] = client.get("vaccines")
            async let fetchedRecommendations: [Recommendation] = client.get("schedules/recommended")
            let snapshot = try await (fetchedParents, fetchedChildren, fetchedVaccines, fetchedRecommendations)
            guard current == revision else { return false }
            parents = snapshot.0
            children = snapshot.1
            vaccines = snapshot.2
            recommendations = snapshot.3
            if !parents.contains(where: { $0.id == parentID }) { parentID = parents.first?.id ?? "" }
            if !familyChildren.contains(where: { $0.id == childID }) { childID = familyChildren.first?.id ?? "" }
            persistSelection()
            if !childID.isEmpty {
                let query = [URLQueryItem(name: "child_id", value: childID)]
                async let fetchedDoses: [Dose] = client.get("schedules", query: query)
                async let fetchedRecords: [Vaccination] = client.get("records", query: query)
                async let fetchedReminders: [Reminder] = client.get("reminders", query: query)
                let details = try await (fetchedDoses, fetchedRecords, fetchedReminders)
                guard current == revision else { return false }
                doses = details.0
                records = details.1
                reminders = details.2
            } else {
                doses = []
                records = []
                reminders = []
            }
            connected = true
            return true
        } catch {
            guard current == revision else { return false }
            connected = false
            self.error = friendly(error)
            return false
        }
    }

    func save(_ path: String, method: String = "POST", body: [String: Any]? = nil, message: String) async -> Bool {
        guard !saving, connected, !loading else { return false }
        saving = true
        error = nil
        notice = nil
        defer { saving = false }
        do {
            let client = try APIClient(address: address, session: session)
            let data = try await client.request(path, method: method, body: body)
            if let created = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                if path == "parents", let identifier = created["parent_id"] as? String {
                    parentID = identifier
                    childID = ""
                }
                if path == "children", let identifier = created["child_id"] as? String { childID = identifier }
            }
            if method == "DELETE" {
                // Do not leave deleted records visible if the refresh fails.
                clearChildData()
            }
            persistSelection()
            let refreshed = await reload()
            notice = message + (refreshed ? "" : " Saved successfully, but refresh failed. Refresh to see the latest data; do not submit again.")
            return true
        } catch {
            if let network = error as? URLError, [.timedOut, .networkConnectionLost].contains(network.code) {
                self.error = "The server response was interrupted. The change may have been saved. Refresh and check before trying again."
            } else {
                self.error = friendly(error)
            }
            return false
        }
    }

    func delete(_ target: DeletionTarget) async -> Bool {
        await save(target.id, method: "DELETE", message: target.successMessage)
    }

    private func friendly(_ error: Error) -> String {
        if error is URLError {
            return "Cannot reach the local server. Keep the Python server running, check the server address, and allow Local Network access. iPhone and Mac must share the same Wi-Fi."
        }
        if error is DecodingError { return "The server returned data this app could not read. Check that you are running the supplied Python API." }
        return error.localizedDescription
    }
}
