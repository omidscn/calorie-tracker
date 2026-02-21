import SwiftUI
import SwiftData
#if os(iOS)
import VisionKit
#endif

struct ContentView: View {
    @State private var calorieService = CalorieEstimationService()
    @State private var syncMonitor = CloudSyncMonitor()
    #if os(iOS)
    @State private var foodLookupService = FoodLookupService()
    #endif
    @State private var viewModel = DayLogViewModel()

    var body: some View {
        DayLogView(viewModel: viewModel)
            .environment(calorieService)
            .environment(syncMonitor)
            #if os(iOS)
            .environment(foodLookupService)
            .background { CameraPrewarmer() }
            #endif
    }
}

#if os(iOS)
// Silently boots the camera XPC session in the background so the first
// real barcode scan opens instantly instead of hanging while the system
// initialises the capture pipeline.
private struct CameraPrewarmer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.frame = .zero
        Task { @MainActor in
            guard DataScannerViewController.isSupported,
                  DataScannerViewController.isAvailable else { return }
            let scanner = DataScannerViewController(recognizedDataTypes: [.barcode()])
            host.addChild(scanner)
            scanner.view.frame = CGRect(x: -1, y: -1, width: 1, height: 1)
            host.view.addSubview(scanner.view)
            scanner.didMove(toParent: host)
            try? scanner.startScanning()
            try? await Task.sleep(for: .seconds(2))
            scanner.stopScanning()
            scanner.willMove(toParent: nil)
            scanner.view.removeFromSuperview()
            scanner.removeFromParent()
        }
        return host
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self], inMemory: true)
}
