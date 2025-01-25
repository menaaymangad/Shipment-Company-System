import 'package:flutter/material.dart';

class SendPageLogic {
  static void updateCalculations({
    required Map<String, TextEditingController> controllers,
    required bool isInsuranceEnabled,
    required double euroRate,
  }) {
    // Parse input values
    final realWeight =
        double.tryParse(controllers['weightController']!.text) ?? 0;
    final additionalWeight =
        double.tryParse(controllers['additionalKGController']!.text) ?? 0;
    final pricePerKg =
        double.tryParse(controllers['pricePerKgController']!.text) ?? 0;
    final minimumPrice =
        double.tryParse(controllers['minimumPriceController']!.text) ?? 0;
    final goodsValue =
        double.tryParse(controllers['goodsValueController']!.text) ?? 0;
    final insurancePercent =
        double.tryParse(controllers['insurancePercentController']!.text) ?? 0;
    final boxPackingCost =
        double.tryParse(controllers['boxPackingCostController']!.text) ?? 0;
    final discountAmount =
        double.tryParse(controllers['discountAmountController']!.text) ?? 0;
    final customsCost =
        double.tryParse(controllers['customsCostController']!.text) ?? 0;
    final doorToDoorPrice =
        double.tryParse(controllers['doorToDoorPriceController']!.text) ?? 0;

    // Calculate total weight
    final totalWeight = realWeight + additionalWeight;
    controllers['totalWeightController']!.text = totalWeight.toStringAsFixed(2);

    // Calculate insurance amount (if enabled)
    double insuranceAmount = 0;
    if (isInsuranceEnabled) {
      insuranceAmount = (goodsValue * insurancePercent) / 100;
      controllers['insuranceAmountController']!.text =
          insuranceAmount.toStringAsFixed(2);
    } else {
      controllers['insuranceAmountController']!.text = '0.00';
    }

    // Calculate post sub cost (realWeight * pricePerKg)
    double postSubCost = realWeight * pricePerKg;

    // Ensure post sub cost is not less than the minimum price
    if (postSubCost < minimumPrice) {
      postSubCost = minimumPrice;
    }

    // Update the post sub cost in the controller
    controllers['postSubCostController']!.text = postSubCost.toStringAsFixed(2);

    // Round up real weight to the nearest multiple of 10 for door-to-door cost
    final roundedWeight = (realWeight / 10).ceil() * 10;

    // Calculate door-to-door cost (roundedWeight / 10 * doorToDoorPrice)
    final doorToDoorCost = (roundedWeight / 10) * doorToDoorPrice;
    controllers['doorToDoorCostController']!.text =
        doorToDoorCost.toStringAsFixed(2);

    // Calculate total post cost
    double totalPostCost = insuranceAmount +
        customsCost +
        boxPackingCost +
        doorToDoorCost +
        postSubCost - // Use the updated post sub cost here
        discountAmount;
    controllers['totalPostCostController']!.text =
        totalPostCost.toStringAsFixed(2);

    // Update unpaid amounts
    final totalPostCostPaid = double.tryParse(
            controllers['totalPostCostPaidController']?.text ?? '0') ??
        0;
    final unpaidAmount = totalPostCost - totalPostCostPaid;
    controllers['unpaidAmountController']!.text =
        unpaidAmount.toStringAsFixed(2);

    // Update Euro amounts
    if (euroRate > 0) {
      // Calculate total cost in EUR and round to 2 decimal places
      final totalCostEur = (totalPostCost / euroRate).toStringAsFixed(2);
      controllers['totalCostEurController']!.text = totalCostEur;

      // Calculate unpaid amount in EUR and round to 2 decimal places
      final unpaidEurCost = (unpaidAmount / euroRate).toStringAsFixed(2);
      controllers['unpaidEurCostController']!.text = unpaidEurCost;
    } else {
      controllers['totalCostEurController']!.text = '0.00';
      controllers['unpaidEurCostController']!.text = '0.00';
    }
  }
}
