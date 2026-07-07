import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var store: FluidCheckStore
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                FluidCheckTheme.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 48))
                        .foregroundColor(FluidCheckTheme.accent)
                    Text("Unlock Fluid Levels Checklist Pro")
                        .font(FluidCheckTheme.titleFont)
                        .foregroundColor(FluidCheckTheme.textPrimary)
                    Text("Multi-vehicle checklist history with low-level alerts")
                        .font(FluidCheckTheme.bodyFont)
                        .foregroundColor(FluidCheckTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button {
                        Task { await purchase() }
                    } label: {
                        Text(isPurchasing ? "Processing..." : "Subscribe $1.99/month")
                            .font(FluidCheckTheme.bodyFont.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FluidCheckTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(isPurchasing)
                    .accessibilityIdentifier("subscribeButton")
                    .padding(.horizontal)
                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red).font(.caption)
                    }
                    Button("Not now") { dismiss() }
                        .foregroundColor(FluidCheckTheme.textSecondary)
                        .accessibilityIdentifier("dismissPaywallButton")
                }
                .padding()
            }
        }
    }

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await purchases.purchasePro()
            if purchases.isPro {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
        .environmentObject(FluidCheckStore())
}
