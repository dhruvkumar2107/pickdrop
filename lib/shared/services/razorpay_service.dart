import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../config/env/env_config.dart';

const int _paymentCancelledCode = 2; // From Razorpay.PAYMENT_CANCELLED

class RazorpayService {
  late final Razorpay _razorpay;

  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion);

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void setCallbacks({
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  Future<void> openCheckout({
    required double amount,
    required String orderId,
    required String description,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    if (!EnvConfig.isRazorpayConfigured) {
      throw Exception('Razorpay is not configured. Please set RAZORPAY_KEY_ID in .env');
    }

    final options = {
      'key': EnvConfig.razorpayKeyId,
      'amount': (amount * 100).toInt(),
      'currency': 'INR',
      'name': 'PickDrop',
      'description': description,
      'order_id': orderId,
      'prefill': {
        'name': customerName,
        'email': customerEmail,
        'contact': customerPhone,
      },
      'theme': {
        'color': '#FF6B00',
      },
      'modal': {
        'ondismiss': () {
          _onError?.call(PaymentFailureResponse(
            _paymentCancelledCode,
            'Payment cancelled by user',
            <String, dynamic>{},
          ));
        },
      },
    };

    _razorpay.open(options);
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String bookingId,
  }) async {
    try {
      final result = await _functions.httpsCallable('verifyPayment').call({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'bookingId': bookingId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['paid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createOrder(String bookingId) async {
    final result = await _functions.httpsCallable('createRazorpayOrder').call({
      'bookingId': bookingId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> createWalletOrder(int amount) async {
    final result = await _functions.httpsCallable('createWalletTopupOrder').call({'amount': amount});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<bool> verifyWalletPayment({required String orderId, required String paymentId, required String signature}) async {
    try {
      final result = await _functions.httpsCallable('verifyWalletTopup').call({'orderId': orderId, 'paymentId': paymentId, 'signature': signature});
      return (result.data as Map)['paid'] == true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
