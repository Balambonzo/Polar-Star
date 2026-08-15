import Foundation

enum MotivationalNotifications {

    static func randomWarning() -> String {
        warning.randomElement()!
    }

    static func randomFinalWarning() -> String {
        finalWarning.randomElement()!
    }

    static func randomInactivity() -> String {
        inactivity.randomElement()!
    }

    static let warning = [

        "Every excuse costs you a future.",

        "Discipline is built when nobody is watching.",

        "One hour decides who you'll become.",

        "Comfort has never created greatness.",

        "Don't negotiate with weakness.",

        "You promised yourself you wouldn't quit.",

        "Small actions become extraordinary lives.",

        "Your future self is waiting.",

        "Stay consistent.",

        "Momentum is earned."

    ]

    static let finalWarning = [

        "No one is coming to save you.",

        "This decision will echo tomorrow.",

        "The dream survives only if you do.",

        "Discipline or regret. Choose.",

        "Your excuses don't care about your future.",

        "The streak is almost gone.",

        "Don't betray yesterday's effort.",

        "Greatness is one action away.",

        "Pain fades. Regret stays.",

        "Finish what you started."

    ]

    static let inactivity = [

        "Dreams disappear one excuse at a time.",

        "Someone with less talent kept going.",

        "Your potential is still waiting.",

        "Time never pauses.",

        "The cost of inaction is invisible until it's too late.",

        "Consistency is remembered forever.",

        "The hardest step is today's.",

        "Stop watching your future leave.",

        "Discipline begins now.",

        "Become the person you promised yourself."

    ]
    
    static func streakIdentityLine(forDays days: Int) -> String {
        switch days {
        case 0...6:
            return "Every master was once a beginner."
        case 7...29:
            return "You're building something most people never will."
        case 30...99:
            return "Discipline is becoming your identity."
        default:
            return "You're no longer chasing motivation. You're living by discipline."
        }
    }

}
