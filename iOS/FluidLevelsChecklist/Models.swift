import Foundation

struct FluidCheck: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String        // Fluid name
    var detail: String      // Level status
    var date: Date           // Checked date
    var note: String = ""
}
