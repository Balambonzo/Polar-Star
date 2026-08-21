////
////  ISBNLookupService 2.swift
////  Full Focus
////
////  Created by Alberto Toscano on 15/08/2026.
////
//
//
//// ISBNLookupService.swift
//import Foundation
//
//enum ISBNLookupService {
//    struct BookInfo {
//        let title: String
//        let author: String
//        let totalPages: Int
//        let coverURL: String?
//    }
//
//    // Chiave hardcoded per uso personale — se in futuro pubblichi l'app,
//    // rimettila su xcconfig/Info.plist per non finire su GitHub.
//    private static let googleBooksAPIKey = ""
//
//    static func lookup(isbn: String) async -> BookInfo? {
//        if let result = await lookupOpenLibrary(isbn: isbn) {
//            return result
//        }
//        return await lookupGoogleBooks(isbn: isbn)
//    }
//
//    private static func lookupOpenLibrary(isbn: String) async -> BookInfo? {
//        guard let url = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data") else { return nil }
//
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                  let bookData = json["ISBN:\(isbn)"] as? [String: Any] else {
//                return nil
//            }
//
//            let title = bookData["title"] as? String ?? "Unknown title"
//            let authorsArray = bookData["authors"] as? [[String: Any]] ?? []
//            let author = authorsArray.compactMap { $0["name"] as? String }.joined(separator: ", ")
//            let pages = bookData["number_of_pages"] as? Int ?? 0
//            let coverURL = "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"
//
//            return BookInfo(
//                title: title,
//                author: author.isEmpty ? "Unknown author" : author,
//                totalPages: pages,
//                coverURL: coverURL
//            )
//        } catch {
//            print("Open Library error:", error)
//            return nil
//        }
//    }
//
//    private static func lookupGoogleBooks(isbn: String) async -> BookInfo? {
//        guard !googleBooksAPIKey.isEmpty else { return nil }
//        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)&key=\(googleBooksAPIKey)") else { return nil }
//
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                  let items = json["items"] as? [[String: Any]],
//                  let volumeInfo = items.first?["volumeInfo"] as? [String: Any] else {
//                return nil
//            }
//
//            let title = volumeInfo["title"] as? String ?? "Unknown title"
//            let authors = (volumeInfo["authors"] as? [String])?.joined(separator: ", ") ?? "Unknow author"
//            let pages = volumeInfo["pageCount"] as? Int ?? 0
//            let coverURL = ((volumeInfo["imageLinks"] as? [String: Any])?["thumbnail"] as? String)?
//                .replacingOccurrences(of: "http://", with: "https://")
//
//            return BookInfo(title: title, author: authors, totalPages: pages, coverURL: coverURL)
//        } catch {
//            print("Google Books error:", error)
//            return nil
//        }
//    }
//}


// ISBNLookupService.swift
import Foundation

enum ISBNLookupService {
    struct BookInfo {
        let title: String
        let author: String
        let totalPages: Int
        let coverURL: String?
    }

    // Chiave hardcoded per uso personale — se in futuro pubblichi l'app,
    // rimettila su xcconfig/Info.plist per non finire su GitHub.
    private static let googleBooksAPIKey = ""

    static func lookup(isbn: String) async -> BookInfo? {
        return await lookupGoogleBooks(isbn: isbn)
    }

    private static func lookupGoogleBooks(isbn: String) async -> BookInfo? {
        guard !googleBooksAPIKey.isEmpty else {
            print("⚠️ API key vuota")
            return nil
        }
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)&key=\(googleBooksAPIKey)") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status code:", httpResponse.statusCode)
            }
            print("📦 Raw response:", String(data: data, encoding: .utf8) ?? "impossibile decodificare")

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]],
                  let volumeInfo = items.first?["volumeInfo"] as? [String: Any] else {
                print("⚠️ Parsing fallito o nessun risultato")
                return nil
            }

            let title = volumeInfo["title"] as? String ?? "Unknown title"
            let authors = (volumeInfo["authors"] as? [String])?.joined(separator: ", ") ?? "Unknow author"
            let pages = volumeInfo["pageCount"] as? Int ?? 0
            let coverURL = ((volumeInfo["imageLinks"] as? [String: Any])?["thumbnail"] as? String)?
                .replacingOccurrences(of: "http://", with: "https://")

            return BookInfo(title: title, author: authors, totalPages: pages, coverURL: coverURL)
        } catch {
            print("Google Books error:", error)
            return nil
        }
    }
}
