import SwiftUI
import SwiftData

/// Schermata da mostrare una tantum per collegare l'app al backup di casa.
/// Le credenziali, una volta inserite, restano salvate nel Keychain e
/// l'app farà login da sola alle volte successive (anche dopo reinstallazione).
struct BackupLoginView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @Query private var studyEntries: [StudyEntry]
    @Query private var trainingEntries: [TrainingEntry]
    @Query private var readingSessions: [ReadingSession]
    @Query private var customEntries: [CustomActivityEntry]

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                VStack(spacing: 16) {
                    Text("Collega il backup")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Usa l'account creato sul pannello del Mac.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.textPrimary)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.textPrimary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        connect()
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Connetti")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                .padding(24)
            }
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func connect() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await PocketBaseClient.shared.login(email: email, password: password)
                BackupSyncService.backupEverythingNow(
                    studyEntries: studyEntries,
                    trainingEntries: trainingEntries,
                    readingSessions: readingSessions,
                    customEntries: customEntries
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = "Non riesco a collegarmi. Controlla di essere sulla stessa rete Wi-Fi del Mac."
                    isLoading = false
                }
            }
        }
    }
}
