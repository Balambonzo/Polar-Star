import SwiftUI
import SwiftData
import FirebaseFirestore

/// Il profilo di un amico: streak, record, e l'ultima foto che ha
/// caricato. Refresh manuale disponibile oltre all'aggiornamento
/// automatico via push.
struct FriendDetailView: View {
    let friend: Friend
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isRefreshing = false
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 96, height: 96)
                            if let path = friend.profileImagePath, let uiImage = ImageStore.load(path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        Text(friend.username)
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text("@\(friend.friendCode)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        
                        HStack(spacing: 12) {
                            statBlock(icon: "flame.fill", value: "\(friend.currentStreak)", label: "Streak")
                            statBlock(icon: "trophy.fill", value: "\(friend.bestStreak)", label: "Record")
                        }
                        .padding(.horizontal, 24)
                        
                        if let lastEntryDate = friend.lastEntryDate {
                            Text("Last picture: \(lastEntryDate.formatted(.relative(presentation: .named)))")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        if let path = friend.profileImagePath, let uiImage = ImageStore.load(path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                        }
                        
                        Button {
                            refresh()
                        } label: {
                            Label(isRefreshing ? "Updating..." : "Update now", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.orange)
                        }
                        .disabled(isRefreshing)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(friend.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
            .onAppear { listener = FriendLookupService.listenToFriend(code: friend.friendCode, onUpdate: apply) }
                        .onDisappear { listener?.remove() }
        }
    }
    
    private func statBlock(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.orange)
            Text(value).font(.title3.bold()).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    private func refresh() {
        isRefreshing = true
        Task {
            if let updated = try? await FriendLookupService.refreshFriend(byCode: friend.friendCode) {
                apply(updated)
            }
            isRefreshing = false
        }
    }
    
    private func apply(_ updated: FriendLookupService.FriendProfile) {
        friend.username = updated.username
        friend.currentStreak = updated.currentStreak
        friend.bestStreak = updated.bestStreak
        friend.lastEntryDate = updated.lastEntryDate
        if let photo = updated.latestPhoto, let fileName = ImageStore.save(photo) {
            friend.profileImagePath = fileName
        }
        try? modelContext.save()
    }
}
