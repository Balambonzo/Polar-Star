import SwiftUI
import SwiftData

struct JollyActivityShelfView: View {
    @Query(sort: \CustomActivityEntry.date, order: .forward) private var entries: [CustomActivityEntry]
    @Query private var profiles: [UserProfile]

    @State private var selectedEntry: CustomActivityEntry?

    private let columnSpacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 14

    /// La foto più recente diventa la card "in evidenza" in cima — le altre
    /// finiscono nelle sezioni mensili qui sotto, senza duplicarla.
    private var latestEntry: CustomActivityEntry? {
        entries.max(by: { $0.date < $1.date })
    }

    private var groupedByMonth: [(month: Date, entries: [CustomActivityEntry])] {
        let calendar = Calendar.current
        let remaining = entries.filter { $0.id != latestEntry?.id }
        let grouped = Dictionary(grouping: remaining) { entry in
            calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
        }
        return grouped.keys.sorted(by: >).map { key in
            (month: key, entries: (grouped[key] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    StarfieldBackground()

                    if entries.isEmpty {
                        ContentUnavailableView(
                            "Nothing here yet",
                            systemImage: "photo.stack",
                            description: Text("Complete a session to add a photo to your shelf.")
                        )
                    } else {
                        ScrollView {
                            shelfContent(availableWidth: geo.size.width)
                        }
                    }
                }
            }
            .navigationTitle(profiles.first?.customActivityName ?? "Activities")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedEntry) { entry in
                PhotoPagerView(
                    entries: entries.sorted { $0.date > $1.date },
                    initialEntry: entry
                )
            }
        }
    }

    // MARK: - Contenuto

    private func shelfContent(availableWidth: CGFloat) -> some View {
        let contentWidth = availableWidth - horizontalPadding * 2
        let columnWidth = (contentWidth - columnSpacing) / 2

        return VStack(spacing: 22) {
            headerCard
            featuredCard

            ForEach(groupedByMonth, id: \.month) { group in
                monthSection(group.month, group.entries, columnWidth: columnWidth)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 40)
    }

    private var headerCard: some View {
        HStack(spacing: 24) {
            statColumn(value: "\(entries.count)", label: entries.count == 1 ? "photo" : "photos")
            if let first = entries.map(\.date).min() {
                statColumn(value: firstDateLabel(first), label: "collecting since")
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.orange)
        }
        .padding(16)
        .glassCard(padding: 0)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    /// Card grande in cima con l'ultima foto aggiunta: qui, a differenza
    /// delle celle della griglia, l'immagine viene ritagliata (.fill) per
    /// dare l'effetto "banner" — è una scelta deliberata solo per questa
    /// singola card, non per il resto della shelf.
    @ViewBuilder
    private var featuredCard: some View {
        if let entry = latestEntry, let image = ImageCache.shared.image(named: entry.imageFileName) {
            Button {
                Haptics.tap()
                selectedEntry = entry
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom, endPoint: .top
                    )
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220, alignment: .bottom)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Latest")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                        Text(entry.date.formatted(.dateTime.day().month(.wide).year()))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(ShelfTileButtonStyle())
        }
    }

    private func monthSection(_ month: Date, _ monthEntries: [CustomActivityEntry], columnWidth: CGFloat) -> some View {
        let split = balancedColumns(monthEntries, columnWidth: columnWidth)

        return VStack(alignment: .leading, spacing: 10) {
            Text(monthLabel(month))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)

            HStack(alignment: .top, spacing: columnSpacing) {
                VStack(spacing: columnSpacing) {
                    ForEach(split.left) { entry in
                        ShelfPhotoTile(entry: entry) { selectedEntry = entry }
                    }
                }
                VStack(spacing: columnSpacing) {
                    ForEach(split.right) { entry in
                        ShelfPhotoTile(entry: entry) { selectedEntry = entry }
                    }
                }
            }
        }
    }

    // MARK: - Masonry: distribuzione a due colonne bilanciate per altezza

    /// Ogni foto va nella colonna più "corta" al momento, stimando l'altezza
    /// dalla proporzione reale dell'immagine (colonna a larghezza fissa).
    /// Risultato: due colonne di altezza simile, non una griglia a caselle
    /// uguali che costringe ogni foto nello stesso riquadro.
    private func balancedColumns(
        _ items: [CustomActivityEntry],
        columnWidth: CGFloat
    ) -> (left: [CustomActivityEntry], right: [CustomActivityEntry]) {
        var left: [CustomActivityEntry] = []
        var right: [CustomActivityEntry] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0

        for entry in items {
            let estimatedHeight = columnWidth / max(estimatedAspectRatio(for: entry), 0.35)
            if leftHeight <= rightHeight {
                left.append(entry)
                leftHeight += estimatedHeight + columnSpacing
            } else {
                right.append(entry)
                rightHeight += estimatedHeight + columnSpacing
            }
        }
        return (left, right)
    }

    private func estimatedAspectRatio(for entry: CustomActivityEntry) -> CGFloat {
        guard let image = ImageCache.shared.image(named: entry.imageFileName), image.size.height > 0 else {
            return 0.75
        }
        return image.size.width / image.size.height
    }

    // MARK: - Formattazione

    private func monthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    private func firstDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Singola foto in griglia

private struct ShelfPhotoTile: View {
    let entry: CustomActivityEntry
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            content
        }
        .buttonStyle(ShelfTileButtonStyle())
    }

    /// Le proporzioni reali della foto sono sempre rispettate (nessun
    /// ritaglio forzato a quadrato): la cella si adatta all'immagine.
    @ViewBuilder
    private var content: some View {
        if let image = ImageCache.shared.image(named: entry.imageFileName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(image.size, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 0.6)
                )
                .overlay(alignment: .bottomLeading) {
                    Text(entry.date.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(8)
                }
                .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Piccola compressione al tocco, coerente su tutte le celle della shelf.
private struct ShelfTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Visualizzatore a schermo intero, scorrevole tra tutte le foto

private struct PhotoPagerView: View {
    let entries: [CustomActivityEntry]
    let initialEntry: CustomActivityEntry

    @Environment(\.dismiss) private var dismiss
    @State private var selection: UUID

    init(entries: [CustomActivityEntry], initialEntry: CustomActivityEntry) {
        self.entries = entries
        self.initialEntry = initialEntry
        _selection = State(initialValue: initialEntry.id)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(entries) { entry in
                    photoPage(entry).tag(entry.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black.ignoresSafeArea())
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func photoPage(_ entry: CustomActivityEntry) -> some View {
        if let image = ImageCache.shared.image(named: entry.imageFileName) {
            VStack {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                Spacer()
                Text(entry.date.formatted(.dateTime.day().month(.wide).year()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 24)
            }
        }
    }
}
