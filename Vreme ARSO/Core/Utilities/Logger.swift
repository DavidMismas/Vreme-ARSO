import Foundation
import OSLog

enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.david.vremearso"
    static let app = OSLog(subsystem: subsystem, category: "app")
    static let network = OSLog(subsystem: subsystem, category: "network")
}
