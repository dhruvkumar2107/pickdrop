import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../data/datasources/insurance_claim_remote_datasource.dart';

class InsuranceClaimSheet extends StatefulWidget {
  final String bookingId;
  final double goodsValue;

  const InsuranceClaimSheet({
    super.key,
    required this.bookingId,
    this.goodsValue = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    double goodsValue = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsuranceClaimSheet(
        bookingId: bookingId,
        goodsValue: goodsValue,
      ),
    );
  }

  @override
  State<InsuranceClaimSheet> createState() => _InsuranceClaimSheetState();
}

class _InsuranceClaimSheetState extends State<InsuranceClaimSheet> {
  static const int _maxPhotos = 3;
  static const List<String> _incidents = [
    'Goods damaged in transit',
    'Items missing after delivery',
    'Water or rain damage',
    'Vehicle accident in transit',
  ];

  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _incident;
  final List<XFile> _photos = [];
  String? _claimId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.goodsValue > 0) {
      _valueController.text = widget.goodsValue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _photos.add(picked));
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not open the photo picker');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    final value = double.tryParse(_valueController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();

    if (_incident == null) {
      AppToast.warning(context, 'Please tell us what happened');
      return;
    }
    if (value <= 0) {
      AppToast.warning(context, 'Please enter the value of your goods');
      return;
    }
    if (description.isEmpty) {
      AppToast.warning(context, 'Please describe the damage');
      return;
    }
    if (_photos.isEmpty) {
      AppToast.warning(context, 'Please attach at least one photo');
      return;
    }

    setState(() => _submitting = true);
    try {
      final dataSource = InsuranceClaimRemoteDataSource();
      final claimId = await dataSource.createClaim(
        bookingId: widget.bookingId,
        amount: value,
        description: description,
        photoUrls: _photos.map((photo) => photo.path).toList(growable: false),
        incidentType: _incident!,
      );
      if (!mounted) return;
      setState(() => _claimId = claimId);
      AppToast.success(context, 'Claim submitted - track its status below');
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not submit the claim. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingXl,
        AppDimensions.spacingMd,
        AppDimensions.spacingXl,
        AppDimensions.spacingXl + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingSm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.health_and_safety_rounded,
                      color: colors.primary, size: 22),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transit insurance claim',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'Trip ${widget.bookingId} - settled within 24 hours',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            if (_claimId == null) _buildForm(colors) else _buildTracker(colors),
          ],
        ),
      ),
    );
  }

  InputDecoration _field(
    AppColorsExtension colors, {
    required String hint,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: colors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildForm(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What happened?',
          style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: _incidents.map((incident) {
            final selected = _incident == incident;
            return ChoiceChip(
              label: Text(incident),
              labelStyle: AppTextStyles.labelSmall.copyWith(
                color: selected ? colors.onPrimary : colors.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              selected: selected,
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceVariant,
              onSelected: (_) => setState(() => _incident = incident),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Value of goods (₹)',
          style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        TextField(
          controller: _valueController,
          keyboardType: TextInputType.number,
          decoration: _field(colors, hint: 'e.g. 8000', prefix: '₹ '),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Damage description',
          style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: _field(
            colors,
            hint: 'Describe what was damaged, where and when it happened',
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Photos ($_photos.length/$_maxPhotos)',
          style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Row(
          children: List.generate(_maxPhotos, (index) {
            final hasPhoto = index < _photos.length;
            return Padding(
              padding: EdgeInsets.only(
                right: index == _maxPhotos - 1 ? 0 : AppDimensions.spacingSm,
              ),
              child: GestureDetector(
                onTap: hasPhoto ? () => _removePhoto(index) : _addPhoto,
                child: Container(
                  width: 84,
                  height: 84,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: hasPhoto ? colors.primary : colors.outline,
                    ),
                  ),
                  child: hasPhoto
                      ? Image.file(
                          File(_photos[index].path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: colors.primary, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'Add',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: colors.primary),
                            ),
                          ],
                        ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        GradientButton(
          text: 'Submit claim',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildTracker(AppColorsExtension colors) {
    return StreamBuilder<InsuranceClaimModel?>(
      stream: InsuranceClaimRemoteDataSource().watchClaim(_claimId!),
      builder: (context, snapshot) {
        final claim = snapshot.data;
        final status = claim?.status ?? 'SUBMITTED';
        final stage = _stageIndex(status);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Claim ${_claimId!}',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                StatusChip.fromStatus(status),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                _stage(colors, 'Submitted', stage >= 0, 0),
                _connector(colors, stage >= 1),
                _stage(colors, 'Under review', stage >= 1, 1),
                _connector(colors, stage >= 2),
                _stage(colors, 'Approved / Paid', stage >= 2, 2),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: colors.infoLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: colors.info),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      _statusMessage(status),
                      style: AppTextStyles.bodySmall.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            GradientButton(
              text: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        );
      },
    );
  }

  int _stageIndex(String status) {
    switch (status.toUpperCase()) {
      case 'UNDER_REVIEW':
        return 1;
      case 'APPROVED':
      case 'PAID':
        return 2;
      default:
        return 0;
    }
  }

  String _statusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'UNDER_REVIEW':
        return 'Our claims team is verifying your photos and trip record. You will hear from us within 24 hours.';
      case 'APPROVED':
        return 'Claim approved! Payout is being processed to your registered account.';
      case 'PAID':
        return 'Claim settled in full. The amount has been paid out to your account.';
      default:
        return 'Claim received. Our adjuster will start the review shortly - no paperwork needed from your side.';
    }
  }

  Widget _stage(
    AppColorsExtension colors,
    String label,
    bool done,
    int index,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: done ? colors.success : colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check_rounded, size: 18, color: colors.onPrimary)
                  : Text(
                      '${index + 1}',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: done ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: done ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector(AppColorsExtension colors, bool done) {
    return Container(
      width: 24,
      height: 3,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: done ? colors.success : colors.outline,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}
