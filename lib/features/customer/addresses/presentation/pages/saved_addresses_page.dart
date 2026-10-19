import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Saved Addresses', style: AppTextStyles.headlineSmall),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actions: [
          TextButton.icon(
            onPressed: uid == null
                ? null
                : () => context.push(RouteNames.addAddress),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            label: Text(
              'Add',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to manage saved addresses.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('savedAddresses')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load saved addresses.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _EmptyState(
                    onAdd: () => context.push(RouteNames.addAddress),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.spacingXl),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final type = (data['type'] ?? 'Other').toString();
                    final label = (data['label'] ?? type).toString();
                    final icon = type == 'Home'
                        ? Icons.home_rounded
                        : type == 'Work'
                        ? Icons.work_rounded
                        : Icons.location_on_rounded;
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(
                        bottom: AppDimensions.spacingMd,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: .12,
                          ),
                          child: Icon(icon, color: AppColors.primary),
                        ),
                        title: Text(label, style: AppTextStyles.titleMedium),
                        subtitle: Text(
                          (data['address'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete address',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                          ),
                          onPressed: () => doc.reference.delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.home_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text('No saved addresses', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Save a pickup location for faster bookings.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add address'),
        ),
      ],
    ),
  );
}
