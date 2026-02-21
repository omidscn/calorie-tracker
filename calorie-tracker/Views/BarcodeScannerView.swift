import SwiftUI

#if os(iOS)
import VisionKit

struct BarcodeScannerView: View {
    var onBarcodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isCameraReady = false

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    ZStack {
                        DataScannerRepresentable(
                            onBarcodeScanned: onBarcodeScanned,
                            onCameraReady: { withAnimation(.easeIn(duration: 0.3)) { isCameraReady = true } }
                        )
                        .ignoresSafeArea()

                        if !isCameraReady {
                            loadingOverlay
                        }
                    }
                } else {
                    scannerUnavailableView
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                Text("Starting camera…")
                    .foregroundStyle(.white)
                    .font(.subheadline)
            }
        }
        .transition(.opacity)
    }

    private var scannerUnavailableView: some View {
        ContentUnavailableView(
            "Scanner Not Available",
            systemImage: "barcode.viewfinder",
            description: Text("Barcode scanning requires an iPhone with a camera.")
        )
    }
}

// MARK: - DataScanner UIKit Bridge

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onBarcodeScanned: (String) -> Void
    var onCameraReady: () -> Void

    func makeUIViewController(context: Context) -> ScannerContainerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return ScannerContainerViewController(scanner: scanner, onCameraReady: onCameraReady)
    }

    func updateUIViewController(_ uiViewController: ScannerContainerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned, onCameraReady: onCameraReady)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onBarcodeScanned: (String) -> Void
        var onCameraReady: () -> Void
        private var hasScanned = false
        private var hasSignalledReady = false

        init(onBarcodeScanned: @escaping (String) -> Void, onCameraReady: @escaping () -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
            self.onCameraReady = onCameraReady
        }

        // Any delegate event means the camera is processing frames — signal ready.
        private func signalReadyIfNeeded() {
            guard !hasSignalledReady else { return }
            hasSignalledReady = true
            DispatchQueue.main.async { self.onCameraReady() }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            signalReadyIfNeeded()
            guard !hasScanned else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let value = barcode.payloadStringValue {
                    hasScanned = true
                    dataScanner.stopScanning()
                    DispatchQueue.main.async { self.onBarcodeScanned(value) }
                    return
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            signalReadyIfNeeded()
        }
    }
}

// MARK: - Container

// Starts/stops scanning at the correct UIKit lifecycle points.
// Falls back to clearing the loading overlay after 3 s if the camera
// produces no delegate events (e.g. nothing in frame to detect).
final class ScannerContainerViewController: UIViewController {
    private let scanner: DataScannerViewController
    private let onCameraReady: () -> Void
    private var readyFallbackTask: Task<Void, Never>?

    init(scanner: DataScannerViewController, onCameraReady: @escaping () -> Void) {
        self.scanner = scanner
        self.onCameraReady = onCameraReady
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(scanner)
        scanner.view.frame = view.bounds
        scanner.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scanner.view)
        scanner.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // startScanning() internally calls AVCaptureSession.startRunning(), which
        // is computationally expensive and must NOT run on the main thread or it
        // blocks the UI until the camera pipeline is ready.
        let sc = scanner
        DispatchQueue.global(qos: .userInitiated).async {
            try? sc.startScanning()
        }

        // Fallback: if no frames are detected within 3 s (e.g. empty frame),
        // hide the loading overlay anyway so it doesn't stick forever.
        readyFallbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.onCameraReady()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        readyFallbackTask?.cancel()
        scanner.stopScanning()
    }
}
#endif
