import 'package:app/pages/main_pages/send_page/id_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendUtils {
  // Custom color palette for consistent design
  static final Color primaryColor = const Color(0xFF2C3E50);
  static final Color secondaryColor = const Color(0xFF34495E);
  static final Color _lightGreyColor = const Color(0xFFF4F6F7);
  static final Color _textColorLight = const Color(0xFF4A4A4A);

  /// Builds a card with enhanced styling and optional title
  static Widget buildCard({
    String? title,
    required Widget child,
    double? height,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(20.r),
        child: Center(child: child),
      ),
    );
  }

  /// Builds an input row with icon and child widget
  static Widget buildInputRow({
    IconData? icon,
    required Widget child,
    Color? iconColor,
    bool isIconButton =
        false, // Add this parameter to toggle between Icon and IconButton
    VoidCallback? onIconPressed,
    // Add this parameter for IconButton's onPressed
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) // Only add the icon if it's provided
            isIconButton
                ? IconButton(
                    icon: Icon(
                      icon,
                      size: 40.h,
                      color: iconColor ?? secondaryColor,
                    ),
                    onPressed: onIconPressed, // Handle the icon button press
                  )
                : Icon(
                    icon,
                    size: 40.h,
                    color: iconColor ?? secondaryColor,
                  ),
          if (icon != null)
            SizedBox(width: 12.w), // Add spacing only if icon is present
          Expanded(child: child),
        ],
      ),
    );
  }

  static Widget buildIdInputRow({
    IconData? icon,
    required Widget child,
    Color? iconColor,
    bool isIconButton =
        false, // Add this parameter to toggle between Icon and IconButton
    VoidCallback? onIconPressed,
    required Function(IdType) onTypeSelected,
    IdType? currentType, // Add this parameter for IconButton's onPressed
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IdTypeSelector(
            currentType: currentType,
            onTypeSelected: onTypeSelected,
          ),
          SizedBox(width: 12.w), // Add spacing only if icon is present
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Builds a custom text field with enhanced styling
  static Widget buildTextField({
    required String hint,
    String? label, // Add a label parameter
    bool optional = false,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    double? height,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      height: height ?? 75.h,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        maxLines: null,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _textColorLight,
          fontSize: 24.sp,
        ),
        decoration: InputDecoration(
          labelText: hint, // Add the label here
          labelStyle: TextStyle(
            color: enabled ? Colors.grey[700] : Colors.grey[500],
            fontSize: 24.sp,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 24.sp,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : _lightGreyColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          suffixText: optional ? 'Optional' : null,
          suffixStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 20.sp,
          ),
        ),
      ),
    );
  }

  static Widget buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool isRequired = true,
    bool enabled = true,
    Widget? suffixIcon,
    double? height,
    String? Function(String?)? validator,
  }) {
    // Ensure the value is valid or set a default value
    final validValue = items.contains(value) ? value : null;

    return SizedBox(
      height: 80.h,
      child: DropdownButtonFormField<String>(
        value: validValue, // Use the valid value
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            fontSize: 24.sp,
            color: enabled ? Colors.grey[700] : Colors.grey[500],
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : _lightGreyColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          suffixIcon: suffixIcon,
        ),
        style: TextStyle(
          fontSize: 24.sp,
          color: enabled ? Colors.black87 : Colors.grey[600],
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24.sp),
            ),
          );
        }).toList(),
        validator: validator ??
            (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return '$label is required';
              }
              return null;
            },
        onChanged: enabled ? onChanged : null,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          size: 30.h,
          color: enabled ? primaryColor : Colors.grey[400],
        ),
        dropdownColor: Colors.white,
        alignment: AlignmentDirectional.center,
      ),
    );
  }
}

class AppTheme {
  // Color Palette
  static const Color primary = Color(0xFF2C3E50);
  static const Color secondary = Color(0xFF34495E);
  static const Color background = Color(0xFFF4F6F7);
  static const Color textDark = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF7A7A7A);

  // Text Styles
  static TextStyle get headingStyle => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: 24.sp,
        color: textDark,
      );

  // Input Decorations
  static InputDecoration textFieldDecoration({
    required String hint,
    bool optional = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 24.sp,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      filled: true,
      fillColor: enabled ? Colors.white : background,
      border: _buildBorder(enabled: enabled),
      enabledBorder: _buildBorder(enabled: enabled),
      focusedBorder: _buildBorder(color: primary, width: 2),
      disabledBorder: _buildBorder(enabled: false),
      suffixText: optional ? 'Optional' : null,
      suffixStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 20.sp,
      ),
      suffixIcon: suffixIcon,
    );
  }

  // Shared Border Style
  static OutlineInputBorder _buildBorder({
    Color? color,
    double width = 1.5,
    bool enabled = true,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color ?? (enabled ? Colors.grey.shade300 : Colors.grey.shade200),
        width: width,
      ),
    );
  }

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 2,
        blurRadius: 5,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Spacing Constants
  static final double verticalSpacing = 10.h;
  static final double horizontalSpacing = 12.w;
  static final double cardPadding = 20.r;
}

// Enhanced Widget Builder Class
class AppWidgets {
  static Widget buildResponsiveCard({
    String? title,
    required Widget child,
    double? height,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: height,
        decoration: AppTheme.cardDecoration.copyWith(
          color: backgroundColor,
        ),
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: AppTheme.headingStyle),
              SizedBox(height: AppTheme.verticalSpacing),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  static Widget buildResponsiveTextField({
    required String hint,
    required TextEditingController controller,
    bool optional = false,
    bool enabled = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    double? height,
  }) {
    return SizedBox(
      height: height ?? 75.h,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        textAlign: TextAlign.center,
        style: AppTheme.bodyStyle,
        decoration: AppTheme.textFieldDecoration(
          hint: hint,
          optional: optional,
          enabled: enabled,
        ),
      ),
    );
  }
}
