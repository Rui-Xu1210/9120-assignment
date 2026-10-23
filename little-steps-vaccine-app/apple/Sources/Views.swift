import SwiftUI

enum Theme {
    static let purple = Color(red: 0.43, green: 0.34, blue: 0.65)
    static let lavender = Color(red: 0.94, green: 0.92, blue: 0.98)
    static let green = Color(red: 0.20, green: 0.49, blue: 0.38)
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var tab = 0
    @State private var settings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.loading { ProgressView().controlSize(.small).padding(6) }
                FeedbackView()
                if tab != 3, !store.familyChildren.isEmpty {
                    HStack {
                        Image(systemName: "figure.child.circle.fill").font(.title2).foregroundStyle(Theme.purple)
                        Picker("Child", selection: Binding(get: { store.childID }, set: { store.chooseChild($0) })) {
                            ForEach(store.familyChildren) { child in Text(child.name).tag(child.id) }
                        }
                        .pickerStyle(.menu)
                        .disabled(store.saving || store.loading)
                        Spacer()
                        Text("\(store.records.count) recorded").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Theme.lavender.opacity(0.55))
                }
                if store.child == nil, tab != 3 {
                    ContentUnavailableView {
                        Label(store.address.isEmpty ? "Let's get connected" : "Your family's next step", systemImage: "heart.text.clipboard")
                    } description: {
                        Text(store.address.isEmpty ? "Connect to your computer's demo server to get started." : "Add a parent and child in Family to see their vaccination plan.")
                    } actions: {
                        Button(store.address.isEmpty ? "Connect to server" : "Open Family") {
                            if store.address.isEmpty { settings = true } else { tab = 3 }
                        }.buttonStyle(.borderedProminent)
                    }
                }
                TabView(selection: $tab) {
                    ScheduleView().tabItem { Label("Schedule", systemImage: "calendar") }.tag(0)
                    HistoryView().tabItem { Label("History", systemImage: "checkmark.shield") }.tag(1)
                    RemindersView().tabItem { Label("Reminders", systemImage: "bell") }.tag(2)
                    FamilyView().tabItem { Label("Family", systemImage: "person.2") }.tag(3)
                }
            }
            .navigationTitle("Little Steps")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button { Task { await store.reload() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                        .disabled(store.loading || store.saving || store.address.isEmpty)
                    Button { settings = true } label: { Label("Server settings", systemImage: "gearshape") }
                        .disabled(store.saving || store.loading)
                }
            }
            .sheet(isPresented: $settings) { ServerSettingsView() }
            .task { await store.reload() }
        }
    }
}

struct FeedbackView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        if let text = store.error ?? store.notice {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: store.error == nil ? "checkmark.circle" : "exclamationmark.circle")
                Text(text).font(.callout).textSelection(.enabled)
                Spacer(minLength: 0)
                Button { store.error = nil; store.notice = nil } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).accessibilityLabel("Dismiss message")
            }
            .foregroundStyle(store.error == nil ? Theme.green : Color.primary)
            .padding(12)
            .background(store.error == nil ? Theme.green.opacity(0.09) : Color.orange.opacity(0.12))
        }
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var store: AppStore
    @State private var hideCompleted = false
    @State private var detail: Dose?

    private var groups: [(title: String, order: Int, doses: [Dose])] {
        let lookup = Dictionary(store.recommendations.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        let grouped = Dictionary(grouping: store.doses) { lookup[$0.key]?.title ?? "Other doses" }
        return grouped.map { title, doses in
            (title: title, order: lookup[doses.first?.key ?? ""]?.sortOrder ?? Int.max, doses: doses)
        }.sorted { $0.order == $1.order ? $0.title < $1.title : $0.order < $1.order }
    }

    var body: some View {
        List {
            if let child = store.child {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Small steps. Growing protection.", systemImage: "heart.fill")
                            .font(.headline).foregroundStyle(Theme.purple)
                        Text("\(child.name)'s vaccination plan").font(.title2.bold())
                        Text("Born \(LocalDate.display(child.dateOfBirth))").foregroundStyle(.secondary)
                        ProgressView(value: Double(store.doses.filter(\.completed).count), total: Double(max(1, store.doses.count)))
                            .tint(Theme.green)
                        Text("\(store.doses.filter(\.completed).count) of \(store.doses.count) sample doses recorded")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }.listRowBackground(Theme.lavender.opacity(0.65))
                Section {
                    Toggle("Hide completed age groups", isOn: $hideCompleted)
                }
                ForEach(groups, id: \.title) { group in
                    if !hideCompleted || !group.doses.allSatisfy(\.completed) {
                        Section {
                            ForEach(group.doses) { dose in
                                Button { detail = dose } label: { DoseRow(dose: dose) }
                                    .buttonStyle(.plain)
                                    .disabled(store.loading || store.saving || !store.connected)
                            }
                        } header: {
                            HStack {
                                Text(group.title)
                                Spacer()
                                Text("\(group.doses.filter(\.completed).count)/\(group.doses.count)")
                            }
                        }
                    }
                }
                if hideCompleted && !store.doses.isEmpty && store.doses.allSatisfy(\.completed) {
                    Text("All age groups are recorded. Turn off the filter to review them.").foregroundStyle(Theme.green)
                }
                if store.doses.isEmpty && !store.loading {
                    Text("No planned doses are available. Refresh to check the server.").foregroundStyle(.secondary)
                }
                Section { CourseworkNotice() }
            }
        }
        .refreshable { await store.reload() }
        .sheet(item: $detail) { DoseDetailView(dose: $0) }
    }
}

struct DoseRow: View {
    let dose: Dose
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dose.completed ? "checkmark.circle.fill" : "syringe")
                .font(.title3).foregroundStyle(dose.completed ? Theme.green : Theme.purple)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 5) {
                Text(dose.vaccineName).font(.headline)
                Text("Planned · \(LocalDate.display(dose.scheduledDate))").font(.caption).foregroundStyle(.secondary)
                if dose.isOverdue {
                    Text("Past planned date · check with your provider").font(.caption).foregroundStyle(.orange)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("Dose \(dose.doseNumber)").font(.caption.bold()).padding(6).background(Theme.lavender, in: Capsule())
                Text(dose.completed ? "Recorded" : "Not recorded").font(.caption2).foregroundStyle(dose.completed ? Theme.green : .secondary)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }.padding(.vertical, 5).contentShape(Rectangle())
    }
}

struct CourseworkNotice: View {
    var body: some View {
        Label {
            Text("Sample coursework plan, not medical advice. The supplied data may include alternative vaccine brands. Confirm the right vaccines and timing with your child's healthcare provider. Use fictional family details for this demo.")
                .font(.caption).foregroundStyle(.secondary)
        } icon: { Image(systemName: "info.circle").foregroundStyle(Theme.purple) }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var deletion: DeletionTarget?
    var body: some View {
        List {
            Section {
                Text("A little record of every step").font(.title3.bold())
                Text("Record a vaccination by opening a dose in Schedule.").font(.callout).foregroundStyle(.secondary)
            }
            if store.child != nil && store.records.isEmpty {
                ContentUnavailableView("No vaccinations recorded", systemImage: "checkmark.shield", description: Text("When you record a dose, it will appear here."))
            }
            ForEach(store.records) { record in
                Section {
                    Label(record.vaccineName, systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(Theme.green)
                    LabeledContent("Dose", value: "\(record.doseNumber)")
                    LabeledContent("Given on", value: LocalDate.display(record.vaccinationDate))
                    LabeledContent("Provider", value: record.provider ?? "Not entered")
                    Button(role: .destructive) {
                        deletion = DeletionTarget(kind: .record, identifier: record.id,
                                                  name: "\(record.vaccineName), dose \(record.doseNumber)")
                    } label: { Label("Delete vaccination record", systemImage: "trash") }
                    .disabled(!store.connected || store.loading || store.saving)
                }
            }
        }.refreshable { await store.reload() }
        .sheet(item: $deletion) { DeleteConfirmationView(target: $0) }
    }
}

struct RemindersView: View {
    @EnvironmentObject private var store: AppStore
    @State private var filter = "pending"
    @State private var detail: Reminder?
    private var visible: [Reminder] { store.reminders.filter { filter == "all" || $0.reminderStatus == filter } }

    var body: some View {
        List {
            Section {
                Picker("Show reminders", selection: $filter) {
                    Text("Pending").tag("pending")
                    Text("Completed").tag("completed")
                    Text("All").tag("all")
                }.pickerStyle(.segmented)
                Text("These are saved in-app reminders, not phone notifications. Check the app to review them.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if store.child != nil && visible.isEmpty {
                ContentUnavailableView("No \(filter == "all" ? "" : filter + " ")reminders", systemImage: "bell.badge")
            }
            ForEach(visible) { reminder in
                Button { detail = reminder } label: {
                    HStack(spacing: 12) {
                        Image(systemName: reminder.completed ? "checkmark.circle.fill" : "bell.fill")
                            .foregroundStyle(reminder.completed ? Theme.green : Theme.purple)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(reminder.vaccineName).font(.headline)
                            Text("Dose \(reminder.doseNumber) · \(LocalDate.display(reminder.reminderDate, time: true))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(reminder.completed ? "Completed" : "Pending").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 5).contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(!store.connected || store.loading || store.saving)
            }
        }
        .refreshable { await store.reload() }
        .sheet(item: $detail) { ReminderDetailView(reminder: $0) }
    }
}

struct FamilyView: View {
    @EnvironmentObject private var store: AppStore
    @State private var addParent = false
    @State private var addChild = false
    @State private var deletion: DeletionTarget?
    var body: some View {
        List {
            Section {
                Label("Your family, together", systemImage: "person.2.fill").font(.title3.bold()).foregroundStyle(Theme.purple)
                Text("Start with a parent, then add your child. Each child gets their own sample plan.")
                    .foregroundStyle(.secondary)
            }
            Section("Parent") {
                if !store.parents.isEmpty {
                    Picker("Current parent", selection: Binding(get: { store.parentID }, set: { store.chooseParent($0) })) {
                        ForEach(store.parents) { parent in Text(parent.name).tag(parent.id) }
                    }.disabled(store.saving || store.loading)
                    Button(role: .destructive) {
                        deletion = DeletionTarget(kind: .parent, identifier: store.parentID, name: store.parentName)
                    } label: { Label("Delete parent and all their children", systemImage: "trash") }
                    .disabled(!store.connected || store.loading || store.saving)
                }
                Button { addParent = true } label: { Label("Add a parent", systemImage: "person.badge.plus") }
                    .disabled(!store.connected || store.loading || store.saving)
            }
            Section("Children") {
                ForEach(store.familyChildren) { child in
                    Button { store.chooseChild(child.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(child.name).font(.headline)
                                Text("Born \(LocalDate.display(child.dateOfBirth))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if child.id == store.childID { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green) }
                        }.padding(.vertical, 4).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(store.loading || store.saving)
                    Button(role: .destructive) {
                        deletion = DeletionTarget(kind: .child, identifier: child.id, name: child.name)
                    } label: { Label("Delete \(child.name)’s profile", systemImage: "trash") }
                    .disabled(!store.connected || store.loading || store.saving)
                }
                Button { addChild = true } label: { Label("Add a child", systemImage: "plus.circle") }
                    .disabled(store.parentID.isEmpty || !store.connected || store.loading || store.saving)
            }
            Section { CourseworkNotice() }
        }
        .refreshable { await store.reload() }
        .sheet(isPresented: $addParent) { FamilyEntryView(kind: .parent, parentID: store.parentID) }
        .sheet(isPresented: $addChild) { FamilyEntryView(kind: .child, parentID: store.parentID) }
        .sheet(item: $deletion) { DeleteConfirmationView(target: $0) }
    }
}

struct FamilyEntryView: View {
    enum Kind { case parent, child }
    let kind: Kind
    let parentID: String
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var birth = Date()
    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(kind == .parent ? "Parent's name" : "Child's name", text: $name)
                    if kind == .child { DatePicker("Date of birth", selection: $birth, in: ...Date(), displayedComponents: .date) }
                } footer: { Text("Use fictional details for the coursework demo. Names can contain up to 100 characters.") }
                Section {
                    Button(store.saving ? "Saving…" : kind == .parent ? "Add parent" : "Add child") {
                        Task {
                            let body = kind == .parent ? ["name": cleanName] : ["name": cleanName, "date_of_birth": LocalDate.day(birth), "parent_id": parentID]
                            if await store.save(kind == .parent ? "parents" : "children", body: body,
                                                message: kind == .parent ? "Parent added. You can now add a child." : "Child added. Their sample plan and reminders are ready.") { dismiss() }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cleanName.isEmpty || cleanName.count > 100 || store.saving || store.loading || !store.connected)
                }
                FeedbackView()
            }
            .formStyle(.grouped)
            .navigationTitle(kind == .parent ? "Add a parent" : "Add a child")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(store.saving) } }
        }
        .frame(idealWidth: 480, idealHeight: 440)
        .interactiveDismissDisabled(store.saving)
    }
}

struct DoseDetailView: View {
    let dose: Dose
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode = "record"
    @State private var given = Date()
    @State private var planned = Date()
    @State private var provider = ""
    @State private var confirmRecord = false
    private var birth: Date { LocalDate.date(store.child?.dateOfBirth ?? "") ?? Date.distantPast }
    private var vaccine: Vaccine? { store.vaccines.first { $0.id == dose.vaccineId } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(dose.vaccineName, systemImage: dose.completed ? "checkmark.seal.fill" : "syringe")
                        .font(.title2.bold()).foregroundStyle(Theme.purple)
                    LabeledContent("For", value: store.child?.name ?? "Your child")
                    LabeledContent("Dose", value: "\(dose.doseNumber)")
                    LabeledContent("Planned date", value: LocalDate.display(dose.scheduledDate))
                    if let diseases = vaccine?.diseases, !diseases.isEmpty {
                        LabeledContent("Listed protection", value: diseases.joined(separator: ", "))
                    }
                }
                if dose.completed {
                    Section {
                        Label("This dose has been recorded", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.green)
                        Text("You can review its date and provider in History.")
                    }
                } else {
                    Section {
                        Picker("Action", selection: $mode) {
                            Text("Record vaccination").tag("record")
                            Text("Edit planned date").tag("plan")
                        }.pickerStyle(.segmented)
                        if mode == "record" {
                            DatePicker("Given on", selection: $given, in: birth...Date(), displayedComponents: .date)
                        } else {
                            DatePicker("Planned date", selection: $planned, in: birth..., displayedComponents: .date)
                        }
                        TextField("Provider / clinic (optional)", text: $provider)
                    } footer: {
                        Text(mode == "record" ? "Only record a vaccination that has already been given. Recording also completes the matching reminder." : "Changing the planned date also moves its reminder date while keeping the reminder time. This does not book an appointment.")
                    }
                    Section {
                        Button(store.saving ? "Saving…" : mode == "record" ? "Save vaccination record" : "Save planned date") {
                            if mode == "record" { confirmRecord = true } else { Task { await save() } }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.saving || store.loading || !store.connected || provider.trimmingCharacters(in: .whitespacesAndNewlines).count > 50)
                        Text("Provider name: up to 50 characters.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                FeedbackView()
                Section { CourseworkNotice() }
            }
            .formStyle(.grouped)
            .navigationTitle("Dose details")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.disabled(store.saving) } }
            .onAppear {
                planned = LocalDate.date(dose.scheduledDate) ?? Date()
                given = min(max(planned, birth), Date())
                provider = dose.provider ?? ""
            }
            .confirmationDialog("Record \(dose.vaccineName), dose \(dose.doseNumber)?", isPresented: $confirmRecord, titleVisibility: .visible) {
                Button("Yes, this dose was given") { Task { await save() } }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Given on \(LocalDate.display(LocalDate.day(given))). This completes its schedule and reminder.") }
        }
        .frame(idealWidth: 540, idealHeight: 660)
        .interactiveDismissDisabled(store.saving)
    }

    private func save() async {
        let clinic = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        var body: [String: Any] = ["provider": clinic.isEmpty ? NSNull() : clinic as Any]
        let path: String
        if mode == "record" {
            path = "records"
            body["child_id"] = dose.childId
            body["vaccine_id"] = dose.vaccineId
            body["dose_number"] = dose.doseNumber
            body["vaccination_date"] = LocalDate.day(given) + "T12:00:00"
        } else {
            path = "schedules/\(dose.id)"
            body["scheduled_date"] = LocalDate.day(planned)
            body["status"] = dose.status
        }
        if await store.save(path, method: mode == "record" ? "POST" : "PATCH", body: body,
                            message: mode == "record" ? "Vaccination recorded. The matching reminder is completed." : "Planned date updated.") { dismiss() }
    }
}

struct ReminderDetailView: View {
    let reminder: Reminder
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(reminder.vaccineName).font(.title2.bold())
                    LabeledContent("Dose", value: "\(reminder.doseNumber)")
                    LabeledContent("Status", value: reminder.completed ? "Completed" : "Pending")
                    if reminder.completed {
                        Text("This reminder is completed because the dose is recorded.").foregroundStyle(Theme.green)
                    } else {
                        DatePicker("Remind me on", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        Button(store.saving ? "Saving…" : "Save reminder") {
                            Task {
                                if await store.save("reminders/\(reminder.id)", method: "PATCH",
                                                    body: ["reminder_date": LocalDate.timestamp(date)], message: "Reminder updated.") { dismiss() }
                            }
                        }.buttonStyle(.borderedProminent).disabled(store.saving || store.loading || !store.connected)
                    }
                } footer: { Text("Saved in the demo database. This does not create an iPhone notification or book an appointment. Dates use the calendar time you enter, without timezone conversion.") }
                FeedbackView()
            }
            .formStyle(.grouped)
            .navigationTitle("Reminder")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.disabled(store.saving) } }
            .onAppear { date = LocalDate.date(reminder.reminderDate) ?? Date() }
        }
        .frame(idealWidth: 500, idealHeight: 420)
        .interactiveDismissDisabled(store.saving)
    }
}

struct ServerSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var checking = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("http://192.168.1.10:8000", text: $address)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                    Button(checking ? "Connecting…" : "Connect and load family") {
                        checking = true
                        Task {
                            let success = await store.connect(address)
                            checking = false
                            if success { dismiss() }
                        }
                    }.buttonStyle(.borderedProminent).disabled(checking || address.isEmpty)
                } header: {
                    Text("Local Python API")
                } footer: {
                    Text("On this Mac, use http://127.0.0.1:8000. On iPhone, use the Mac's current Wi-Fi address instead of localhost. Keep the Python server running and both devices on the same Wi-Fi. Allow Local Network access when asked.")
                }
                Section("Demo privacy") {
                    Text("Only the API address and your selected family are stored on this device. Family details and records live in the local demo database. There is no login or public hosting. Use fictional details on a trusted network.")
                    Text("The app never receives PostgreSQL passwords. It cannot work offline, and it does not send push notifications.")
                }
                FeedbackView()
            }
            .formStyle(.grouped)
            .navigationTitle("Server settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.disabled(checking) } }
            .onAppear { address = store.address }
        }
        .frame(idealWidth: 520, idealHeight: 540)
        .interactiveDismissDisabled(checking)
    }
}


struct DeleteConfirmationView: View {
    let target: DeletionTarget
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Delete \(target.name)?").font(.headline)
                    Text(target.explanation)
                    Text("This cannot be undone after deletion.").foregroundStyle(.secondary)
                }
                Section {
                    Button(role: .destructive) {
                        Task {
                            if await store.delete(target) { dismiss() }
                        }
                    } label: {
                        Label(store.saving ? "Deleting…" : "Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.saving || store.loading || !store.connected)
                }
                FeedbackView()
            }
            .formStyle(.grouped)
            .navigationTitle("Confirm deletion")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(store.saving)
                }
            }
        }
        .frame(idealWidth: 480, idealHeight: 400)
        .interactiveDismissDisabled(store.saving)
    }
}
