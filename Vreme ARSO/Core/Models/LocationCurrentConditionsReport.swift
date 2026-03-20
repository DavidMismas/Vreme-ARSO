import Foundation

struct LocationCurrentConditionsReport: Sendable {
    let locationName: String
    let observation: CurrentObservation
    let sourceURL: URL
}
