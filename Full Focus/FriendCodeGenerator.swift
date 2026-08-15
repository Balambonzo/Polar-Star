import Foundation

enum FriendCodeGenerator {

    static func generate() -> String {

        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

        let letters = String(
            (0..<3).map { _ in
                alphabet.randomElement()!
            }
        )

        let numbers = Int.random(in: 1000...9999)

        return "\(letters)-\(numbers)"

    }

}
