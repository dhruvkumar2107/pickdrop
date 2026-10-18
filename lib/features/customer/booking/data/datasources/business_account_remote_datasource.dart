import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessAccountSnapshot {
  const BusinessAccountSnapshot({
    this.companyName = '',
    this.gstin = '',
    this.billingEmail = '',
    this.monthlyLimit = 0,
    this.teamMembers = const [],
    this.invoices = const [],
    this.pendingBulkOrders = const [],
  });

  final String companyName;
  final String gstin;
  final String billingEmail;
  final double monthlyLimit;
  final List<Map<String, String>> teamMembers;
  final List<Map<String, String>> invoices;
  final List<Map<String, String>> pendingBulkOrders;

  factory BusinessAccountSnapshot.fromMap(Map<String, dynamic> data) {
    final members = data['teamMembers'];
    final invoices = data['invoices'];
    final pending = data['pendingBulkOrders'];
    final limit = data['monthlyLimit'];
    return BusinessAccountSnapshot(
      companyName: data['companyName'] is String ? data['companyName'] as String : '',
      gstin: data['gstin'] is String ? data['gstin'] as String : '',
      billingEmail:
          data['billingEmail'] is String ? data['billingEmail'] as String : '',
      monthlyLimit: limit is num ? limit.toDouble() : 0,
      teamMembers: members is List
          ? [
              for (final item in members)
                if (item is Map)
                  {
                    'name': '${item['name'] ?? ''}',
                    'email': '${item['email'] ?? ''}',
                    'role': '${item['role'] ?? 'Member'}',
                  },
            ]
          : const [],
      invoices: invoices is List
          ? [
              for (final item in invoices)
                if (item is Map)
                  {
                    'id': '${item['id'] ?? ''}',
                    'month': '${item['month'] ?? ''}',
                    'amount': '${item['amount'] ?? ''}',
                    'status': '${item['status'] ?? ''}',
                    'url': '${item['url'] ?? ''}',
                  },
            ]
          : const [],
      pendingBulkOrders: pending is List
          ? [
              for (final item in pending)
                if (item is Map)
                  {
                    'pickup': '${item['pickup'] ?? ''}',
                    'drop': '${item['drop'] ?? ''}',
                    'goods': '${item['goods'] ?? ''}',
                    'weight': '${item['weight'] ?? ''}',
                    'status': '${item['status'] ?? ''}',
                  },
            ]
          : const [],
    );
  }
}

class BusinessAccountRemoteDataSource {
  static const String collectionName = 'businessAccounts';
  static const String invoiceBaseUrl = 'https://pickdrop.app/invoices/';
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final FirebaseFirestore _firestore;

  BusinessAccountRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static List<Map<String, String>> parseCsvRows(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isNotEmpty && lines.first.toLowerCase().contains('pickup')) {
      lines.removeAt(0);
    }
    final rows = <Map<String, String>>[];
    for (final line in lines) {
      final cells = line.split(',').map((cell) => cell.trim()).toList();
      if (cells.length < 4) continue;
      rows.add({
        'pickup': cells[0],
        'drop': cells[1],
        'goods': cells[2],
        'weight': cells[3],
        'status': 'QUEUED',
      });
    }
    return rows;
  }

  static String invoiceUrlFor(String invoiceId) => '$invoiceBaseUrl$invoiceId';

  DocumentReference<Map<String, dynamic>> _doc(String ownerId) =>
      _firestore.collection(collectionName).doc(ownerId);

  Future<BusinessAccountSnapshot?> fetch(String ownerId) async {
    final doc = await _doc(ownerId).get();
    final data = doc.data();
    if (data == null) return null;
    return BusinessAccountSnapshot.fromMap(data);
  }

  Future<void> saveProfile({
    required String ownerId,
    required String companyName,
    required String gstin,
    required String billingEmail,
    double? monthlyLimit,
  }) async {
    await _doc(ownerId).set(
      {
        'ownerId': ownerId,
        'companyName': companyName,
        'gstin': gstin,
        'billingEmail': billingEmail,
        'monthlyLimit': ?monthlyLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> replaceTeamMembers(
    String ownerId,
    List<Map<String, String>> members,
  ) async {
    await _doc(ownerId).set(
      {
        'ownerId': ownerId,
        'teamMembers': [
          for (final member in members)
            {
              'name': member['name'] ?? '',
              'email': member['email'] ?? '',
              'role': member['role'] ?? 'Member',
            },
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> createInvoice({
    required String ownerId,
    required double amount,
  }) async {
    final now = DateTime.now();
    final id = 'INV${now.millisecondsSinceEpoch}';
    final invoice = {
      'id': id,
      'month': '${_monthNames[now.month - 1]} ${now.year}',
      'amount': amount,
      'status': 'READY',
      'url': invoiceUrlFor(id),
    };
    await _doc(ownerId).set(
      {
        'ownerId': ownerId,
        'invoices': FieldValue.arrayUnion([invoice]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return invoiceUrlFor(id);
  }

  Future<void> queueBulkOrders(
    String ownerId,
    List<Map<String, String>> orders,
  ) async {
    await _doc(ownerId).set(
      {
        'ownerId': ownerId,
        'pendingBulkOrders': FieldValue.arrayUnion(orders),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
