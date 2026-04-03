import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// IAP service for ChefStash premium unlock (non-consumable, one-time purchase)
class IAPService {
  static final IAPService instance = IAPService._();
  IAPService._();

  static const String _productID = 'chefstash_premium';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return;

      final Stream<List<PurchaseDetails>> purchaseUpdated =
          InAppPurchase.instance.purchaseStream;

      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: _updateStreamOnDone,
        onError: _updateStreamOnError,
      );

      // Restore previous purchases on init
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Error initializing IAP: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.productID == _productID) {
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _isPremium = true;
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }

  Future<bool> purchase() async {
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return false;

      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails({_productID});

      if (response.productDetails.isEmpty) {
        debugPrint('No product found for $_productID');
        // For testing: allow purchase in debug mode
        if (kDebugMode) {
          _isPremium = true;
          return true;
        }
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );

      if (Platform.isAndroid) {
        return await InAppPurchase.instance.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        return await InAppPurchase.instance.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
      return _isPremium;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  Future<String?> getPriceString() async {
    try {
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails({_productID});

      if (response.productDetails.isEmpty) return '\$19.99';

      return response.productDetails.first.price;
    } catch (e) {
      debugPrint('Error getting price: $e');
      return '\$19.99';
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
