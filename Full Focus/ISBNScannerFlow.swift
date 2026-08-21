import SwiftUI
import VisionKit

struct ISBNScannerFlow: View {
    let onBookCreated: (Book) -> Void

    @State private var manualISBN = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pendingInfo: ISBNLookupService.BookInfo?
    @State private var pendingISBN = ""
    @State private var isAlreadyStarted = false
    @State private var startPageText = ""
    @Environment(\.dismiss) private var dismiss

    private var scannerSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if scannerSupported {
                    ISBNScannerView { code in
                        Task { await handleScan(code) }
                    }
                    .ignoresSafeArea()
                } else {
                    StarfieldBackground()
                }

                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if let pendingInfo {
                            confirmPanel(pendingInfo)
                        } else if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            Text("Or insert the ISBN manually")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            HStack {
                                TextField("ISBN (ex. 9788804668237)", text: $manualISBN)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(.white)
                                Button("Search") {
                                    Task { await handleScan(manualISBN) }
                                }
                                .foregroundStyle(.orange)
                                .disabled(manualISBN.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                    }
                    .padding()
                    .background(.black.opacity(0.6))
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Scan ISBN")
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

    @ViewBuilder
    private func confirmPanel(_ info: ISBNLookupService.BookInfo) -> some View {
        VStack(spacing: 12) {
            Text(info.title)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Picker("", selection: $isAlreadyStarted) {
                Text("New book").tag(false)
                Text("Already started").tag(true)
            }
            .pickerStyle(.segmented)

            if isAlreadyStarted {
                TextField("Page you're at", text: $startPageText)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }

            Button {
                confirmBook(info)
            } label: {
                Text("Confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isAlreadyStarted && Int(startPageText) == nil)
        }
    }

    private func handleScan(_ isbn: String) async {
        let cleaned = isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        guard let info = await ISBNLookupService.lookup(isbn: cleaned) else {
            isLoading = false
            errorMessage = "Book not found. Check the code and retry"
            return
        }

        isLoading = false
        pendingISBN = cleaned
        isAlreadyStarted = false
        startPageText = ""
        pendingInfo = info
    }

    private func confirmBook(_ info: ISBNLookupService.BookInfo) {
        let book = Book(
            isbn: pendingISBN,
            title: info.title,
            author: info.author,
            coverURL: info.coverURL,
            totalPages: info.totalPages > 0 ? info.totalPages : 200
        )

        if isAlreadyStarted, let page = Int(startPageText) {
            book.currentPage = book.totalPages > 0 ? min(page, book.totalPages) : page
        }

        onBookCreated(book)
        Haptics.success()
    }
}
