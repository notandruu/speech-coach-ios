import SwiftUI

enum AppRoute: Hashable {
    case promptSelection
    case recording(PracticePrompt)
    case results(ScoreBreakdown, PracticePrompt)
    case history
    case settings
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
