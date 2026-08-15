import SwiftUI

struct DayDetailView: View {
    let date: Date
    let status: DayStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                VStack {
                    if case .completed(let record) = status, let fileName = record.photoFileName, let image = ImageStore.load(fileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()
                    } else if case .completed(let record) = status {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)
                            Text("\(record.totalMinutes) Total time")
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle(date.formatted(.dateTime.day().month(.wide).year()))
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
