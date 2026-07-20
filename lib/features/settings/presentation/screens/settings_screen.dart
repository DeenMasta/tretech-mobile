import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/bluetooth_print_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../router/route_names.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loadingDevices = false;

  Future<void> _testPrint(String macAddress) async {
    final service = ref.read(bluetoothPrintServiceProvider);

    // Very simple TSPL test payload
    const tspl = '''
SIZE 40 mm, 30 mm
GAP 2 mm, 0 mm
CLS
TEXT 10,10,"4",0,1,1,"Test Print Successful!"
PRINT 1
''';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sending test print...')));

    final result = await service.printTspl(macAddress, tspl);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print completed successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print failed: ${result.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectPrinter() async {
    setState(() => _loadingDevices = true);

    if (await Permission.bluetoothConnect.request().isDenied ||
        await Permission.bluetoothScan.request().isDenied ||
        await Permission.locationWhenInUse.request().isDenied) {
      setState(() => _loadingDevices = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bluetooth & Location permissions are required to select a printer.',
            ),
          ),
        );
      }
      return;
    }

    final service = ref.read(bluetoothPrintServiceProvider);
    final devices = await service.listPairedDevices();
    setState(() => _loadingDevices = false);

    if (!mounted) return;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No paired Bluetooth devices found. Pair your printer in device Settings first.',
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PrinterPickerSheet(
        devices: devices,
        onSelected: (device) {
          ref
              .read(settingsProvider.notifier)
              .savePrinter(
                printerName: device.name,
                macAddress: device.macAddress,
              );
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Printer set to "${device.name}"')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final printer = ref.watch(settingsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text('Settings', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.dashboard);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        children: [
          // ── Account Section ──
          if (currentUser != null) ...[
            const _SectionHeader(label: 'Account'),
            const SizedBox(height: AppDimensions.spaceSm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceLg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            currentUser.name.isNotEmpty
                                ? currentUser.name.substring(0, 1).toUpperCase()
                                : 'U',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentUser.email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                ),
                                child: Text(
                                  currentUser.mobileRoleLabel,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXl),
          ],

          // ── Bluetooth Printer Section ──
          const _SectionHeader(label: 'Bluetooth Printer'),
          const SizedBox(height: AppDimensions.spaceSm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Current printer info
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceLg),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: printer.isConfigured
                              ? AppColors.successContainer
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Icon(
                          Icons.print_rounded,
                          color: printer.isConfigured
                              ? AppColors.success
                              : AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printer.isConfigured
                                  ? printer.printerName
                                  : 'No printer configured',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              printer.isConfigured
                                  ? printer.macAddress
                                  : 'Tap "Select Printer" to configure',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (printer.isConfigured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Active',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (printer.isConfigured) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _testPrint(printer.macAddress),
                                icon: const Icon(Icons.print_rounded, size: 16),
                                label: const Text('Test Print'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceSm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ref.read(settingsProvider.notifier).clearPrinter();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Printer disconnected.')),
                                  );
                                },
                                icon: const Icon(Icons.link_off_rounded, size: 16),
                                label: const Text('Disconnect'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                    color: AppColors.error.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),
                      ],
                      OutlinedButton.icon(
                        onPressed: _loadingDevices ? null : _selectPrinter,
                        icon: _loadingDevices
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.bluetooth_searching_rounded,
                                size: 16,
                              ),
                        label: Text(
                          printer.isConfigured
                              ? 'Change Printer'
                              : 'Select Printer',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXl),

          // ── App Info Section ──
          const _SectionHeader(label: 'App Info'),
          const SizedBox(height: AppDimensions.spaceSm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                _InfoTile(label: 'Version', value: '1.0.0'),
                Divider(height: 1),
                _InfoTile(label: 'App', value: 'TRETECH Warehouse Manager'),
                Divider(height: 1),
                _InfoTile(
                  label: 'Company',
                  value: 'TREMED Surgical Solution Sdn Bhd',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXl),

          // ── Logout Section ──
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go(RouteNames.login);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceLg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
            ),
          ),
          
          const SizedBox(height: AppDimensions.space4xl),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceLg,
        vertical: AppDimensions.spaceMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Printer picker bottom sheet ───────────────────────────────────────────────

class _PrinterPickerSheet extends StatelessWidget {
  const _PrinterPickerSheet({required this.devices, required this.onSelected});

  final List<BluetoothDevice> devices;
  final void Function(BluetoothDevice device) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
            AppDimensions.spaceSm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'Select Bluetooth Printer',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                iconSize: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: devices.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final device = devices[i];
              return ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  device.name.isNotEmpty ? device.name : 'Unknown Device',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  device.macAddress,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onTap: () => onSelected(device),
              );
            },
          ),
        ),
        SizedBox(
          height: MediaQuery.paddingOf(context).bottom + AppDimensions.spaceMd,
        ),
      ],
    );
  }
}
