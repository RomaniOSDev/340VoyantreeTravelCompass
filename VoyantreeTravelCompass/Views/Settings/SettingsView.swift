import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    NavigationLink {
                        StatsView()
                    } label: {
                        settingsLabel(title: "Statistics", icon: "chart.bar.fill")
                    }
                    .buttonStyle(GoldPressStyle())
                    .frame(minHeight: 44)
                    settingsRow(title: "Rate Us", icon: "star.fill") {
                        rateApp()
                    }
                    settingsRow(title: "Privacy", icon: "hand.raised.fill") {
                        if let url = URL(string: AppLinks.privacy.rawValue) {
                            UIApplication.shared.open(url)
                        }
                    }
                    settingsRow(title: "Terms", icon: "doc.text.fill") {
                        if let url = URL(string: AppLinks.terms.rawValue) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        TicketCard {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset All Data")
                                    .font(.headline)
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .frame(minHeight: 44)
                }
                .padding(18)
            }
            .screenBackdrop("BgPass")
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Erase all saved trips?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { store.resetAllData() }
                Button("Cancel", role: .cancel) { }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsLabel(title: title, icon: icon)
        }
        .buttonStyle(GoldPressStyle())
        .frame(minHeight: 44)
    }

    private func settingsLabel(title: String, icon: String) -> some View {
        TicketCard {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 28)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
