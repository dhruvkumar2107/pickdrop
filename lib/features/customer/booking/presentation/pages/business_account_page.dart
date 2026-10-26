import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../data/datasources/business_account_remote_datasource.dart';

/// GST details plus a statement of the account's real delivered trips.
class BusinessAccountPage extends StatefulWidget {
  const BusinessAccountPage({super.key});

  @override
  State<BusinessAccountPage> createState() => _BusinessAccountPageState();
}

class _BusinessAccountPageState extends State<BusinessAccountPage> {
  final BusinessAccountRemoteDataSource _dataSource = BusinessAccountRemoteDataSource();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _busy = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Future<List<StatementTrip>>? _trips;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    _loadTrips();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _gstinController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final data = await _dataSource.fetch(uid);
      if (data == null || !mounted) return;
      setState(() {
        _companyController.text = data.companyName;
        _gstinController.text = data.gstin;
        _emailController.text = data.billingEmail;
      });
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not load business details.');
    }
  }

  void _loadTrips() {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _trips = _dataSource.deliveredTrips(uid, _month));
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isAfter(DateTime.now())) return;
    _month = next;
    _loadTrips();
  }

  Future<void> _saveGst() async {
    final uid = _uid;
    if (uid == null || _busy) return;
    final company = _companyController.text.trim();
    final gstin = _gstinController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    if (company.isEmpty) {
      AppToast.warning(context, 'Enter your registered business name.');
      return;
    }
    if (gstin.isNotEmpty && !BusinessAccountRemoteDataSource.gstinPattern.hasMatch(gstin)) {
      AppToast.warning(context, 'That GSTIN does not look valid. Check all 15 characters.');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppToast.warning(context, 'Enter a valid billing email.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _dataSource.saveProfile(
        ownerId: uid,
        companyName: company,
        gstin: gstin,
        billingEmail: email,
      );
      _gstinController.text = gstin;
      if (mounted) AppToast.success(context, 'Business details saved');
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareStatement(List<StatementTrip> trips) async {
    final profile = BusinessProfile(
      companyName: _companyController.text.trim(),
      gstin: _gstinController.text.trim(),
      billingEmail: _emailController.text.trim(),
    );
    final csv = BusinessAccountRemoteDataSource.statementCsv(profile, trips);
    final name = 'pickdrop-statement-${_month.year}-${_month.month.toString().padLeft(2, '0')}.csv';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(csv)),
              mimeType: 'text/csv',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          subject: 'PickDrop trip statement',
        ),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not share the statement.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, colors)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.spacingLg, AppDimensions.spacingLg,
                AppDimensions.spacingLg, AppDimensions.spacingXxl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('GST details'),
              CustomTextField(controller: _companyController, label: 'Company name',
                  hint: 'Registered business name', textCapitalization: TextCapitalization.words),
              const SizedBox(height: AppDimensions.spacingMd),
              CustomTextField(controller: _gstinController, label: 'GSTIN (optional)',
                  hint: '22AAAAA0000A1Z5', textCapitalization: TextCapitalization.characters),
              const SizedBox(height: AppDimensions.spacingMd),
              CustomTextField(controller: _emailController, label: 'Billing email (optional)',
                  hint: 'accounts@company.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppDimensions.spacingLg),
              GradientButton(
                  text: 'Save business details',
                  isFullWidth: true,
                  isLoading: _busy,
                  onPressed: _saveGst),
              _sectionTitle('Trip statement'),
              _statementCard(colors),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding:
            const EdgeInsets.only(top: AppDimensions.spacingLg, bottom: AppDimensions.spacingSm),
        child: Text(title, style: AppTextStyles.titleSmall.copyWith(color: context.colors.onSurface)),
      );

  Widget _statementCard(AppColorsExtension colors) {
    final isCurrentMonth =
        _month.year == DateTime.now().year && _month.month == DateTime.now().month;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: FutureBuilder<List<StatementTrip>>(
        future: _trips,
        builder: (context, snapshot) {
          final trips = snapshot.data ?? const <StatementTrip>[];
          final total = trips.fold<double>(0, (sum, t) => sum + t.total);
          final gst = trips.fold<double>(0, (sum, t) => sum + t.gst);
          final summary = snapshot.hasError
              ? 'Could not load trips.'
              : snapshot.connectionState != ConnectionState.done
                  ? 'Loading...'
                  : '${trips.length} ${trips.length == 1 ? 'delivery' : 'deliveries'}'
                      ' • ₹${total.toStringAsFixed(0)} billed • ₹${gst.toStringAsFixed(0)} GST';
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _shiftMonth(-1),
                icon: Icon(Icons.chevron_left_rounded, color: colors.onPrimary),
              ),
              Expanded(
                child: Text('${_monthNames[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(color: colors.onPrimary)),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                icon: Icon(Icons.chevron_right_rounded,
                    color: colors.onPrimary.withValues(alpha: isCurrentMonth ? 0.3 : 1)),
              ),
            ]),
            Text(summary,
                style: AppTextStyles.labelSmall
                    .copyWith(color: colors.onPrimary.withValues(alpha: 0.85))),
            TextButton.icon(
                onPressed: trips.isEmpty ? null : () => _shareStatement(trips),
                icon: Icon(Icons.download_rounded, size: 16, color: colors.onPrimary),
                label: Text('Download statement (CSV)',
                    style: AppTextStyles.labelLarge.copyWith(color: colors.onPrimary))),
          ]);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension colors) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            MediaQuery.of(context).padding.top + AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingXl),
        decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusXl))),
        child: Row(children: [
          IconButtonWidget(
              icon: Icons.arrow_back_rounded,
              color: colors.onPrimary,
              onPressed: () {
                if (mounted) context.pop();
              }),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
              child: Text('Business account',
                  style: AppTextStyles.headlineSmall.copyWith(color: colors.onPrimary))),
        ]),
      );
}
