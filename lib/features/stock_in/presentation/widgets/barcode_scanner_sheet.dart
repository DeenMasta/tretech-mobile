import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

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
    this.manualLabel = 'Manual entry',
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
  final TextEditingController _valueCtl = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _manual = false;
  bool _flashEnabled = false;
  bool _handled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _valueCtl.dispose();
    super.dispose();
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
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                _manual
                    ? 'Type the value when the barcode is unavailable or unreadable.'
                    : 'Aim the rear camera at the barcode or QR code.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              if (_manual) ...[
                AppTextField(
                  controller: _valueCtl,
                  label: 'Manual value',
                  hint: 'Type the captured value',
                  prefixIcon: Icons.keyboard_rounded,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppButton(
                  label: 'Confirm',
                  icon: Icons.check_rounded,
                  onPressed: () => _submit(_valueCtl.text),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusLg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _flashEnabled ? 'Flash off' : 'Flash on',
                        variant: AppButtonVariant.secondary,
                        icon: _flashEnabled
                            ? Icons.flash_off_rounded
                            : Icons.flash_on_rounded,
                        onPressed: _toggleTorch,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppDimensions.spaceSm),
              AppButton(
                label: _manual ? 'Use camera scanner' : widget.manualLabel,
                variant: AppButtonVariant.ghost,
                icon: _manual
                    ? Icons.qr_code_scanner_rounded
                    : Icons.keyboard_rounded,
                onPressed: _toggleEntryMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcode = capture.barcodes.cast<Barcode?>().firstWhere(
      (item) => (item?.rawValue?.trim().isNotEmpty ?? false),
      orElse: () => null,
    );
    final value = barcode?.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(BarcodeScanResult(value: value, manual: false));
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() => _flashEnabled = !_flashEnabled);
  }

  Future<void> _toggleEntryMode() async {
    if (_manual) {
      _handled = false;
      await _scannerController.start();
    } else {
      await _scannerController.stop();
      _valueCtl.clear();
    }
    if (!mounted) return;
    setState(() => _manual = !_manual);
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(BarcodeScanResult(value: trimmed, manual: true));
  }
}
