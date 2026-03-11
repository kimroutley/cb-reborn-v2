import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cb_theme/cb_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _isProcessing = true);
        HapticService.heavy();
        
        String joinCode = rawValue;
        
        // Attempt to parse if it's a URL
        if (rawValue.contains('cb-reborn.web.app/join') && rawValue.contains('code=')) {
          final uri = Uri.tryParse(rawValue);
          if (uri != null && uri.queryParameters.containsKey('code')) {
            joinCode = uri.queryParameters['code']!;
          }
        }
        
        cameraController.stop();
        Navigator.of(context).pop(joinCode);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'SCAN VIP PASS',
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          // Custom Scanner Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6), // Backdrop
            ),
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const SizedBox(),
              ),
            ),
          ),
          // Cutout transparent box for scanner
          Center(
            child: Container(
              width: 276,
              height: 276,
              color: Colors.transparent, // Where the scanner is clearly visible
            ),
          ),
          
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'SCAN HOST TERMINAL',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: CBColors.textGlow(scheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Align the QR code within the frame',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: CBGhostButton(
                label: 'CANCEL',
                onPressed: () {
                  HapticService.light();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
