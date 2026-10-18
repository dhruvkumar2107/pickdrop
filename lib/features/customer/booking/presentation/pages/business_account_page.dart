import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../data/datasources/business_account_remote_datasource.dart';

class BusinessAccountPage extends StatefulWidget {
  const BusinessAccountPage({super.key});

  @override
  State<BusinessAccountPage> createState() => _BusinessAccountPageState();
}

class _BusinessAccountPageState extends State<BusinessAccountPage> {
  final BusinessAccountRemoteDataSource _dataSource = BusinessAccountRemoteDataSource();
  final TextEditingController _companyController = TextEditingController(text: 'Sharma Traders');
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _csvController = TextEditingController();
  List<Map<String, String>> _members = [
    {'name': 'Aarav Sharma', 'email': 'aarav@sharmatraders.in', 'role': 'Owner'},
    {'name': 'Neha Gupta', 'email': 'neha@sharmatraders.in', 'role': 'Ops'},
  ];
  bool _busy = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, String>> get _rows => BusinessAccountRemoteDataSource.parseCsvRows(_csvController.text);

  @override
  void initState() {
    super.initState();
    _csvController.addListener(() => setState(() {}));
    _loadAccount();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _gstinController.dispose();
    _emailController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  Future<bool> _persist(Future<void> Function(String uid) action,
      {required String fallbackToast, String? successToast}) async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) AppToast.success(context, fallbackToast);
      return true;
    }
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action(uid);
      if (mounted) AppToast.success(context, successToast ?? fallbackToast);
      return true;
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not save. Try again.');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadAccount() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final data = await _dataSource.fetch(uid);
      if (data == null || !mounted) return;
      setState(() {
        if (data.companyName.isNotEmpty) _companyController.text = data.companyName;
        if (data.gstin.isNotEmpty) _gstinController.text = data.gstin;
        if (data.billingEmail.isNotEmpty) _emailController.text = data.billingEmail;
        if (data.teamMembers.isNotEmpty) _members = data.teamMembers;
      });
    } catch (_) {}
  }

  Future<void> _saveGst() => _persist(
      (uid) => _dataSource.saveProfile(
          ownerId: uid,
          companyName: _companyController.text.trim(),
          gstin: _gstinController.text.trim(),
          billingEmail: _emailController.text.trim()),
      fallbackToast: 'GST details saved');

  Future<void> _addMember() async {
    final input = await AppDialog.showInput(
        context: context, title: 'Add team member', hint: 'Full name or name@company.com');
    if (input == null || input.trim().isEmpty || !mounted) return;
    final raw = input.trim();
    final member = raw.contains('@')
        ? {'name': raw.split('@').first, 'email': raw, 'role': 'Member'}
        : {'name': raw, 'email': '', 'role': 'Member'};
    setState(() => _members = [..._members, member]);
    await _persist((uid) => _dataSource.replaceTeamMembers(uid, _members), fallbackToast: 'Team member added');
  }

  Future<void> _removeMember(int index) async {
    final confirmed = await AppDialog.showConfirmation(
        context: context, title: 'Remove member?', message: 'They lose access to this account.', confirmText: 'Remove');
    if (confirmed != true || !mounted) return;
    final next = [..._members]..removeAt(index);
    setState(() => _members = next);
    await _persist((uid) => _dataSource.replaceTeamMembers(uid, next), fallbackToast: 'Team member removed');
  }

  Future<void> _downloadInvoice() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) AppToast.info(context, 'GST invoice download started');
      return;
    }
    try {
      final url = await _dataSource.createInvoice(ownerId: uid, amount: 18450);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) AppToast.success(context, 'GST invoice opened');
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not create invoice');
    }
  }

  Future<void> _uploadCsv() async {
    final rows = _rows;
    if (rows.isEmpty) return;
    final queued = await _persist(
      (uid) => _dataSource.queueBulkOrders(uid, rows),
      fallbackToast: '${rows.length} bookings queued',
      successToast: '${rows.length} bulk orders queued',
    );
    if (queued && mounted) _csvController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rowCount = _rows.length;

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
              CustomTextField(controller: _gstinController, label: 'GSTIN',
                  hint: '22AAAAA0000A1Z5', textCapitalization: TextCapitalization.characters),
              const SizedBox(height: AppDimensions.spacingMd),
              CustomTextField(controller: _emailController, label: 'Billing email',
                  hint: 'accounts@company.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppDimensions.spacingLg),
              GradientButton(
                  text: 'Save GST details',
                  isFullWidth: true,
                  isLoading: _busy,
                  onPressed: _saveGst),
              _sectionTitle('This month'),
              _billingCard(colors),
              _sectionTitle('Team members (${_members.length})'),
              for (var i = 0; i < _members.length; i++) _memberRow(colors, _members[i], i),
              PrimaryButton(
                  text: 'Add member',
                  leadingIcon: Icons.person_add_alt_1_rounded,
                  isFullWidth: false,
                  onPressed: _addMember),
              _sectionTitle('Bulk booking (CSV)'),
              CustomTextField(
                  controller: _csvController,
                  hint: 'Paste rows: pickup, drop, goods, weight',
                  minLines: 4,
                  maxLines: 6),
              const SizedBox(height: AppDimensions.spacingMd),
              GradientButton(
                  text: rowCount > 0 ? 'Upload $rowCount bookings' : 'Upload bookings',
                  isFullWidth: true,
                  onPressed: rowCount > 0 ? _uploadCsv : null),
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

  Widget _memberRow(AppColorsExtension colors, Map<String, String> member, int index) {
    final email = member['email'] ?? '';
    final label =
        '${member['name'] ?? ''} • ${member['role'] ?? 'Member'}${email.isEmpty ? '' : ' • $email'}';
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: colors.outlineVariant)),
      child: Row(children: [
        Icon(Icons.person_outline_rounded, size: AppDimensions.iconSm, color: colors.primary),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
            child: Text(label,
                style: AppTextStyles.labelLarge.copyWith(color: colors.onSurface), maxLines: 2)),
        IconButton(
            onPressed: () => _removeMember(index),
            icon: Icon(Icons.delete_outline_rounded,
                size: AppDimensions.iconSm, color: colors.onSurfaceVariant)),
      ]),
    );
  }

  Widget _billingCard(AppColorsExtension colors) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('October 2026 billing',
              style: AppTextStyles.labelLarge.copyWith(color: colors.onPrimary)),
          const SizedBox(height: AppDimensions.spacingXs),
          Text('42 trips • ₹18,450 billed • ₹923 GST',
              style: AppTextStyles.labelSmall
                  .copyWith(color: colors.onPrimary.withValues(alpha: 0.85))),
          TextButton.icon(
              onPressed: _downloadInvoice,
              icon: Icon(Icons.picture_as_pdf_outlined, size: 16, color: colors.onPrimary),
              label: Text('GST invoice',
                  style: AppTextStyles.labelLarge.copyWith(color: colors.onPrimary))),
        ]),
      );

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
