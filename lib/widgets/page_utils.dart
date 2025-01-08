import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PageUtils {
  /// Creates a standard card with consistent styling
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double elevation = 4,
    BorderRadiusGeometry borderRadius =
        const BorderRadius.all(Radius.circular(12)),
  }) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(16.0.r),
        child: child,
      ),
    );
  }

  /// Creates a standard search bar with optional onChanged handler
  static Widget buildSearchBar({
    required void Function(String)? onChanged,
    String labelText = 'Search',
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: labelText,
        hintText: 'Enter city or country',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      onChanged: onChanged,
    );
  }

  /// Creates a standard form text field
  static Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    int? maxLines,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        maxLines: maxLines,
      ),
    );
  }

  /// Creates a standard dropdown form field
  static Widget buildDropdownFormField({
    required String labelText,
    required List<String> items,
    required String? value,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      validator: validator,
      onChanged: onChanged,
    );
  }

  /// Creates a standard action button row
  static Widget buildActionButtons({
    required VoidCallback? onAddPressed,
    required VoidCallback? onUpdatePressed,
    required VoidCallback? onDeletePressed,
    required VoidCallback? onCancelPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onAddPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: const Text('Add'),
        ),
        if (onUpdatePressed != null)
          ElevatedButton(
            onPressed: onUpdatePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Update'),
          ),
        if (onDeletePressed != null)
          ElevatedButton(
            onPressed: onDeletePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Delete'),
          ),
        ElevatedButton(
          onPressed: onCancelPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Creates a standard checkbox for agent selection
  static Widget buildAgentSelection({
    required bool value,
    required void Function(bool?)? onChanged,
  }) {
    return Column(
      children: [
        const Divider(),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              shape: const CircleBorder(),
            ),
            const Text('We Have Agent Here'),
          ],
        ),
      ],
    );
  }
  static Widget buildPostSelection({
    required bool value,
    required void Function(bool?)? onChanged,
  }) {
    return Column(
      children: [
        const Divider(),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              shape: const CircleBorder(),
            ),
            const Text('Is Post'),
          ],
        ),
      ],
    );
  }

}
