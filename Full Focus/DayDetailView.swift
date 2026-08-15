import SwiftUI

struct DayDetailView: View {
    let detail: ConstellationView.DayDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        if let fileName = detail.photoFileName, let image = ImageStore.load(fileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                        }

                        if let milestone = detail.milestone {
                            VStack(spacing: 6) {
                                Text(milestone.displayName)
                                    .font(.title3.bold())
                                    .foregroundStyle(milestone.coreColor)
                                Text("Goal of your streak")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }

                        VStack(spacing: 10) {
                            HStack {
                                Label("Total time", systemImage: "clock.fill")
                                Spacer()
                                Text("\(detail.totalMinutes) min")
                            }
                            if !detail.completedActivityLabels.isEmpty {
                                Divider().overlay(Theme.cardBorder)
                                ForEach(detail.completedActivityLabels, id: \.self) { label in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(label)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                        .glassCard()
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(detail.date.formatted(.dateTime.day().month(.wide).year()))
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
}
