import SwiftUI
import SwiftData

struct ReadingSessionSetupView: View {
    let onStart: (Book, Int) -> Void
    let onNewBook: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \Book.sortOrder) private var books: [Book]

    @State private var selectedBook: Book?
    @State private var selectedMinutes = 15

    private var inProgressBooks: [Book] {
        books.filter { !$0.isCompleted }
    }

    private var minuteOptions: [Int] {
        let minimum = profiles.first?.dailyReadingMinimumMinutes ?? 10
        return Array(stride(from: minimum, through: 180, by: 5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("What do you want to read today?")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.top, 20)

                        if inProgressBooks.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(inProgressBooks) { book in
                                    bookOption(book)
                                }
                            }
                            .padding(.horizontal, 20)

                            Button {
                                onNewBook()
                            } label: {
                                Label("New book", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                        }

                        if let selectedBook {
                            VStack(spacing: 12) {
                                Text("How much today?")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                                Picker("Minutes", selection: $selectedMinutes) {
                                    ForEach(minuteOptions, id: \.self) { m in
                                        Text("\(m) min").tag(m)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 110)

                                Button {
                                    onStart(selectedBook, selectedMinutes)
                                    Haptics.action()
                                } label: {
                                    Label("Start reading", systemImage: "book.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .foregroundStyle(.white)
                                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 30)
                    }
                }
                .transaction {
                    $0.scrollContentOffsetAdjustmentBehavior = .disabled
                }
            }
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
            .onAppear {
                selectedMinutes = profiles.first?.dailyReadingMinimumMinutes ?? 15
                if selectedBook == nil { selectedBook = inProgressBooks.first }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("You have no books for the moment")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Button {
                onNewBook()
            } label: {
                Label("Scan your first book!", systemImage: "barcode.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }

    private func bookOption(_ book: Book) -> some View {
        let isSelected = selectedBook?.id == book.id
        return Button {
            selectedBook = book
        } label: {
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
                    Text("Page \(book.currentPage) of \(book.totalPages)")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : Theme.textTertiary)
            }
            .padding(12)
            .background(isSelected ? Color.orange.opacity(0.12) : Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : Theme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
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
}
