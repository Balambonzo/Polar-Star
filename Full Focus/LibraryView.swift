import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.sortOrder) private var books: [Book]
    @State private var selectedBook: Book?
    @State private var showActions = false

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                if books.isEmpty {
                    ContentUnavailableView(
                        "The bookshelf is empty",
                        systemImage: "book.closed",
                        description: Text("Scan the book's barcode from Today to start reading!")
                    )
                } else {
                    List {
                        ForEach(books) { book in
                            bookRow(book)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedBook = book
                                    showActions = true
                                }
                                .swipeActions(edge: .leading) {
                                    Button(role: .destructive) {
                                        delete(book)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Bookshelf")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog(selectedBook?.title ?? "", isPresented: $showActions, titleVisibility: .visible) {
                if let book = selectedBook, !book.isCompleted {
                    Button("Mark as completed") {
                        markCompleted(book)
                    }
                }
                if let book = selectedBook {
                    Button("Move on top") {
                        moveToTop(book)
                    }
                }
                Button("Exit", role: .cancel) {}
            }
        }
    }

    private func bookRow(_ book: Book) -> some View {
        HStack(spacing: 14) {
            bookCoverImage(book)
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                ProgressView(value: progressFraction(book))
                    .tint(book.isCompleted ? .green : .orange)
                Text(book.isCompleted ? "Completed" : "\(Int(progressFraction(book) * 100))%")
                    .font(.caption2)
                    .foregroundStyle(book.isCompleted ? .green : Theme.textTertiary)
            }
        }
        .padding(12)
        .glassCard(padding: 0)
    }

    private func bookCoverImage(_ book: Book) -> some View {
            Group {
                if let urlString = book.coverURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ShimmerPlaceholder()
                    }
                } else {
                    ShimmerPlaceholder()
                }
            }
        }

    private func progressFraction(_ book: Book) -> Double {
        guard book.totalPages > 0 else { return book.isCompleted ? 1 : 0 }
        return min(1, Double(book.currentPage) / Double(book.totalPages))
    }

    private func delete(_ book: Book) {
        modelContext.delete(book)
        try? modelContext.save()
    }

    private func markCompleted(_ book: Book) {
        book.isCompleted = true
        book.completedAt = .now
        try? modelContext.save()
    }

    private func moveToTop(_ book: Book) {
        let minOrder = books.map(\.sortOrder).min() ?? 0
        book.sortOrder = minOrder - 1
        try? modelContext.save()
    }
}
