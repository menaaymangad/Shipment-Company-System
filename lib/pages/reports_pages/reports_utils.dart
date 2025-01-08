import 'package:app/widgets/send_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomAppBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton('Overview', 0),
          SizedBox(width: 16.w),
          _buildTabButton('Reports', 1),
          SizedBox(width: 16.w),
          _buildTabButton('EU Report', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3B82F6).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const TabButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.purple : Colors.transparent,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatsCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 28.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ReportCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  // Constants for styling
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textColor = Color(0xFF2D3748);
  static const Color _hintColor = Color(0xFF94A3B8);
  static const Color _iconColor = Color(0xFF64748B);

  final String label;
  final String? value;
  final List<String> items;
  final Function(String?)? onChanged;
  final bool isRequired;
  final bool enabled;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final double? height;
  final TextStyle? labelStyle;
  final TextStyle? itemStyle;

  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    this.items = const [],
    this.onChanged,
    this.isRequired = true,
    this.enabled = true,
    this.suffixIcon,
    this.validator,
    this.height,
    this.labelStyle,
    this.itemStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the value is valid or set to null
    final validValue = items.contains(value) ? value : null;

    return SizedBox(
      height: height ?? 80.h,
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: labelStyle ??
              TextStyle(
                fontSize: 24.sp,
                color: enabled ? Colors.grey[700] : Colors.grey[500],
              ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.lightGreen,
          border: _buildBorder(enabled: enabled),
          enabledBorder: _buildBorder(enabled: enabled),
          focusedBorder: _buildBorder(
            color: SendUtils.primaryColor,
            width: 2,
          ),
          disabledBorder: _buildBorder(enabled: false),
          suffixIcon: suffixIcon,
        ),
        style: itemStyle ??
            TextStyle(
              fontSize: 24.sp,
              color: enabled ? _textColor : Colors.grey[600],
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
          Icons.keyboard_arrow_down,
          size: 28.sp,
          color: enabled ? _iconColor : Colors.grey[400],
        ),
        dropdownColor: Colors.white,
        alignment: AlignmentDirectional.center,
      ),
    );
  }

  OutlineInputBorder _buildBorder({
    Color? color,
    double width = 1.5,
    bool enabled = true,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color ?? (enabled ? _borderColor : Colors.grey.shade200),
        width: width,
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return _FormField(
      label: label,
      child: SizedBox(
        height: 70.h,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 26.sp,
            color: const Color(0xFF2D3748),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.label,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormField(
      label: label,
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF3B82F6),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        child: Container(
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8.r),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate?.toString().split(' ')[0] ?? 'Select date',
                  style: TextStyle(
                    fontSize: 26.sp,
                    color: selectedDate != null
                        ? const Color(0xFF2D3748)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 24.sp,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

class ButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment alignment;
  final double spacing;

  const ButtonRow({
    super.key,
    required this.buttons,
    this.alignment = MainAxisAlignment.center,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: alignment,
        children: buttons.asMap().entries.map((entry) {
          final isLast = entry.key == buttons.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : spacing),
            child: entry.value,
          );
        }).toList(),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    required this.color,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 12.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 12.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          );

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOutlined ? color : Colors.white,
                ),
              ),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20.sp),
          SizedBox(width: 8.w),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          );
  }
}

