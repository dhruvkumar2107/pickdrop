import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/undo_confirmation.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  final List<_Address> _addresses = [
    _Address(
        type: 'Home',
        label: 'Home',
        address: '42, Jayanagar 4th Block, Bangalore - 560041',
        icon: Icons.home_rounded,
        color: Color(0xFF2563EB)),
    _Address(
        type: 'Work',
        label: 'Office',
        address: 'EGL Tech Park, Koramangala, Bangalore - 560095',
        icon: Icons.work_rounded,
        color: Color(0xFF16A34A)),
    _Address(
        type: 'Other',
        label: 'Gym',
        address: 'Cult Fit, 5th Block, Koramangala, Bangalore - 560034',
        icon: Icons.location_on_rounded,
        color: AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Saved Addresses', style: AppTextStyles.headlineSmall),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            label: Text('Add',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: _addresses.isEmpty
          ? _EmptyState(onAdd: () => _showAddDialog(context))
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              itemCount: _addresses.length,
              itemBuilder: (_, i) => _AddressTile(
                address: _addresses[i],
                onDelete: () async {
                  HapticFeedback.mediumImpact();
                  final removed = _addresses.removeAt(i);
                  if (mounted) setState(() {});
                  final undone = await showUndoConfirmation(
                    context,
                    title: 'Address removed',
                    message: '${removed.label} was deleted.',
                    actionLabel: 'Undo',
                  );
                  if (undone && mounted) {
                    setState(() => _addresses.insert(i, removed));
                  }
                },
              )
                  .animate(delay: Duration(milliseconds: i * 80))
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0),
            ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAddressSheet(),
    );
  }
}

class _Address {
  final String type;
  final String label;
  final String address;
  final IconData icon;
  final Color color;

  const _Address({
    required this.type,
    required this.label,
    required this.address,
    required this.icon,
    required this.color,
  });
}

class _AddressTile extends StatelessWidget {
  final _Address address;
  final VoidCallback onDelete;

  const _AddressTile({required this.address, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: address.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(address.icon, color: address.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.label,
                    style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(address.address,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.onSurfaceVariant),
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Edit', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded,
                        size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: const Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏠', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No saved addresses',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text('Add your home, work, or other addresses\nfor quick access during booking.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAddressSheet extends StatelessWidget {
  const _AddAddressSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusLg)),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Address', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppDimensions.spacingXl),
            TextField(
              decoration: InputDecoration(
                labelText: 'Label (Home, Work, etc.)',
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm)),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Address',
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
                child: Text('Save Address', style: AppTextStyles.labelLarge),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
