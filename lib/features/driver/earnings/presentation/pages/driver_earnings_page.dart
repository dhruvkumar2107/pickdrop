import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../widgets/incentives_section.dart';
import '../widgets/ledger_section.dart';

class DriverEarningsPage extends StatefulWidget {
  const DriverEarningsPage({super.key});

  @override
  State<DriverEarningsPage> createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends State<DriverEarningsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  double _todayEarnings = 0;
  final double _dailyGoal = 2000;
  int _weeklyTrips = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<BarChartGroupData> _barGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLedger();
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  Future<void> _loadLedger() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('driverLedger')
          .where('driverId', isEqualTo: uid)
          .get();
      final now = DateTime.now();
      final days = List<double>.filled(7, 0);
      final rows = <Map<String, dynamic>>[];
      var today = 0.0;
      var weeklyTrips = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final net = (data['net'] as num? ?? 0).toDouble();
        final timestamp = data['createdAt'];
        final date = timestamp is Timestamp ? timestamp.toDate() : now;
        final age = DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(date.year, date.month, date.day)).inDays;
        if (age == 0) today += net;
        if (age >= 0 && age < 7) {
          days[6 - age] += net;
          weeklyTrips++;
        }
        rows.add({
          'id': doc.id,
          'amount': net,
          'time':
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          'from': 'Completed delivery',
          'to':
              'Booking ${doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)}',
        });
      }
      rows.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));
      if (!mounted) return;
      setState(() {
        _todayEarnings = today;
        _weeklyTrips = weeklyTrips;
        _transactions = rows;
        _barGroups = [
          for (var i = 0; i < 7; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i],
                  color: i == 6
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFFFF9A3C),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalProgress = (_todayEarnings / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF14161A),
      body: CustomScrollView(
        slivers: [
          // Gradient earnings header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppDimensions.spacingXl,
                MediaQuery.of(context).padding.top + AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                AppDimensions.spacingXxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BackButton(color: Colors.white),
                      Text(
                        'Earnings',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  Text(
                    'Today\'s Earnings',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '₹${_todayEarnings.toStringAsFixed(0)}',
                    style: AppTextStyles.priceLarge.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  // Goal progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Goal',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '₹${_todayEarnings.toStringAsFixed(0)} / ₹${_dailyGoal.toStringAsFixed(0)}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        child: LinearProgressIndicator(
                          value: goalProgress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white54,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.labelLarge,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'This Week'),
                  Tab(text: 'This Month'),
                ],
              ),
            ),
          ),

          // Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTab == 0
                        ? 'Hourly Breakdown'
                        : _selectedTab == 1
                        ? 'Daily Breakdown'
                        : 'Weekly Breakdown',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        barGroups: _barGroups,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                const days = [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S',
                                ];
                                return Text(
                                  days[value.toInt()],
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        maxY: 2500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXl,
              ),
              child: Row(
                children: [
                  _EarningStat(
                    label: 'Trips',
                    value: '${_transactions.length}',
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  _EarningStat(
                    label: 'Avg / Trip',
                    value:
                        '₹${_transactions.isEmpty ? '0' : (_transactions.fold<double>(0, (running, item) => running + (item['amount'] as num).toDouble()) / _transactions.length).toStringAsFixed(0)}',
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  const _EarningStat(label: 'Rating', value: 'See profile'),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                0,
              ),
              child: GradientButton(
                text: 'Withdraw instantly',
                leadingIcon: Icons.bolt_rounded,
                gradient: AppColors.driverGradient,
                onPressed: () => context.go(RouteNames.driverPayouts),
              ),
            ),
          ),

          // Transactions header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
              ),
              child: Text(
                'Recent Trips',
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
              ),
            ),
          ),

          // Transaction list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Completed trips will appear here.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }
                final tx = _transactions[i];
                return _TransactionTile(tx: tx)
                    .animate(delay: Duration(milliseconds: i * 80))
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0);
              },
              childCount: _loading || _transactions.isEmpty
                  ? 1
                  : _transactions.length,
            ),
          ),

          SliverToBoxAdapter(
            child: Theme(
              data: AppTheme.darkTheme,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXl,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LedgerSection(),
                    const SizedBox(height: AppDimensions.spacingXl),
                    IncentivesSection(weeklyTrips: _weeklyTrips),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;
  const _EarningStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2028),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.spacingXl,
        0,
        AppDimensions.spacingXl,
        AppDimensions.spacingMd,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx['from']} → ${tx['to']}',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tx['id']} · ${tx['time']}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+₹${tx['amount']}',
            style: AppTextStyles.titleMedium.copyWith(
              color: const Color(0xFF22C55E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabDelegate(this.tabBar);

  @override
  Widget build(_, _, _) =>
      Container(color: const Color(0xFF14161A), child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_) => false;
}
