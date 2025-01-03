import 'package:flutter/material.dart';

class SendPageLogic {
  static void updateCalculations({
    required Map<String, TextEditingController> controllers,
  }) {
    double totalWeight = _calculateTotalWeight(controllers);
    controllers['totalWeightController']!.text = totalWeight.toStringAsFixed(2);

    double insuranceAmount = _calculateInsuranceAmount(controllers);
    controllers['insuranceAmountController']!.text =
        insuranceAmount.toStringAsFixed(2);

    double shippingCost = _calculateShippingCost(totalWeight, controllers);
    controllers['doorToDoorCostController']!.text =
        shippingCost.toStringAsFixed(2);

    double totalCost =
        _calculateTotalCost(controllers, shippingCost, insuranceAmount);
    controllers['totalPostCostController']!.text = totalCost.toStringAsFixed(2);

    _updateUnpaidAmounts(controllers, totalCost);
    _updateEuroAmounts(controllers, totalCost);
  }

  static double _calculateTotalWeight(
      Map<String, TextEditingController> controllers) {
    double weight = double.tryParse(controllers['weightController']!.text) ?? 0;
    double additionalKG =
        double.tryParse(controllers['additionalKGController']!.text) ?? 0;
    return weight + additionalKG; // Add volumetric weight logic if needed
  }

  static double _calculateInsuranceAmount(
      Map<String, TextEditingController> controllers) {
    double goodsValue =
        double.tryParse(controllers['goodsValueController']!.text) ?? 0;
    double insurancePercent =
        double.tryParse(controllers['insurancePercentController']!.text) ?? 0;
    return (goodsValue * insurancePercent) / 100;
  }

  static double _calculateShippingCost(
      double totalWeight, Map<String, TextEditingController> controllers) {
    double pricePerKg =
        double.tryParse(controllers['pricePerKgController']!.text) ?? 0;
    return (totalWeight * pricePerKg).clamp(
        double.tryParse(controllers['minimumPriceController']!.text) ?? 0,
        double.infinity);
  }

  static double _calculateTotalCost(
      Map<String, TextEditingController> controllers,
      double shippingCost,
      double insuranceAmount) {
    // Similar calculations for customs cost, export doc cost, etc.
    return shippingCost + insuranceAmount; // Add other costs
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
