import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.sortOrder) private var books: [Book]
    @Query private var readingSessions: [ReadingSession]

    @State private var selectedBook: Book?
    @State private var showActions = false

    private var inProgressBooks: [Book] {
        books.filter { !$0.isCompleted }
    }

    private var completedBooks: [Book] {
        books.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                if books.isEmpty {
                    ContentUnavailableView(
                        "There is nothing here...",
                        systemImage: "book.closed",
                        description: Text("Scan the barcode of a book from Today to start reading!")
                    )
                } else {
                    List {
                        Section {
                            statsHeader
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            dailyPagesChart
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            if !readingSessions.isEmpty {
                                sessionHistorySection
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }

                        if !inProgressBooks.isEmpty {
                            Section("In progress") {
                                ForEach(inProgressBooks) { book in
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
                                .onMove(perform: moveInProgressBooks)
                            }
                        }

                        if !completedBooks.isEmpty {
                            Section("Completed") {
                                ForEach(completedBooks) { book in
                                    bookRow(book)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .leading) {
                                            Button(role: .destructive) {
                                                delete(book)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                }
            }
            .navigationTitle("Reading")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog(selectedBook?.title ?? "", isPresented: $showActions, titleVisibility: .visible) {
                if let book = selectedBook, !book.isCompleted {
                    Button("Mark as completed") {
                        markCompleted(book)
                    }
                }
                if let book = selectedBook {
                    Button("Put on top") {
                        moveToTop(book)
                    }
                }
                Button("Exit", role: .cancel) {}
            }
        }
    }

    // MARK: - Statistiche

    private var statsHeader: some View {
        let stats = ReadingStatsCalculator.stats(sessions: readingSessions, books: books)
        let monthlyPages = ReadingStatsCalculator.monthlyPagesTotal(sessions: readingSessions)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(icon: "flame.fill", value: "\(stats.currentStreak)", label: "Reading streak")
            statTile(icon: "clock.fill", value: readingTimeText(stats.totalMinutes), label: "Total time")
            statTile(icon: "checkmark.seal.fill", value: "\(stats.booksCompleted)", label: "Completed books")
            statTile(icon: "doc.text.fill", value: "\(monthlyPages)", label: "Pages this month")
        }
    }

    private func readingTimeText(_ minutes: Int) -> String {
        String(format: "%.0f h", Double(minutes) / 60.0)
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.orange).font(.subheadline)
            Text(value).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var dailyPagesChart: some View {
        let data = ReadingStatsCalculator.recentDailyPages(sessions: readingSessions)
        let maxPages = max(data.map(\.pages).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Pages in the last 14 days")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data, id: \.date) { entry in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.pages > 0 ? Color.orange.opacity(0.75) : Theme.card)
                            .frame(height: max(4, CGFloat(entry.pages) / CGFloat(maxPages) * 60))
                        Text(dayLabel(entry.date))
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
        }
        .glassCard()
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var sessionHistorySection: some View {
        let recent = readingSessions.sorted { $0.date > $1.date }.prefix(20)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Session history")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 0) {
                ForEach(Array(recent)) { session in
                    sessionRow(session)
                    if session.id != recent.last?.id {
                        Divider().overlay(Theme.cardBorder)
                    }
                }
            }
            .glassCard(padding: 0)
        }
    }

    private func sessionRow(_ session: ReadingSession) -> some View {
        let pages = ReadingStatsCalculator.pagesRead(in: session, allSessions: readingSessions)
        let bookTitle = books.first(where: { $0.id == session.bookID })?.title ?? "Book"
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(session.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(pages) pag.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("\(session.minutesRead) min")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Righe libro

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
                HStack {
                    Text(book.isCompleted ? "Completed" : "\(Int(progressFraction(book) * 100))%")
                        .font(.caption2)
                        .foregroundStyle(book.isCompleted ? .green : Theme.textTertiary)
                    if !book.isCompleted, let pace = ReadingStatsCalculator.pace(for: book), pace > 0 {
                        Text("· ~\(String(format: "%.0f", pace)) pages per day")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
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

    // MARK: - Azioni

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

    private func moveInProgressBooks(from source: IndexSet, to destination: Int) {
        var reordered = inProgressBooks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, book) in reordered.enumerated() {
            book.sortOrder = index
        }
        try? modelContext.save()
    }
}
