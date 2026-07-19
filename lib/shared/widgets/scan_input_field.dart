import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Shared scan-or-type input used by inventory movement modules.
///
/// The owner keeps domain lookup/debounce logic, while this widget keeps the
/// consistent scanner affordance, browse affordance, and loading treatment.
class ScanInputField extends StatelessWidget {
  const ScanInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onScan,
    this.onBrowse,
    this.browseIcon = Icons.list_alt_rounded,
    this.enabled = true,
    this.isLoading = false,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onScan;
  final VoidCallback? onBrowse;
  final IconData browseIcon;
  final bool enabled;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    label: label,
    hint: hint,
    prefixIcon: Icons.qr_code_scanner_rounded,
    onPrefixIconTap: enabled ? onScan : null,
    suffixIcon: onBrowse == null ? null : browseIcon,
    onSuffixIconTap: enabled ? onBrowse : null,
    enabled: enabled,
    isLoading: isLoading,
    errorText: errorText,
    textInputAction: TextInputAction.search,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}
