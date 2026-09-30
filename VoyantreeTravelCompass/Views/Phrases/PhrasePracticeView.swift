import SwiftUI

struct PhrasePracticeView: View {
    let items: [PhraseItem]
    @State private var order: [PhraseItem] = []
    @State private var index = 0
    @State private var showTranslation = false

    private var current: PhraseItem? {
        guard order.indices.contains(index) else { return nil }
        return order[index]
    }

    var body: some View {
        VStack(spacing: 18) {
            if let current {
                Text("\(index + 1) of \(order.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTranslation.toggle()
                    }
                } label: {
                    TicketCard {
                        VStack(spacing: 12) {
                            Text(current.category.uppercased())
                                .font(AppTheme.trackedLabel)
                                .tracking(1.4)
                                .foregroundColor(AppTheme.primary)
                            Text(showTranslation ? current.translation : current.original)
                                .font(AppTheme.displayTitle)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, minHeight: 96)
                            if !showTranslation, !current.transliteration.isEmpty {
                                Text(current.transliteration)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.primary)
                                    .multilineTextAlignment(.center)
                            }
                            Text(showTranslation ? "Tap to hide" : "Tap to reveal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 12) {
                    Button("Previous") { step(-1) }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(order.count < 2)
                    Button("Shuffle") { shuffle(keepCurrent: false) }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    Button("Next") { step(1) }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(order.count < 2)
                }
            } else {
                TicketCard {
                    Text("Add phrases to practice them here.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            Spacer()
        }
        .padding(18)
        .screenBackdrop("BgPass")
        .navigationTitle("Practice")
        .onAppear {
            order = items
            index = 0
            showTranslation = false
        }
    }

    private func step(_ delta: Int) {
        guard !order.isEmpty else { return }
        index = (index + delta + order.count) % order.count
        showTranslation = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func shuffle(keepCurrent: Bool) {
        guard !order.isEmpty else { return }
        let currentId = current?.id
        order.shuffle()
        if keepCurrent, let currentId, let next = order.firstIndex(where: { $0.id == currentId }) {
            index = next
        } else {
            index = 0
        }
        showTranslation = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
