import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, this.text});
  final String? text;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700.w,
      height: 80.h,
      child: TextField(
        decoration: InputDecoration(
          hintText: text,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
