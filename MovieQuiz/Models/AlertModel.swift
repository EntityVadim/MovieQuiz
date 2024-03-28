import Foundation

// MARK: - Alert Model
struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}
