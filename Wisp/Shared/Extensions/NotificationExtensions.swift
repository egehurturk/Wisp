import Foundation

// MARK: - Notification Extensions
extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
    
    // Posted when a new run is successfully saved to the database
    static let runSaved = Notification.Name("runSaved")
    
    static let refreshRunData = Notification.Name("refreshRunData")
}
