import SwiftUI
import SwiftData

struct AddFriendView: View {
    let myProfile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingFriends: [Friend]

    @State private var code: String = ""
    @State private var errorMessage: String?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                Form {
                    Section {
                        Text("Your code")
                            .foregroundStyle(Theme.textSecondary)
                        HStack {
                            Text(myProfile.friendCode)
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = myProfile.friendCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)

                    Section("Send a friend request") {
                        TextField("Friend code (ex. MXQ-4185)", text: $code)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.textPrimary)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            addFriend()
                        } label: {
                            if isSearching {
                                ProgressView()
                            } else {
                                Text("Send request")
                            }
                        }
                        .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                        .tint(.orange)
                    }
                    .listRowBackground(Theme.card)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
        }
    }

    private func addFriend() {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed != myProfile.friendCode else {
            errorMessage = "You can't add yourself!"
            return
        }
        guard !existingFriends.contains(where: { $0.friendCode == trimmed }) else {
            errorMessage = "You already have this friend!"
            return
        }

        errorMessage = nil
        isSearching = true

        Task {
            do {
                let found = try await FriendLookupService.lookupFriend(byCode: trimmed)
                guard found != nil else {
                    await MainActor.run {
                        errorMessage = "This friend code does not exist"
                        isSearching = false
                    }
                    return
                }

                try await FriendLookupService.sendFriendRequest(
                    fromCode: myProfile.friendCode,
                    fromUsername: myProfile.username,
                    toCode: trimmed
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Server error, sorry!"
                    isSearching = false
                }
            }
        }
    }
}
