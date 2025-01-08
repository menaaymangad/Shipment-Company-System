import 'package:flutter/material.dart';

class SendPageLogic {
  static void updateCalculations({
    required Map<String, TextEditingController> controllers,
    required bool isInsuranceEnabled,
  }) {
    // Parse input values
    final realWeight =
        double.tryParse(controllers['weightController']!.text) ?? 0;
    final additionalKg =
        double.tryParse(controllers['additionalKGController']!.text) ?? 0;
    final pricePerKg =
        double.tryParse(controllers['pricePerKgController']!.text) ?? 0;
    final minimumPrice =
        double.tryParse(controllers['minimumPriceController']!.text) ?? 0;
    final insuranceAmount = isInsuranceEnabled
        ? double.tryParse(controllers['insuranceAmountController']!.text) ?? 0
        : 0;
    final boxPackingCost =
        double.tryParse(controllers['boxPackingCostController']!.text) ?? 0;

    // Calculate total weight
    final totalWeight = realWeight + additionalKg;
    controllers['totalWeightController']!.text = totalWeight.toStringAsFixed(2);

    // Calculate shipping cost
    double shippingCost = totalWeight * pricePerKg;
    if (shippingCost < minimumPrice) {
      shippingCost = minimumPrice;
    }

    // Add insurance amount and box packing cost
    double totalPostCost = shippingCost + boxPackingCost;
    if (isInsuranceEnabled) {
      totalPostCost += insuranceAmount;
    }

    // Update the total post cost field
    controllers['totalPostCostController']!.text =
        totalPostCost.toStringAsFixed(2);

    // Update unpaid amounts
    _updateUnpaidAmounts(controllers, totalPostCost);

    // Update Euro amounts
    _updateEuroAmounts(controllers, totalPostCost);
  }

  static void _updateUnpaidAmounts(
      Map<String, TextEditingController> controllers, double totalCost) {
    double paidAmount =
        double.tryParse(controllers['totalPostCostPaidController']!.text) ?? 0;
    controllers['unpaidAmountController']!.text =
        (totalCost - paidAmount).toStringAsFixed(2);
  }

  static void _updateEuroAmounts(
      Map<String, TextEditingController> controllers, double totalCost) {
    const euroRate = 1.309;
    controllers['totalCostEurController']!.text =
        (totalCost / euroRate).toStringAsFixed(2);
  }
}
