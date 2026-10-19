import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/common.dart';
import '../../../../auth/data/datasources/driver_remote_datasource.dart';
import '../../../../auth/data/models/user_model.dart';

class DriverOnboardingPage extends ConsumerStatefulWidget {
  const DriverOnboardingPage({super.key});

  @override
  ConsumerState<DriverOnboardingPage> createState() => _DriverOnboardingPageState();
}

class _DriverOnboardingPageState extends ConsumerState<DriverOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicleTypeId;
  String _vehicleNumber = '';
  String _vehicleModel = '';
  String _licenseNumber = '';
  String _rcNumber = '';
  DateTime? _licenseExpiry;
  DateTime? _rcExpiry;

  XFile? _licenseFront;
  XFile? _licenseBack;
  XFile? _rcFront;
  XFile? _rcBack;
  XFile? _aadhaarFront;
  XFile? _aadhaarBack;
  XFile? _driverPhoto;

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _rejectionReason;
  late final Future<List<VehicleTypeModel>> _vehicleTypesFuture;

  static const List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: 'Vehicle Type',
      subtitle: 'Select your vehicle category',
      icon: Icons.directions_car_outlined,
    ),
    _OnboardingStep(
      title: 'Vehicle Details',
      subtitle: 'Enter vehicle number and model',
      icon: Icons.badge_outlined,
    ),
    _OnboardingStep(
      title: 'Documents',
      subtitle: 'Upload required documents',
      icon: Icons.description_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _vehicleTypesFuture = DriverRemoteDataSourceImpl(FirebaseFirestore.instance).getVehicleTypes();
    _loadKycReviewStatus();
  }

  Future<void> _loadKycReviewStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final record = await FirebaseFirestore.instance.collection('driverPrivate').doc(uid).get();
      final data = record.data();
      if (mounted && data?['status'] == 'REJECTED') {
        setState(() => _rejectionReason = (data?['reviewReason'] as String?)?.trim());
      }
    } catch (_) {
      // A first-time application has no private KYC record yet.
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: DesignTokens.durationNormal,
          curve: DesignTokens.springSmooth,
        );
      }
    } else {
      _submitOnboarding();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedVehicleTypeId == null) {
          AppToast.warning(context, 'Please select a vehicle type');
          return false;
        }
        return true;
      case 1:
        if (_vehicleNumber.trim().isEmpty) {
          AppToast.warning(context, 'Please enter vehicle number');
          return false;
        }
        return true;
      case 2:
        if (_licenseFront == null || _licenseBack == null) {
          AppToast.warning(context, 'Please upload driving license (front & back)');
          return false;
        }
        if (_rcFront == null || _rcBack == null) {
          AppToast.warning(context, 'Please upload vehicle RC (front & back)');
          return false;
        }
        if (_aadhaarFront == null || _aadhaarBack == null) {
          AppToast.warning(context, 'Please upload Aadhaar card (front & back)');
          return false;
        }
        if (_driverPhoto == null) {
          AppToast.warning(context, 'Please upload your photo');
          return false;
        }
        if (_licenseNumber.trim().isEmpty || _rcNumber.trim().isEmpty) {
          AppToast.warning(context, 'Enter your license and RC numbers.');
          return false;
        }
        if (_licenseExpiry == null || _rcExpiry == null) {
          AppToast.warning(context, 'Select the expiry dates shown on your license and RC.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickImage(ImageSource source, Function(XFile) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image != null && mounted) {
        onPicked(image);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _pickExpiryDate({required bool license}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: license ? (_licenseExpiry ?? DateTime(now.year + 1, now.month, now.day))
          : (_rcExpiry ?? DateTime(now.year + 1, now.month, now.day)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (license) {
        _licenseExpiry = selected;
      } else {
        _rcExpiry = selected;
      }
    });
  }

  void _showImageSourceDialog(Function(XFile) onPicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PDCard(
        variant: PDCardVariant.elevated,
        padding: EdgeInsets.all(DesignTokens.spacingLg),
        radius: DesignTokens.radiusXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outline,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
            ),
            SizedBox(height: DesignTokens.spacingLg),
            Text('Choose source', style: TokenTextStyles.titleMedium(color: context.colors.onSurface)),
            SizedBox(height: DesignTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: PDButton(
                    text: 'Camera',
                    leadingIcon: Icons.camera_alt_rounded,
                    variant: PDButtonVariant.outline,
                    size: PDButtonSize.md,
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera, onPicked);
                    },
                  ),
                ),
                SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: PDButton(
                    text: 'Gallery',
                    leadingIcon: Icons.photo_library_rounded,
                    variant: PDButtonVariant.primary,
                    size: PDButtonSize.md,
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery, onPicked);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + DesignTokens.spacingLg),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String subtitle,
    required XFile? frontImage,
    required XFile? backImage,
    required Function(XFile) onFrontPicked,
    required Function(XFile) onBackPicked,
    required IconData icon,
  }) {
    return PDCard(
      variant: PDCardVariant.elevated,
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PDCard(
                variant: PDCardVariant.glass,
                padding: EdgeInsets.all(DesignTokens.spacingSm),
                radius: DesignTokens.radiusSm,
                child: Icon(icon, size: DesignTokens.iconSm, color: context.colors.primary),
              ),
              SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TokenTextStyles.titleMedium(color: context.colors.onSurface)),
                    Text(subtitle, style: TokenTextStyles.bodySmall(color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              Expanded(child: _ImageUploadSlot(
                label: 'Front',
                image: frontImage,
                onTap: () => _showImageSourceDialog(onFrontPicked),
              )),
              SizedBox(width: DesignTokens.spacingMd),
              Expanded(child: _ImageUploadSlot(
                label: 'Back',
                image: backImage,
                onTap: () => _showImageSourceDialog(onBackPicked),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _selectedVehicleTypeId == null) {
        throw StateError('Sign in and select a vehicle type before submitting.');
      }
      Future<String> upload(XFile? file, String name) async {
        if (file == null) throw StateError('A required document is missing.');
        final ref = FirebaseStorage.instance.ref('drivers/${user.uid}/$name');
        await ref.putData(await file.readAsBytes(), SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'));
        return ref.getDownloadURL();
      }
      final urls = await Future.wait([
        upload(_licenseFront, 'license_front.jpg'),
        upload(_licenseBack, 'license_back.jpg'),
        upload(_rcFront, 'rc_front.jpg'),
        upload(_rcBack, 'rc_back.jpg'),
        upload(_aadhaarFront, 'aadhaar_front.jpg'),
        upload(_aadhaarBack, 'aadhaar_back.jpg'),
        upload(_driverPhoto, 'profile.jpg'),
      ]);
      await DriverRemoteDataSourceImpl(FirebaseFirestore.instance).createDriverProfile(
        userId: user.uid,
        vehicleTypeId: _selectedVehicleTypeId!,
        vehicleNumber: _vehicleNumber,
        vehicleModel: _vehicleModel.trim().isEmpty ? null : _vehicleModel.trim(),
        licenseNumber: _licenseNumber.trim(),
        licenseExpiry: _licenseExpiry!,
        rcNumber: _rcNumber.trim(),
        rcExpiry: _rcExpiry!,
        aadhaarNumber: '',
        licenseFrontUrl: urls[0],
        licenseBackUrl: urls[1],
        rcFrontUrl: urls[2],
        rcBackUrl: urls[3],
        aadhaarFrontUrl: urls[4],
        aadhaarBackUrl: urls[5],
        photoUrl: urls[6],
      );
      if (!mounted) return;
      AppToast.success(context, 'Documents submitted. Your profile is pending verification.');
      context.go(RouteNames.driverHome);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, 'Could not submit driver documents: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          _buildHeader(context),
          _buildStepIndicator(context),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildVehicleTypeStep(context),
                _buildVehicleDetailsStep(context),
                _buildDocumentsStep(context),
              ],
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        MediaQuery.of(context).padding.top + DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PDCard(
                variant: PDCardVariant.glass,
                padding: EdgeInsets.all(DesignTokens.spacingXs),
                radius: DesignTokens.radiusFull,
                onTap: () => context.go(RouteNames.splash),
                child: Icon(Icons.close_rounded, color: Colors.white, size: DesignTokens.iconMd),
              ),
              SizedBox(width: DesignTokens.spacingSm),
              Expanded(
                child: Text(
                  'Driver Onboarding',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Text(
            'Complete your driver profile to start earning',
            style: TextStyle(
              fontFamily: DesignTokens.fontUI,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: DesignTokens.spacingLg,
      ),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final step = _steps[index];

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index <= _currentStep
                              ? context.colors.primary
                              : context.colors.outline,
                        ),
                      ),
                    AnimatedContainer(
                      duration: DesignTokens.durationNormal,
                      width: isCurrent ? 28 : 22,
                      height: isCurrent ? 28 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted || isCurrent
                            ? AppColors.brandGradient
                            : null,
                        color: isCompleted || isCurrent ? null : context.colors.surfaceVariant,
                        border: Border.all(
                          color: isCompleted || isCurrent
                              ? context.colors.primary
                              : context.colors.outline,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check_rounded, size: 14, color: context.colors.onPrimary)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontUI,
                                  fontSize: isCurrent ? 12 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent ? context.colors.primary : context.colors.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingXs),
                Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontUI,
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent ? context.colors.primary : context.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVehicleTypeStep(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you drive?', style: TokenTextStyles.headlineSmall(color: context.colors.onSurface)),
          SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Choose the vehicle type that matches your vehicle. This determines the trips you\'ll receive.',
            style: TokenTextStyles.bodyMedium(color: context.colors.onSurfaceVariant),
          ),
          SizedBox(height: DesignTokens.spacingXl),
          FutureBuilder<List<VehicleTypeModel>>(
            future: _vehicleTypesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data?.isEmpty != false) {
                return Text(
                  snapshot.hasError ? 'Vehicle options could not be loaded. Please try again later.' : 'No vehicle categories are available yet.',
                  style: TokenTextStyles.bodyMedium(color: context.colors.error),
                );
              }
              final types = snapshot.data!;
              return Column(
                children: types.map((catalogType) {
                  final type = _VehicleType(
                    id: catalogType.id,
                    name: catalogType.name,
                    icon: _vehicleIcon(catalogType.name),
                    capacityKg: catalogType.capacityKg,
                    baseFare: catalogType.baseFare,
                    perKmRate: catalogType.perKmRate,
                    perMinuteRate: catalogType.perMinuteRate,
                  );
                  final isSelected = _selectedVehicleTypeId == type.id;
                  return Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spacingMd),
                    child: _VehicleTypeCard(
                      type: type,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedVehicleTypeId = type.id),
                    ).animate().fadeIn(duration: DesignTokens.durationNormal),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsStep(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle Details', style: TokenTextStyles.headlineSmall(color: context.colors.onSurface)),
            SizedBox(height: DesignTokens.spacingXs),
            Text(
              'Enter your vehicle registration number and model. This will be visible to customers.',
              style: TokenTextStyles.bodyMedium(color: context.colors.onSurfaceVariant),
            ),
            SizedBox(height: DesignTokens.spacingXl),
            PDInput(
              label: 'Vehicle Number',
              hint: 'e.g., MH12 AB 1234',
              controller: TextEditingController(text: _vehicleNumber),
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => _vehicleNumber = v,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            SizedBox(height: DesignTokens.spacingLg),
            PDInput(
              label: 'Vehicle Model (Optional)',
              hint: 'e.g., Tata Intra V30, Ashok Leyland Dost',
              controller: TextEditingController(text: _vehicleModel),
              prefixIcon: const Icon(Icons.directions_car_outlined),
              onChanged: (v) => _vehicleModel = v,
            ),
            SizedBox(height: DesignTokens.spacingLg),
            PDCard(
              variant: PDCardVariant.info,
              padding: EdgeInsets.all(DesignTokens.spacingMd),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: DesignTokens.iconSm, color: context.colors.info),
                  SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Text(
                      'Make sure the vehicle number matches your RC document.',
                      style: TokenTextStyles.bodySmall(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsStep(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_rejectionReason != null) ...[
            PDCard(
              variant: PDCardVariant.elevated,
              padding: EdgeInsets.all(DesignTokens.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: context.colors.error),
                  SizedBox(width: DesignTokens.spacingSm),
                  Expanded(child: Text(
                    'Your previous KYC was rejected. Correct the documents and resubmit.\\n${_rejectionReason!.isEmpty ? 'Please review each document for clarity and validity.' : _rejectionReason}',
                    style: TokenTextStyles.bodyMedium(color: context.colors.onSurface),
                  )),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spacingMd),
          ],
          Text('Upload Documents', style: TokenTextStyles.headlineSmall(color: context.colors.onSurface)),
          SizedBox(height: DesignTokens.spacingXs),
          Text(
            'All documents are required for verification. Photos should be clear and legible.',
            style: TokenTextStyles.bodyMedium(color: context.colors.onSurfaceVariant),
          ),
          SizedBox(height: DesignTokens.spacingXl),
          _buildDocumentUpload(
            title: 'Driving License',
            subtitle: 'Front and back of your valid driving license',
            frontImage: _licenseFront,
            backImage: _licenseBack,
            onFrontPicked: (img) => setState(() => _licenseFront = img),
            onBackPicked: (img) => setState(() => _licenseBack = img),
            icon: Icons.badge_outlined,
          ),
          SizedBox(height: DesignTokens.spacingSm),
          PDInput(
            label: 'Driving license number',
            hint: 'Enter the number shown on your license',
            onChanged: (value) => _licenseNumber = value,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_licenseExpiry == null ? 'Select license expiry date' :
                'License expires ${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}'),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () => _pickExpiryDate(license: true),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          _buildDocumentUpload(
            title: 'Vehicle RC',
            subtitle: 'Front and back of vehicle registration certificate',
            frontImage: _rcFront,
            backImage: _rcBack,
            onFrontPicked: (img) => setState(() => _rcFront = img),
            onBackPicked: (img) => setState(() => _rcBack = img),
            icon: Icons.description_outlined,
          ),
          SizedBox(height: DesignTokens.spacingSm),
          PDInput(
            label: 'Vehicle RC number',
            hint: 'Enter the number shown on the RC',
            onChanged: (value) => _rcNumber = value,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_rcExpiry == null ? 'Select RC expiry date' :
                'RC expires ${_rcExpiry!.day}/${_rcExpiry!.month}/${_rcExpiry!.year}'),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () => _pickExpiryDate(license: false),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          _buildDocumentUpload(
            title: 'Aadhaar Card',
            subtitle: 'Front and back of Aadhaar card for KYC',
            frontImage: _aadhaarFront,
            backImage: _aadhaarBack,
            onFrontPicked: (img) => setState(() => _aadhaarFront = img),
            onBackPicked: (img) => setState(() => _aadhaarBack = img),
            icon: Icons.credit_card_outlined,
          ),
          SizedBox(height: DesignTokens.spacingMd),
          PDCard(
            variant: PDCardVariant.elevated,
            padding: EdgeInsets.all(DesignTokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PDCard(
                      variant: PDCardVariant.glass,
                      padding: EdgeInsets.all(DesignTokens.spacingSm),
                      radius: DesignTokens.radiusSm,
                      child: Icon(Icons.person_outline, size: DesignTokens.iconSm, color: context.colors.primary),
                    ),
                    SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver Photo', style: TokenTextStyles.titleMedium(color: context.colors.onSurface)),
                          Text('Clear face photo for profile', style: TokenTextStyles.bodySmall(color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingLg),
                _ImageUploadSlot(
                  label: 'Photo',
                  image: _driverPhoto,
                  isSquare: true,
                  onTap: () => _showImageSourceDialog((img) => setState(() => _driverPhoto = img)),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spacingLg),
          PDCard(
            variant: PDCardVariant.info,
            padding: EdgeInsets.all(DesignTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: DesignTokens.iconSm, color: context.colors.info),
                    SizedBox(width: DesignTokens.spacingSm),
                    Text('Verification Process', style: TokenTextStyles.labelLarge(color: context.colors.info)),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingSm),
                Text(
                  '• Documents will be verified within 24-48 hours\n• You\'ll receive a notification once approved\n• You can go online only after verification\n• Rejected documents can be re-uploaded',
                  style: TokenTextStyles.bodySmall(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final isLastStep = _currentStep == _steps.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        DesignTokens.spacingMd,
        DesignTokens.spacingLg,
        MediaQuery.of(context).padding.bottom + DesignTokens.spacingLg,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: PDButton(
                text: AppStrings.back,
                leadingIcon: Icons.arrow_back_rounded,
                variant: PDButtonVariant.outline,
                size: PDButtonSize.md,
                onPressed: () => _pageController.previousPage(
                  duration: DesignTokens.durationNormal,
                  curve: DesignTokens.springSmooth,
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: PDButton(
              text: isLastStep ? AppStrings.submit : AppStrings.next,
              trailingIcon: isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
              variant: PDButtonVariant.primary,
              size: PDButtonSize.lg,
              isLoading: _isSubmitting,
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _VehicleTypeCard extends StatelessWidget {
  final _VehicleType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PDCard(
      variant: isSelected ? PDCardVariant.gradient : PDCardVariant.elevated,
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderColor: isSelected ? colors.primary : null,
      showShadow: isSelected,
      boxShadow: isSelected ? [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.3),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ] : null,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingXs),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primaryContainer
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                type.icon,
                size: DesignTokens.iconLg,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: TokenTextStyles.titleLarge(color: colors.onSurface),
                  ),
                  SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    'Capacity: ${type.capacityKg} kg • Base: ₹${type.baseFare.toStringAsFixed(0)}',
                    style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
                  ),
                  SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    '₹${type.perKmRate.toStringAsFixed(0)}/km • ₹${type.perMinuteRate.toStringAsFixed(0)}/min',
                    style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected)
              PDBadge(
                label: 'Selected',
                variant: PDBadgeVariant.primary,
                size: PDBadgeSize.sm,
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleType {
  final String id;
  final String name;
  final IconData icon;
  final int capacityKg;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;

  const _VehicleType({
    required this.id,
    required this.name,
    required this.icon,
    required this.capacityKg,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
  });
}

IconData _vehicleIcon(String name) {
  final value = name.toLowerCase();
  if (value.contains('bike')) return Icons.two_wheeler_rounded;
  if (value.contains('three') || value.contains('auto')) return Icons.local_shipping_rounded;
  return Icons.local_shipping_rounded;
}

class _ImageUploadSlot extends StatelessWidget {
  final String label;
  final XFile? image;
  final VoidCallback onTap;
  final bool isSquare;

  const _ImageUploadSlot({
    required this.label,
    required this.image,
    required this.onTap,
    this.isSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = image != null;
    final size = isSquare ? 120.0 : 100.0;

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          width: double.infinity,
          height: size,
          decoration: BoxDecoration(
            color: hasImage ? null : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: hasImage ? colors.primary : colors.outline,
              width: hasImage ? 2 : 1.5,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(image!.path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: DesignTokens.spacingXs,
                        right: DesignTokens.spacingXs,
                        child: PDCard(
                          variant: PDCardVariant.primary,
                          padding: EdgeInsets.all(DesignTokens.spacingXxs),
                          radius: DesignTokens.radiusFull,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 12,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: DesignTokens.iconLg,
                      color: colors.onSurfaceVariant,
                    ),
                    SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      label,
                      style: TokenTextStyles.titleSmall(color: colors.onSurfaceVariant),
                    ),
                    SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      'Tap to upload',
                      style: TokenTextStyles.labelSmall(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
