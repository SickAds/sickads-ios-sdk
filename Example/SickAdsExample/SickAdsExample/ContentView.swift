import SickAdsKit
import SwiftUI

struct ContentView: View {
    @State private var lastResult: String = "Нажми кнопку для теста."

    var body: some View {
        VStack(spacing: 24) {
            Text("SickAds Example")
                .font(.title2.weight(.semibold))

            Text(lastResult)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                presentAd()
            } label: {
                Text("Показать рекламу")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func presentAd() {
        SickAds.setApiKey("example-key")

        SickAds.showAd { result in
            switch result {
            case .success:
                lastResult = "Успех! Реклама закрыта!"
            case let .failure(error):
                lastResult = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContentView()
}
