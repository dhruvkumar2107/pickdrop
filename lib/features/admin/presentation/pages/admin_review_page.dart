import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../config/env/env_config.dart';

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});
  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  bool? _isAdmin;
  String? _error;
  bool _busy = false;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion);

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final claims = await user?.getIdTokenResult(true);
      if (mounted) {
        setState(() => _isAdmin = claims?.claims?['role'] == 'admin');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _error = 'Could not verify admin access.';
        });
      }
    }
  }

  Future<void> _review(String callable, Map<String, dynamic> payload) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _functions.httpsCallable(callable).call(payload);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => _error = e.message ?? 'Review action failed.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Review action failed. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _seedDefaults() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _functions
          .httpsCallable('seedBusinessDefaults')
          .call<Map<String, dynamic>>();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Created ${result.data['vehiclesCreated']} missing vehicle types. Review starter prices before launch.',
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.message ?? 'Could not initialize vehicle pricing.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not initialize vehicle pricing. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    await _checkRole();
  }

  Future<void> _editPricing(
    QueryDocumentSnapshot<Map<String, dynamic>> vehicle,
  ) async {
    const keys = ['baseFare', 'perKmRate', 'perMinuteRate', 'minimumFare'];
    final controllers = {
      for (final key in keys)
        key: TextEditingController(text: '${vehicle.data()[key] ?? 0}'),
    };
    final values = await showDialog<Map<String, double>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${vehicle.data()['name'] ?? vehicle.id} prices'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final key in keys)
                TextField(
                  controller: controllers[key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: key),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = <String, double>{};
              for (final key in keys) {
                final value = double.tryParse(controllers[key]!.text.trim());
                if (value == null || value < 0) return;
                parsed[key] = value;
              }
              if (parsed['minimumFare'] == 0) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('Save prices'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (values == null || !mounted) return;
    await _review('updateVehiclePricing', {
      'vehicleTypeId': vehicle.id,
      ...values,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin review')),
        body: Center(child: Text(_error ?? 'Admin custom claim required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin review'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _seedDefaults,
            child: const Text('Initialize catalog'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                _sectionTitle('Starter vehicle prices (INR)'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('vehicleTypes')
                      .where('isActive', isEqualTo: true)
                      .orderBy('sortOrder')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ListTile(
                        title: Text('Could not load the vehicle catalog.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const ListTile(
                        title: Text(
                          'Catalog is empty. Use Initialize catalog first.',
                        ),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        return ListTile(
                          title: Text(data['name'] ?? doc.id),
                          subtitle: Text(
                            'Base ₹${data['baseFare']} • ₹${data['perKmRate']}/km • ₹${data['perMinuteRate']}/min • min ₹${data['minimumFare']}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: _busy ? null : () => _editPricing(doc),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                _sectionTitle('Driver KYC'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('driverPrivate')
                      .where('status', isEqualTo: 'PENDING_REVIEW')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ListTile(
                        title: Text(
                          'Could not load KYC queue. Check admin Firestore rules.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const ListTile(
                        title: Text('No KYC reviews pending.'),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs
                          .map(
                            (doc) => Card(
                              child: ExpansionTile(
                                title: Text('Driver ${doc.id}'),
                                subtitle: Text(
                                  'Submitted ${_date(doc.data()['createdAt'])}',
                                ),
                                children: [
                                  for (final key in [
                                    'licenseFrontUrl',
                                    'licenseBackUrl',
                                    'rcFrontUrl',
                                    'rcBackUrl',
                                    'aadhaarFrontUrl',
                                    'aadhaarBackUrl',
                                  ])
                                    if (doc.data()[key] is String)
                                      ListTile(
                                        title: Text(key),
                                        subtitle: Image.network(
                                          doc.data()[key] as String,
                                          height: 180,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) =>
                                              const Text(
                                                'Document preview unavailable. Check storage access.',
                                              ),
                                        ),
                                      ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _review('reviewDriverKyc', {
                                                'driverId': doc.id,
                                                'decision': 'REJECTED',
                                                'reason': 'Please resubmit clear, valid documents.',
                                              }),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _review('reviewDriverKyc', {
                                                'driverId': doc.id,
                                                'decision': 'APPROVED',
                                              }),
                                        child: const Text('Approve'),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                _sectionTitle('Driver payouts'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('driverPayouts')
                      .where('status', isEqualTo: 'PENDING_REVIEW')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ListTile(
                        title: Text(
                          'Could not load payout queue. Check admin Firestore rules.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const ListTile(
                        title: Text('No payouts pending review.'),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        return Card(
                          child: ListTile(
                            title: Text(
                              '₹${(data['amount'] as num? ?? 0).toStringAsFixed(2)} to ${data['upiId'] ?? ''}',
                            ),
                            subtitle: Text(
                              'Driver ${data['driverId']} • ${_date(data['createdAt'])}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Reject and release balance',
                                  onPressed: _busy
                                      ? null
                                      : () => _review('reviewDriverPayout', {
                                          'payoutId': doc.id,
                                          'decision': 'REJECT',
                                        }),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Approve and send with RazorpayX',
                                  onPressed: _busy
                                      ? null
                                      : () => _review('reviewDriverPayout', {
                                          'payoutId': doc.id,
                                          'decision': 'APPROVE',
                                        }),
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                _sectionTitle('Safety alerts'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('sosAlerts')
                      .where('status', isEqualTo: 'OPEN')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ListTile(
                        title: Text('Could not load safety alerts.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const ListTile(
                        title: Text('No open safety alerts.'),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        final location = data['location'];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${data['role'] == 'driver' ? 'Driver' : 'Customer'} ${data['userId']} • trip ${data['bookingId'] ?? 'not attached'}',
                            ),
                            subtitle: Text(
                              'Created ${_date(data['createdAt'])} • location ${location == null ? 'unavailable' : '${location['latitude']}, ${location['longitude']}'}',
                            ),
                            trailing: TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _review('resolveSosAlert', {
                                      'alertId': doc.id,
                                    }),
                              child: const Text('Resolve'),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                _sectionTitle('Customer reports'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('type', isEqualTo: 'EXTRA_CASH')
                      .where('status', isEqualTo: 'PENDING_REVIEW')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ListTile(
                        title: Text('Could not load customer reports.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const ListTile(
                        title: Text('No customer reports pending.'),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        return Card(
                          child: ListTile(
                            title: Text(
                              'Extra cash: ₹${(data['extraCashAmount'] as num? ?? 0).toStringAsFixed(2)}',
                            ),
                            subtitle: Text(
                              'Booking ${data['bookingId']} • Driver ${data['driverId']}\n${data['reason'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Dismiss report',
                                  onPressed: _busy
                                      ? null
                                      : () => _review('reviewCustomerReport', {
                                          'reportId': doc.id,
                                          'decision': 'DISMISSED',
                                        }),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Resolve report',
                                  onPressed: _busy
                                      ? null
                                      : () => _review('reviewCustomerReport', {
                                          'reportId': doc.id,
                                          'decision': 'RESOLVED',
                                        }),
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                _sectionTitle('Refund requests'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('type', isEqualTo: 'REFUND_REQUEST')
                      .where('status', isEqualTo: 'PENDING_REVIEW')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ListTile(
                        title: Text('Could not load refund requests.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const ListTile(
                        title: Text('No refund requests pending.'),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        final amount = data['requestedAmount'];
                        return Card(
                          child: ListTile(
                            title: Text(
                              'Refund request${amount is num ? ' • ₹${amount.toStringAsFixed(2)}' : ''}',
                            ),
                            subtitle: Text(
                              'Booking ${data['bookingId'] ?? 'not attached'} • User ${data['reporterId']}\n${data['reason'] ?? ''}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
  String _date(dynamic value) => value is Timestamp
      ? value.toDate().toLocal().toString()
      : 'date unavailable';
}
