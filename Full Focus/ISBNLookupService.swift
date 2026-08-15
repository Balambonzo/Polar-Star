// ISBNLookupService.swift
import Foundation

enum ISBNLookupService {
    struct BookInfo {
        let title: String
        let author: String
        let totalPages: Int
        let coverURL: String?
    }
    /// Letta da Info.plist (chiave "GoogleBooksAPIKey"), a sua volta valorizzata
    /// dalla build setting GOOGLE_BOOKS_API_KEY definita in Config.xcconfig
    /// (file NON versionato, vedi Config.xcconfig.example). In questo modo la
    /// chiave reale non finisce mai nel repository git.
    private static let googleBooksAPIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String,
              !key.isEmpty else {
            assertionFailure("GoogleBooksAPIKey mancante: configura Config.xcconfig, vedi Config.xcconfig.example")
            return ""
        }
        return key
    }()

    static func lookup(isbn: String) async -> BookInfo? {
        if let result = await lookupOpenLibrary(isbn: isbn) {
            return result
        }
        return await lookupGoogleBooks(isbn: isbn)
    }

    private static func lookupOpenLibrary(isbn: String) async -> BookInfo? {
        guard let url = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data") else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let bookData = json["ISBN:\(isbn)"] as? [String: Any] else {
                return nil
            }

            let title = bookData["title"] as? String ?? "Unknown title"
            let authorsArray = bookData["authors"] as? [[String: Any]] ?? []
            let author = authorsArray.compactMap { $0["name"] as? String }.joined(separator: ", ")
            let pages = bookData["number_of_pages"] as? Int ?? 0
            let coverURL = "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"

            return BookInfo(
                title: title,
                author: author.isEmpty ? "Unknown author" : author,
                totalPages: pages,
                coverURL: coverURL
            )
        } catch {
            print("Open Library error:", error)
            return nil
        }
    }

    private static func lookupGoogleBooks(isbn: String) async -> BookInfo? {
        guard !googleBooksAPIKey.isEmpty else { return nil }
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)&key=\(googleBooksAPIKey)") else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]],
                  let volumeInfo = items.first?["volumeInfo"] as? [String: Any] else {
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
