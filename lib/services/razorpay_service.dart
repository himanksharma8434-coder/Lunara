import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lunara/services/plus_service.dart';

class RazorpayService {
  static final RazorpayService instance = RazorpayService._();
  RazorpayService._();

  late Razorpay _razorpay;
  bool _isInitialized = false;

  // We need to return the success state to the caller, so we use a Completer
  // or a callback. Let's use a simple callback for the active checkout.
  void Function(bool success)? _onPaymentCompletion;

  void init() {
    if (_isInitialized) return;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _isInitialized = true;
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<bool> startPayment({
    required int amountInPaise,
    required String name,
    required String description,
    required String contact,
    required String email,
  }) async {
    if (!_isInitialized) {
      debugPrint('RazorpayService not initialized.');
      return false;
    }

    final keyId = dotenv.env['RAZORPAY_KEY_ID'];
    if (keyId == null || keyId.isEmpty) {
      debugPrint('RAZORPAY_KEY_ID not found in .env');
      return false;
    }

    var options = {
      'key': keyId,
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'theme': {
        'color': '#FF8989',
      }
    };

    // We wait for the callback by using a completion callback or just letting the UI handle state via PlusService.
    // Since PlusScreen watches PlusService, we don't strictly need to await the payment here if the UI updates automatically.
    // But returning a Future<bool> is nice.
    
    // Actually, Razorpay opens a native UI. We will let the event listeners handle the result.
    _razorpay.open(options);
    
    // We cannot easily return a synchronous boolean here because Razorpay SDK is event-based.
    // The PlusScreen UI should just stop loading when PlusService updates, or when it receives an error.
    return true; // Indicates the UI opened successfully.
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    // Unlock Plus Features!
    PlusService.instance.setPlus(true);
    
    if (_onPaymentCompletion != null) {
      _onPaymentCompletion!(true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    if (_onPaymentCompletion != null) {
      _onPaymentCompletion!(false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // Not explicitly handled for success yet
  }

  void setCompletionCallback(void Function(bool) callback) {
    _onPaymentCompletion = callback;
  }
}
