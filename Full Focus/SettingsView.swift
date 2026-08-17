//
//  SettingsView.swift
//  Full Focus
//
//  Created by Alberto Toscano on 09/08/2026.
//


import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @Query private var readingSessions: [ReadingSession]
    @Query private var customEntries: [CustomActivityEntry]
    @Query private var trainingEntries: [TrainingEntry]
    @Query private var books: [Book]
    @Query private var friends: [Friend]

    @AppStorage(NotificationScheduler.notificationsEnabledKey) private var notificationsEnabled = true
    @AppStorage("starfieldEnabled") private var starfieldEnabled = true

    @State private var reminderTime = Date()
    @State private var showResetOnboardingConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var showBackupLogin = false
    @State private var isBackupConnected = false

    private var selectedActivities: [String] {
            profiles.first?.selectedActivities ?? []
        }

        private var todayDone: Bool {
            let aggregation = ActivityAggregator.aggregate(
                selectedActivities: selectedActivities,
                studyEntries: entries,
                trainingEntries: trainingEntries,
                readingSessions: readingSessions,
                customEntries: customEntries
            )
            return StreakCalculator.stats(completedDates: aggregation.completedDates).todayDone
        }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                Form {
                    Section("Notification") {
                        Toggle("Memorandum activated!", isOn: $notificationsEnabled)
                            .tint(.orange)
                            .onChange(of: notificationsEnabled) { _, _ in
                                NotificationScheduler.shared.refreshSchedule(todayDone: todayDone)
                            }

                        if notificationsEnabled {
                            DatePicker("When do you want the notification?", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .foregroundStyle(Theme.textPrimary)
                                .onChange(of: reminderTime) { _, newValue in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    UserDefaults.standard.set(comps.hour ?? 19, forKey: NotificationScheduler.mainReminderHourKey)
                                    UserDefaults.standard.set(comps.minute ?? 0, forKey: NotificationScheduler.mainReminderMinuteKey)
                                    NotificationScheduler.shared.refreshSchedule(todayDone: todayDone)
                                }
                        }
                    }
                    .listRowBackground(Theme.card)

                    Section("Layout") {
                        Toggle("Starfield background", isOn: $starfieldEnabled)
                        Text("New themes will arrive soon!")
                            .tint(.orange)
                    }
                    .listRowBackground(Theme.card)

                    Section("Datas") {
                        if let url = exportJSONURL {
                            ShareLink(item: url) {
                                Label("Export datas", systemImage: "square.and.arrow.up")
                            }
                            .foregroundStyle(Theme.textPrimary)
                        }

                        Button(role: .destructive) {
                            showResetOnboardingConfirm = true
                        } label: {
                            Label("Go back to the intro", systemImage: "arrow.counterclockwise")
                        }
                        Button(role: .destructive) {
                                                    showDeleteAccountConfirm = true
                                                } label: {
                                                    if isDeletingAccount {
                                                        ProgressView()
                                                    } else {
                                                        Label("Delete account", systemImage: "trash")
                                                            .foregroundStyle(.red)
                                                    }
                                                }
                                                .disabled(isDeletingAccount)
                    }
                    .listRowBackground(Theme.card)
                    
                    Section("Backup") {
                                            Button {
                                                showBackupLogin = true
                                            } label: {
                                                Label(isBackupConnected ? "Modifica backup" : "Collega backup", systemImage: "externaldrive.badge.icloud")
                                            }
                                            .foregroundStyle(Theme.textPrimary)

                                            HStack(spacing: 6) {
                                                Image(systemName: isBackupConnected ? "checkmark.circle.fill" : "xmark.circle")
                                                    .foregroundStyle(isBackupConnected ? .green : Theme.textTertiary)
                                                Text(isBackupConnected ? "Backup collegato" : "Backup non collegato")
                                                    .font(.footnote)
                                                    .foregroundStyle(Theme.textSecondary)
                                            }
                                        }
                                        .listRowBackground(Theme.card)

                    Section {
                                            NavigationLink {
                                                PrivacyInfoView()
                                            } label: {
                                                Label("Privacy", systemImage: "lock.fill")
                                            }
                                            NavigationLink {
                                                TermsView()
                                            } label: {
                                                Label("Terms and conditions", systemImage: "doc.text.fill")
                                            }
                                        }
                                        .listRowBackground(Theme.card)

                    Section {
                        VStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text("PolarStar")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Version \(appVersion)")
                                .font(.caption)
                                .foregroundStyle(Theme.textTertiary)
                            Text("Created by Alberto Toscano")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.top, 4)
                            Text("Built with SwiftUI, SwiftData and Firebase")
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
            .onAppear {
                            let hour = UserDefaults.standard.object(forKey: NotificationScheduler.mainReminderHourKey) as? Int ?? 19
                            let minute = UserDefaults.standard.object(forKey: NotificationScheduler.mainReminderMinuteKey) as? Int ?? 0
                            reminderTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                            Task { isBackupConnected = await PocketBaseClient.shared.isAuthenticated }
                        }
            .alert("Want to go back to the intro?", isPresented: $showResetOnboardingConfirm) {
                Button("Exit", role: .cancel) {}
                Button("Go") {
                    if let profile = profiles.first {
                        profile.hasCompletedOnboarding = false
                        try? modelContext.save()
                    }
                    dismiss()
                }
            } message: {
                Text("Your datas won't be deleted")
            }
            .alert("Are you sure?", isPresented: $showDeleteAccountConfirm) {
                            Button("Exit", role: .cancel) {}
                            Button("Delete", role: .destructive) {
                                deleteAccount()
                            }
            } message: {
                                        Text("Tutti i tuoi dati — foto, streak, libri, amici, profilo pubblico — verranno cancellati per sempre. Questa azione non si può annullare.")
                                        Text("All your datas (photos, streak, books, friends, public profile) which will be lost forever. There is no going back.")
                                    }
            .sheet(isPresented: $showBackupLogin, onDismiss: {
                                Task { isBackupConnected = await PocketBaseClient.shared.isAuthenticated }
                            }) {
                                BackupLoginView()
                            }
                    }
                }

    // MARK: - Esportazione

    private struct ExportPayload: Codable {
        struct Entry: Codable {
            let date: String
            let studyMinutes: Int
        }
        let exportedAt: String
        let currentStreak: Int
        let bestStreak: Int
        let totalSessions: Int
        let entries: [Entry]
    }

    private var exportJSONURL: URL? {
        let formatter = ISO8601DateFormatter()
        let aggregation = ActivityAggregator.aggregate(
                    selectedActivities: selectedActivities,
                    studyEntries: entries,
                    trainingEntries: trainingEntries,
                    readingSessions: readingSessions,
                    customEntries: customEntries
                )
                let stats = StreakCalculator.stats(completedDates: aggregation.completedDates)
        let payload = ExportPayload(
            exportedAt: formatter.string(from: Date()),
            currentStreak: stats.currentStreak,
            bestStreak: stats.bestStreak,
            totalSessions: entries.count,
            entries: entries.map { .init(date: formatter.string(from: $0.date), studyMinutes: $0.studyDurationMinutes) }
        )
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fullfocus-export.json")
        try? data.write(to: url)
        return url
    }
    
    private func deleteAccount() {
                isDeletingAccount = true
                let codeToDelete = profiles.first?.friendCode

                // 1. Cancella subito tutto in locale — l'utente non deve mai
                // restare bloccato ad aspettare la rete per questa parte.
                for entry in entries { modelContext.delete(entry) }
                for entry in trainingEntries { modelContext.delete(entry) }
                for entry in readingSessions { modelContext.delete(entry) }
                for entry in customEntries { modelContext.delete(entry) }
                for book in books { modelContext.delete(book) }
                for friend in friends { modelContext.delete(friend) }
                if let profile = profiles.first { modelContext.delete(profile) }
                try? modelContext.save()

                UserDefaults.standard.removeObject(forKey: "studyTimerState_v2_study")
                UserDefaults.standard.removeObject(forKey: "studyTimerState_v2_training")
                UserDefaults.standard.removeObject(forKey: "studyTimerState_v2_reading")
                UserDefaults.standard.removeObject(forKey: "studyTimerState_v2_custom")

                isDeletingAccount = false
                dismiss()

                // 2. Pulizia remota "best effort", in background: se Firebase o
                // il Mac non sono raggiungibili, fallisce in silenzio — l'utente
                // ha già chiuso la schermata a questo punto, quindi non blocca.
                Task {
                    if let code = codeToDelete {
                        try? await FriendLookupService.deleteProfile(friendCode: code)
                    }
                    if await PocketBaseClient.shared.isAuthenticated {
                        await PocketBaseClient.shared.eraseAllBackupData()
                        await PocketBaseClient.shared.logout()
                    }
                }
            }
}



private struct PrivacyInfoView: View {
    var body: some View {
        ZStack {
            StarfieldBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What we save, and where")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)

                    privacyItem(
                        title: "On your device",
                        text: "All the photos you upload and your streak are saved only on your iPhone"
                    )
                    privacyItem(
                        title: "Public profile",
                        text: "To let you add friends, some datas (your username, your current streak, your best streak and your last photo) are published on a server (Firebase) and are visible to anyone who knows your invitation code."
                    )
                    privacyItem(
                        title: "No add-on, no tracking",
                        text: "PolarStar does not have any add-on or third-part tracking."
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func privacyItem(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
