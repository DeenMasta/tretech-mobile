import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// A bottom-sheet barcode scanner with manual-entry fallback.
///
/// Returns the scanned/typed value, plus a flag indicating whether the
/// value was entered manually so the caller can flag manual audit logs.
class BarcodeScanResult {
  const BarcodeScanResult({required this.value, required this.manual});

  final String value;
  final bool manual;
}

class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({
    super.key,
    required this.title,
    required this.helperText,
    this.manualLabel = 'Type manually',
  });

  final String title;
  final String helperText;
  final String manualLabel;

  static Future<BarcodeScanResult?> show(
    BuildContext context, {
    required String title,
    required String helperText,
  }) {
    return showModalBottomSheet<BarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => BarcodeScannerSheet(title: title, helperText: helperText),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _manual = false;
  bool _handled = false;
  final TextEditingController _manualCtl = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualCtl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes
        .map((b) => b.rawValue ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(BarcodeScanResult(value: value, manual: false));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Text(widget.title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text(widget.helperText, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppDimensions.spaceLg),
              if (_manual)
                _buildManual()
              else
                _buildScanner(),
              const SizedBox(height: AppDimensions.spaceLg),
              AppButton(
                label: _manual ? 'Use camera' : widget.manualLabel,
                variant: AppButtonVariant.ghost,
                icon: _manual
                    ? Icons.qr_code_scanner_rounded
                    : Icons.keyboard_rounded,
                onPressed: () => setState(() => _manual = !_manual),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (_, error, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              child: Text(
                'Camera unavailable: ${error.errorCode.name}.\nUse manual entry below.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _manualCtl,
          label: 'Manual entry',
          hint: 'Type or paste the value',
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: _submitManual,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        AppButton(
          label: 'Confirm',
          icon: Icons.check_rounded,
          onPressed: () => _submitManual(_manualCtl.text),
        ),
      ],
    );
  }

  void _submitManual(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(BarcodeScanResult(value: v, manual: true));
  }
}
