import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../../../common/map/presentation/pages/map_picker_page.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedLabel = 'Home';
  double? _lat;
  double? _lng;

  static const List<String> _labels = ['Home', 'Work', 'Other'];

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await context.push<MapPickerResult>(RouteNames.mapPicker);
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      if (result.address.isNotEmpty) {
        _addressController.text = result.address;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      AppToast.warning(context, 'Pick the exact location on the map');
      return;
    }
    AppToast.success(context, 'Address saved');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            height: safeTop + 120,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Expanded(
                      child: Text(
                        AppStrings.addAddress,
                        style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Save as', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      children: _labels
                          .map(
                            (label) => Padding(
                              padding: const EdgeInsets.only(
                                  right: AppDimensions.spacingSm),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: _selectedLabel == label,
                                selectedColor: AppColors.primaryContainer,
                                labelStyle: AppTextStyles.labelLarge.copyWith(
                                  color: _selectedLabel == label
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedLabel = label),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Flat / Street / Area / City',
                      validator: (v) => Validators.required(v),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    GlassCard(
                      onTap: _pickOnMap,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.map_outlined,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Set location on map',
                                    style: AppTextStyles.labelLarge),
                                Text(
                                  _lat == null
                                      ? 'Required — tap to open the map'
                                      : 'Pinned: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: _lat == null
                                        ? AppColors.onSurfaceVariant
                                        : const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    GradientButton(
                      text: AppStrings.save,
                      isFullWidth: true,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
