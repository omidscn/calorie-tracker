import SwiftUI

#if canImport(VisionKit)
import VisionKit
#endif

struct BarcodeScannerView: View {
    var onBarcodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
#if os(iOS)
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(onBarcodeScanned: { barcode in
                        onBarcodeScanned(barcode)
                    })
                    .ignoresSafeArea()
                } else {
                    scannerUnavailableView
                }
#else
                scannerUnavailableView
#endif
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

    private var scannerUnavailableView: some View {
        ContentUnavailableView(
            "Scanner Not Available",
            systemImage: "barcode.viewfinder",
            description: Text("Barcode scanning requires an iPhone with a camera.")
        )
    }
}

// MARK: - DataScanner UIKit Bridge (iOS only)

#if os(iOS)
private struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onBarcodeScanned: (String) -> Void
        private var hasScanned = false

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasScanned else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let value = barcode.payloadStringValue {
                    hasScanned = true
                    dataScanner.stopScanning()
                    DispatchQueue.main.async {
                        self.onBarcodeScanned(value)
                    }
                    return
                }
            }
        }
    }
}
#endif
