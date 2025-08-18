import Foundation

// MARK: - Notification Extensions
extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
    
    // Posted when a new run is successfully saved to the database
    static let runSaved = Notification.Name("runSaved")
    
    // Posted when a run is successfully deleted from the database
    static let runDeleted = Notification.Name("runDeleted")
    
    static let refreshRunData = Notification.Name("refreshRunData")
}
