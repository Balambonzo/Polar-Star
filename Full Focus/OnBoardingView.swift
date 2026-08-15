import SwiftUI
import SwiftData
import PhotosUI

struct OnboardingView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @State private var page = 0

    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var goal: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var trainingBaselineLevels: [String: Int] = [:]

    @State private var selectedActivityKeys: Set<String> = []
    @State private var onboardingTrainingLevel: TrainingLevel = .beginner
    @State private var dailyReadingMinutes: Int = 15
    @State private var customActivityName: String = ""
    @State private var customActivityMinutes: Int = 30

    var body: some View {
        ZStack {
            StarfieldBackground()

            TabView(selection: $page) {
                introPage(
                    icon: "sparkles",
                    title: "PolarStar",
                    subtitle: "PolarStar is a simple app to help you build real results, with constancy every day. This is not a motivational app, it is a way that makes you be honest with yourself."
                )
                .tag(0)

                introPage(
                    icon: "checkmark.circle.fill",
                    title: "Choose, Complete, Win",
                    subtitle: "You can choose up to 4 activity to work on: study, exercise, reading, or anything else you want. Every day, complete what you choose, and leave a concrete result: a photo, a timer completed, a page read."
                )
                .tag(1)

                introPage(
                    icon: "moon.stars.fill",
                    title: "Constancy is not invisible",
                    subtitle: "Every completed day lights up a star in your personal sky. A skipped day leaves an empty space forever: no recovery, no shortcut. That's what makes it real."
                )
                .tag(2)

                activityChoicePage
                    .tag(3)
                
                BodyBaselineSetupView(levels: $trainingBaselineLevels) {
                    withAnimation { page = 5 }
                }
                .tag(4)

                setupPage
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: page == 3 || page == 4 ? .never : .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .onAppear {
            fullName = profile.fullName
            username = profile.username
            goal = profile.goal ?? ""
        }
    }

    // MARK: - Pagine introduttive

    @ViewBuilder
    private func introPage(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .yellow.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .orange.opacity(0.5), radius: 20)

            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()
            Spacer()

            Button {
                withAnimation { page += 1 }
            } label: {
                Text("Avanti")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Scelta attività (multi-select, 1-4)

    private var activityChoicePage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("What do you want to improve?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                Text("Choose 1-4 activities you want to improve. Each one has its own section.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    activityToggleCard(key: ActivityKey.study.rawValue, title: "Study", subtitle: "A daily picture to never forget your work", icon: "book.fill")

                    activityToggleCard(key: ActivityKey.training.rawValue, title: "Training", subtitle: "Simple free-body exercises to improve yourself day after day", icon: "figure.strengthtraining.traditional")
                    if selectedActivityKeys.contains(ActivityKey.training.rawValue) {
                        trainingConfig
                    }

                    activityToggleCard(key: ActivityKey.reading.rawValue, title: "Reading", subtitle: "One book at a time, page after page", icon: "book.closed.fill")
                    if selectedActivityKeys.contains(ActivityKey.reading.rawValue) {
                        readingConfig
                    }

                    activityToggleCard(key: ActivityKey.custom.rawValue, title: "Jolly activity", subtitle: "Choose an hobby you want to cultivate constantly", icon: "star.fill")
                    if selectedActivityKeys.contains(ActivityKey.custom.rawValue) {
                        customConfig
                    }
                }
                .padding(.horizontal, 28)

                Button {
                    withAnimation {
                        page = selectedActivityKeys.contains(ActivityKey.training.rawValue) ? 4 : 5
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceedFromActivityPage ? Color.orange : Color.gray.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canProceedFromActivityPage)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private var canProceedFromActivityPage: Bool {
        guard !selectedActivityKeys.isEmpty else { return false }
        if selectedActivityKeys.contains(ActivityKey.custom.rawValue) && customActivityName.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return true
    }

    private func activityToggleCard(key: String, title: String, subtitle: String, icon: String) -> some View {
        let isSelected = selectedActivityKeys.contains(key)
        return Button {
            if isSelected {
                selectedActivityKeys.remove(key)
            } else {
                selectedActivityKeys.insert(key)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .orange : .white.opacity(0.5))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .white.opacity(0.3))
            }
            .padding()
            .background(isSelected ? Color.orange.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var trainingConfig: some View {
        VStack(spacing: 8) {
            Text("Level")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Picker("Level", selection: $onboardingTrainingLevel) {
                ForEach(TrainingLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.top, 2)
        .padding(.bottom, 6)
    }

    private var readingConfig: some View {
        VStack(spacing: 6) {
            Text("Reading even just a few pages every day builds a habit that lasts—and over time, it adds up much more than you think.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Stepper("Minimum per day: \(dailyReadingMinutes) min", value: $dailyReadingMinutes, in: 5...60, step: 5)
                .foregroundStyle(.white)
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    private var customConfig: some View {
        VStack(spacing: 10) {
            OnboardingField(placeholder: "Jolly activity", text: $customActivityName)
            Stepper("Minutes per day: \(customActivityMinutes) min", value: $customActivityMinutes, in: 5...120, step: 5)
                .foregroundStyle(.white)
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    // MARK: - Pagina di setup profilo

    private var setupPage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Now tell us something about you!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                Text("You can change everything later in the profile section")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.orange, .orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 100, height: 100)

                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }

                VStack(spacing: 14) {
                    OnboardingField(placeholder: "Full name", text: $fullName)
                    OnboardingField(placeholder: "Nickname", text: $username)
                    OnboardingField(placeholder: "Main goal", text: $goal)
                }
                .padding(.horizontal, 28)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Start")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            fullName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : Color.orange,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .dismissKeyboardOnTap()
                .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() {
        profile.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.goal = trimmedGoal.isEmpty ? nil : trimmedGoal
        if let selectedImage, let fileName = ImageStore.save(selectedImage) {
            profile.profileImagePath = fileName
        }
        profile.hasCompletedOnboarding = true
        profile.selectedActivities = Array(selectedActivityKeys)

        if selectedActivityKeys.contains(ActivityKey.training.rawValue) {
                    profile.trainingLevel = onboardingTrainingLevel.rawValue
                    profile.initialMuscleLevels = trainingBaselineLevels
                }
        if selectedActivityKeys.contains(ActivityKey.reading.rawValue) {
            profile.dailyReadingMinimumMinutes = dailyReadingMinutes
        }
        if selectedActivityKeys.contains(ActivityKey.custom.rawValue) {
            profile.customActivityName = customActivityName.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.customActivityDurationMinutes = customActivityMinutes
        }

        try? modelContext.save()

        Task {
            await ensureUniqueCodeAndPublish()
        }
    }

    private func ensureUniqueCodeAndPublish() async {
        var attempts = 0
        while attempts < 5 {
            guard (try? await FriendLookupService.lookupFriend(byCode: profile.friendCode)) != nil else {
                break
            }
            profile.friendCode = FriendCodeGenerator.generate()
            try? modelContext.save()
            attempts += 1
        }

        try? await FriendLookupService.publishMyProfile(
            friendCode: profile.friendCode,
            username: profile.username,
            currentStreak: 0,
            bestStreak: 0,
            lastEntryDate: nil,
            latestPhoto: nil
        )
    }
}

private struct OnboardingField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
            .foregroundStyle(.white)
            .padding()
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .autocorrectionDisabled()
    }
}
