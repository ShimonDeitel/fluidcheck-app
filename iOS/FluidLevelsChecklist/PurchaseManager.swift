import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let proProductID = "com.shimondeitel.fluidcheck.pro.monthly"

    @Published private(set) var isPro: Bool = false
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.proProductID {
            isPro = transaction.revocationDate == nil
        }
        await transaction.finish()
    }

    func purchasePro() async throws {
        let products = try await Product.products(for: [Self.proProductID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result {
            await handle(verification)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }
}
