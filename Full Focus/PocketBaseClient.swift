import Foundation
import UIKit

enum PocketBaseError: Error {
    case notAuthenticated
    case invalidResponse
    case serverUnreachable
}

/// Comunicazione con l'istanza PocketBase che gira sul Mac di casa.
/// Ogni "kind" (es. "studyEntries") viene salvato come un unico record
/// in `backups`, con dentro l'intero array in JSON — non un record per
/// ogni singola voce. Semplice da ragionare: ad ogni salvataggio
/// sovrascriviamo l'istantanea completa di quel tipo di dato.
actor PocketBaseClient {
    static let shared = PocketBaseClient()
    
    // MARK: - Cancellazione

        /// Cancella TUTTI i backup (ogni "kind") e tutte le foto associate
        /// all'utente corrente su PocketBase. Da chiamare quando l'utente
        /// elimina l'account: altrimenti i suoi dati resterebbero orfani
        /// sul Mac anche dopo la cancellazione in locale.
        func eraseAllBackupData() async {
            guard let userId else { return }

            // Cancella tutti i record "backups" dell'utente (uno per ogni kind)
            let backupsFilter = "user = \"\(userId)\""
            if let encoded = backupsFilter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let listURL = URL(string: "\(baseURL)/api/collections/backups/records?filter=\(encoded)&perPage=500") {
                if let listRequest = try? authorizedRequest(url: listURL, method: "GET"),
                   let (data, _) = try? await URLSession.shared.data(for: listRequest) {
                    struct ListResponse: Decodable {
                        struct Item: Decodable { let id: String }
                        let items: [Item]
                    }
                    if let decoded = try? JSONDecoder().decode(ListResponse.self, from: data) {
                        for item in decoded.items {
                            if let url = URL(string: "\(baseURL)/api/collections/backups/records/\(item.id)"),
                               let request = try? authorizedRequest(url: url, method: "DELETE") {
                                _ = try? await URLSession.shared.data(for: request)
                            }
                        }
                    }
                }
            }

            // Cancella tutte le foto dell'utente
            let photosFilter = "user = \"\(userId)\""
            if let encoded = photosFilter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let listURL = URL(string: "\(baseURL)/api/collections/photos/records?filter=\(encoded)&perPage=500") {
                if let listRequest = try? authorizedRequest(url: listURL, method: "GET"),
                   let (data, _) = try? await URLSession.shared.data(for: listRequest) {
                    struct ListResponse: Decodable {
                        struct Item: Decodable { let id: String }
                        let items: [Item]
                    }
                    if let decoded = try? JSONDecoder().decode(ListResponse.self, from: data) {
                        for item in decoded.items {
                            if let url = URL(string: "\(baseURL)/api/collections/photos/records/\(item.id)"),
                               let request = try? authorizedRequest(url: url, method: "DELETE") {
                                _ = try? await URLSession.shared.data(for: request)
                            }
                        }
                    }
                }
            }
        }

    // MARK: - Configurazione

    /// Sostituisci con l'hostname Bonjour scelto al passo 1 del setup.
    private let baseURL = "http://192.168.178.94:8090"

    // MARK: - Stato di sessione (persistito in Keychain)

    private var authToken: String?
    private var userId: String?
    private var savedEmail: String?
    private var savedPassword: String?

    private init() {
        authToken = KeychainHelper.read(key: "pb_token")
        userId = KeychainHelper.read(key: "pb_user_id")
        savedEmail = KeychainHelper.read(key: "pb_email")
        savedPassword = KeychainHelper.read(key: "pb_password")
    }

    var isAuthenticated: Bool { authToken != nil && userId != nil }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/collections/users/auth-with-password") else {
            throw PocketBaseError.invalidResponse
        }
        var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 6
                request.httpBody = try JSONEncoder().encode(["identity": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PocketBaseError.invalidResponse
        }

        struct AuthResponse: Decodable {
            struct Record: Decodable { let id: String }
            let token: String
            let record: Record
        }
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)

        authToken = decoded.token
        userId = decoded.record.id
        savedEmail = email
        savedPassword = password

        KeychainHelper.save(key: "pb_token", value: decoded.token)
        KeychainHelper.save(key: "pb_user_id", value: decoded.record.id)
        KeychainHelper.save(key: "pb_email", value: email)
        KeychainHelper.save(key: "pb_password", value: password)
    }

    /// Da chiamare all'avvio dell'app: se abbiamo già un token valido non fa
    /// nulla; altrimenti prova un login silenzioso con le credenziali salvate
    /// (utile proprio nel caso di reinstallazione, dato che il Keychain resta).
    func restoreSessionIfPossible() async {
        if isAuthenticated { return }
        guard let email = savedEmail, let password = savedPassword else { return }
        try? await login(email: email, password: password)
    }

    func logout() {
        authToken = nil
        userId = nil
        KeychainHelper.delete(key: "pb_token")
        KeychainHelper.delete(key: "pb_user_id")
    }

    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
            guard let token = authToken else { throw PocketBaseError.notAuthenticated }
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue(token, forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 6
            return request
        }

    // MARK: - Backup / restore di uno "snapshot" JSON

    /// Trova l'id del record `backups` esistente per (utente corrente, kind),
    /// se c'è già — serve per capire se fare POST (crea) o PATCH (aggiorna).
    private func existingBackupRecordId(kind: String) async throws -> String? {
        guard let userId else { throw PocketBaseError.notAuthenticated }
        let filter = "kind = \"\(kind)\" && user = \"\(userId)\""
        guard let encoded = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/collections/backups/records?filter=\(encoded)")
        else { throw PocketBaseError.invalidResponse }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        struct ListResponse: Decodable {
            struct Item: Decodable { let id: String }
            let items: [Item]
        }
        let decoded = try? JSONDecoder().decode(ListResponse.self, from: data)
        return decoded?.items.first?.id
    }

    /// Sovrascrive su PocketBase l'intero snapshot per un dato "kind"
    /// (es. "studyEntries") con l'array passato. Va richiamata ogni volta
    /// che salvi qualcosa in locale — passale sempre l'elenco COMPLETO
    /// aggiornato, non solo la voce nuova.
    func pushBackup<T: Encodable>(kind: String, payload: [T]) async throws {
        guard let userId else { throw PocketBaseError.notAuthenticated }
        let payloadData = try JSONEncoder().encode(payload)
        let payloadJSON = try JSONSerialization.jsonObject(with: payloadData)

        let body: [String: Any] = ["kind": kind, "user": userId, "payload": payloadJSON]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        if let existingId = try await existingBackupRecordId(kind: kind) {
            guard let url = URL(string: "\(baseURL)/api/collections/backups/records/\(existingId)") else {
                throw PocketBaseError.invalidResponse
            }
            var request = try authorizedRequest(url: url, method: "PATCH")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
            _ = try await URLSession.shared.data(for: request)
        } else {
            guard let url = URL(string: "\(baseURL)/api/collections/backups/records") else {
                throw PocketBaseError.invalidResponse
            }
            var request = try authorizedRequest(url: url, method: "POST")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
            _ = try await URLSession.shared.data(for: request)
        }
    }

    /// Scarica l'ultimo snapshot salvato per un "kind". Restituisce `nil`
    /// se non esiste ancora nessun backup di quel tipo per l'utente.
    func pullBackup<Payload: Decodable>(kind: String, as type: Payload.Type) async throws -> [Payload]? {
        guard let userId else { throw PocketBaseError.notAuthenticated }
        let filter = "kind = \"\(kind)\" && user = \"\(userId)\""
        guard let encoded = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/collections/backups/records?filter=\(encoded)")
        else { throw PocketBaseError.invalidResponse }

        let request = try authorizedRequest(url: url, method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(BackupListResponse<Payload>.self, from: data)
        return decoded.items.first?.payload
    }
    
    private struct BackupListResponse<Payload: Decodable>: Decodable {
        struct Item: Decodable { let payload: [Payload] }
        let items: [Item]
    }

    // MARK: - Foto

    func uploadPhoto(image: UIImage, filename: String) async throws {
        guard let userId, let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw PocketBaseError.notAuthenticated
        }
        guard let url = URL(string: "\(baseURL)/api/collections/photos/records") else {
            throw PocketBaseError.invalidResponse
        }
        var request = try authorizedRequest(url: url, method: "POST")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func addField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        addField("filename", filename)
        addField("user", userId)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        _ = try await URLSession.shared.data(for: request)
    }

    /// Scarica tutte le foto dell'utente (usato in fase di ripristino).
    /// Restituisce coppie (filename, UIImage).
    func downloadAllPhotos() async throws -> [(filename: String, image: UIImage)] {
        guard let userId else { throw PocketBaseError.notAuthenticated }
        let filter = "user = \"\(userId)\""
        guard let encoded = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let listURL = URL(string: "\(baseURL)/api/collections/photos/records?filter=\(encoded)&perPage=500")
        else { throw PocketBaseError.invalidResponse }

        let listRequest = try authorizedRequest(url: listURL, method: "GET")
        let (listData, _) = try await URLSession.shared.data(for: listRequest)

        struct ListResponse: Decodable {
            struct Item: Decodable { let id: String; let filename: String; let image: String }
            let items: [Item]
        }
        let decoded = try JSONDecoder().decode(ListResponse.self, from: listData)

        var results: [(String, UIImage)] = []
        for item in decoded.items {
            guard let fileURL = URL(string: "\(baseURL)/api/files/photos/\(item.id)/\(item.image)") else { continue }
            if let (data, _) = try? await URLSession.shared.data(from: fileURL), let image = UIImage(data: data) {
                results.append((item.filename, image))
            }
        }
        return results
    }
}
