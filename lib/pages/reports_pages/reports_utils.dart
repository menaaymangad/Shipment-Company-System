// Reusable Components

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

class StatsGridView extends StatelessWidget {
  const StatsGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16.w,
      crossAxisSpacing: 16.w,
      childAspectRatio: 2,
      children: const [
        StatsCard(
          value: '1,235',
          label: 'Total Codes',
          color: Colors.purple,
        ),
        StatsCard(
          value: '2,425',
          label: 'Total Boxes',
          color: Colors.cyan,
        ),
        StatsCard(
          value: '0',
          label: 'Total Pallets',
          color: Colors.orange,
        ),
        StatsCard(
          value: '37,350.25',
          label: 'Total KG',
          color: Colors.blue,
        ),
      ],
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
  final String label;
  final String? helper;
  final List<String> items;

  const CustomDropdown({
    super.key,
    required this.label,
    this.helper,
    this.items = const [], // Default empty list for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    return _FormField(
      label: label,
      helper: helper,
      child: Container(
        height: 70.h,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.white,
        ),
        child: DropdownButtonFormField<String>(
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {},
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            border: InputBorder.none,
            hintText: 'Select ${label.toLowerCase()}',
            hintStyle: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 16.sp,
            ),
          ),
          style: TextStyle(
            fontSize: 16.sp,
            color: const Color(0xFF2D3748),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 28.sp,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? helper;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.helper,
    this.controller,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return _FormField(
      label: label,
      helper: helper,
      child: SizedBox(
        height: 70.h,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 16.sp,
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
  final String? helper;
  final DateTime? initialDate;
  final Function(DateTime)? onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.label,
    this.helper,
    this.initialDate,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FormField(
      label: label,
      helper: helper,
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: initialDate ?? DateTime.now(),
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
          if (picked != null && onDateSelected != null) {
            onDateSelected!(picked);
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
                  initialDate?.toString().split(' ')[0] ?? 'Select date',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: initialDate != null
                        ? const Color(0xFF2D3748)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20.sp,
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
  final String? helper;
  final Widget child;

  const _FormField({
    required this.label,
    required this.child,
    this.helper,
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
          if (helper != null) ...[
            SizedBox(height: 4.h),
            Text(
              helper!,
              style: TextStyle(
                fontSize: 24.sp,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
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

class EUCountriesTable extends StatelessWidget {
  const EUCountriesTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Total Codes')),
            DataColumn(label: Text('Total Boxes')),
            DataColumn(label: Text('Total Pallets')),
            DataColumn(label: Text('Total KG')),
            DataColumn(label: Text('Total Cash in')),
            DataColumn(label: Text('Total Commissions')),
            DataColumn(label: Text('Total Paid To company')),
            DataColumn(label: Text('Total Paid in Europe')),
          ],
          rows: [
            'Germany',
            'Netherlands',
            'United Kingdom',
            'Finland',
            'Sweden',
            'Norway',
          ]
              .map((country) => DataRow(
                    cells: List.generate(9,
                        (index) => DataCell(Text(index == 0 ? country : ''))),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
