import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlagUploadWidget extends StatelessWidget {
  final String flagPath;
  final bool isCircular;
  final bool isLoading;
  final Function() onUpload;
  final Function() onDelete;

  const FlagUploadWidget({
    super.key,
    required this.flagPath,
    required this.isCircular,
    required this.isLoading,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCircular ? 'Circular Flag' : 'Square Flag',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: _buildImageContainer(context),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (flagPath.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    iconSize: 30.sp,
                    tooltip: 'Remove image',
                    onPressed: onDelete,
                  ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  color: Theme.of(context).primaryColor,
                  iconSize: 30.sp,
                  tooltip: 'Upload image',
                  onPressed: onUpload,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer(BuildContext context) {
    if (isLoading) {
      return _buildLoadingContainer();
    }

    if (flagPath.isEmpty) {
      return _buildEmptyContainer();
    }

    return _buildImagePreview();
  }

  Widget _buildLoadingContainer() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyContainer() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 32.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 8.h),
          Text(
            'Upload Image',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius:
            isCircular ? BorderRadius.circular(60.r) : BorderRadius.circular(8),
        child: Image.file(
          File(flagPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 24.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
