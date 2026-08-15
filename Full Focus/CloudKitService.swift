import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

/// Comunicazione con Firestore per il sistema amici: profilo pubblico
/// ricercabile per friend code, e richieste di amicizia con accettazione.
enum FriendLookupService {

    private static var db: Firestore { Firestore.firestore() }

    struct FriendProfile {
        let friendCode: String
        let username: String
        let currentStreak: Int
        let bestStreak: Int
        let lastEntryDate: Date?
        let latestPhoto: UIImage?
    }

    struct FriendRequest: Identifiable {
        let id: String          // ID documento: "\(from)_\(to)"
        let from: String
        let to: String
        let fromUsername: String
        let status: String      // "pending" | "accepted" | "declined"
    }

    // MARK: - Pubblicare il proprio profilo

    static func ensureSignedIn() async {
            if Auth.auth().currentUser != nil { return }
            await withCheckedContinuation { continuation in
                Auth.auth().signInAnonymously { _, error in
                    if let error {
                        print("Firebase anonymous sign-in error: \(error)")
                    }
                    continuation.resume()
                }
            }
        }
    
    static func publishMyProfile(
            friendCode: String,
            username: String,
            currentStreak: Int,
            bestStreak: Int,
            lastEntryDate: Date?,
            latestPhoto: UIImage?
        ) async throws {
            await ensureSignedIn()
            guard let uid = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "FriendLookupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Non autenticato"])
            }

        var data: [String: Any] = [
            "friendCode": friendCode,
            "username": username,
            "currentStreak": currentStreak,
            "bestStreak": bestStreak,
            "ownerUID": uid
        ]
        if let lastEntryDate {
            data["lastEntryDate"] = Timestamp(date: lastEntryDate)
        }
        if let latestPhoto, let jpeg = resizedJPEGData(latestPhoto) {
            data["latestPhotoBase64"] = jpeg.base64EncodedString()
        }

        try await db.collection("profiles").document(friendCode).setData(data, merge: true)
    }

    private static func resizedJPEGData(_ image: UIImage, maxDimension: CGFloat = 480, quality: CGFloat = 0.5) -> Data? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    // MARK: - Cercare un profilo pubblico

    static func lookupFriend(byCode code: String) async throws -> FriendProfile? {
        let snapshot = try await db.collection("profiles").document(code).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return friendProfile(from: data, fallbackCode: code)
    }

    static func refreshFriend(byCode code: String) async throws -> FriendProfile? {
        try await lookupFriend(byCode: code)
    }

    private static func friendProfile(from data: [String: Any], fallbackCode: String) -> FriendProfile {
        var photo: UIImage?
        if let base64String = data["latestPhotoBase64"] as? String,
           let imageData = Data(base64Encoded: base64String) {
            photo = UIImage(data: imageData)
        }
        let lastEntryDate = (data["lastEntryDate"] as? Timestamp)?.dateValue()
        return FriendProfile(
            friendCode: data["friendCode"] as? String ?? fallbackCode,
            username: data["username"] as? String ?? "Amico",
            currentStreak: data["currentStreak"] as? Int ?? 0,
            bestStreak: data["bestStreak"] as? Int ?? 0,
            lastEntryDate: lastEntryDate,
            latestPhoto: photo
        )
    }

    static func listenToFriend(code: String, onUpdate: @escaping (FriendProfile) -> Void) -> ListenerRegistration {
        db.collection("profiles").document(code).addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            let profile = friendProfile(from: data, fallbackCode: code)
            DispatchQueue.main.async { onUpdate(profile) }
        }
    }

    // MARK: - Richieste di amicizia

    static func sendFriendRequest(fromCode: String, fromUsername: String, toCode: String) async throws {
        let requestID = "\(fromCode)_\(toCode)"
        let data: [String: Any] = [
            "from": fromCode,
            "to": toCode,
            "fromUsername": fromUsername,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("friendRequests").document(requestID).setData(data, merge: true)
    }

    /// Richieste ricevute e ancora senza risposta.
    static func fetchIncomingRequests(myCode: String) async throws -> [FriendRequest] {
        let snapshot = try await db.collection("friendRequests")
            .whereField("to", isEqualTo: myCode)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        return snapshot.documents.map(requestFromDocument)
    }

    /// Richieste che ho inviato io e che sono state accettate.
    static func fetchAcceptedSentRequests(myCode: String) async throws -> [FriendRequest] {
        let snapshot = try await db.collection("friendRequests")
            .whereField("from", isEqualTo: myCode)
            .whereField("status", isEqualTo: "accepted")
            .getDocuments()
        return snapshot.documents.map(requestFromDocument)
    }

    static func respondToRequest(requestID: String, accept: Bool) async throws {
        try await db.collection("friendRequests").document(requestID)
            .setData(["status": accept ? "accepted" : "declined"], merge: true)
    }
    /// Cancella il profilo pubblico da Firestore — va chiamata quando
        /// l'utente elimina l'account, prima di cancellare i dati locali.
        static func deleteProfile(friendCode: String) async throws {
            try await db.collection("profiles").document(friendCode).delete()
        }

    private static func requestFromDocument(_ doc: QueryDocumentSnapshot) -> FriendRequest {
        let data = doc.data()
        return FriendRequest(
            id: doc.documentID,
            from: data["from"] as? String ?? "",
            to: data["to"] as? String ?? "",
            fromUsername: data["fromUsername"] as? String ?? "Amico",
            status: data["status"] as? String ?? "pending"
        )
    }
}
