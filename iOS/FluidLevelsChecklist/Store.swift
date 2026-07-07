import Foundation
import Combine

@MainActor
final class FluidCheckStore: ObservableObject {
    @Published private(set) var items: [FluidCheck] = []
    @Published var isPro: Bool = false

    /// Free-tier item cap. Seed data count is always well below this so a
    /// fresh install never hits the paywall immediately.
    static let freeLimit = 8

    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        fileURL = support.appendingPathComponent("fluidcheck_store.json")
        load()
        if items.isEmpty {
            seed()
        }
    }

    private func seed() {
        let cal = Calendar.current
        items = [
            FluidCheck(name: "Sample Fluid Check A", detail: "Example", date: cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()),
            FluidCheck(name: "Sample Fluid Check B", detail: "Example", date: cal.date(byAdding: .day, value: -10, to: Date()) ?? Date())
        ]
        save()
    }

    var canAddMore: Bool {
        isPro || items.count < Self.freeLimit
    }

    @discardableResult
    func add(_ item: FluidCheck) -> Bool {
        guard canAddMore else { return false }
        items.append(item)
        save()
        return true
    }

    func update(_ item: FluidCheck) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([FluidCheck].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
