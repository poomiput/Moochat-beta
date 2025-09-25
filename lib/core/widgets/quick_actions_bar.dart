import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:easy_localization/easy_localization.dart';

/// Persistent top search and quick actions bar with rounded corners
class QuickActionsBar extends StatelessWidget {
  final String? searchQuery;
  final Function(String)? onSearchChanged;
  final VoidCallback? onScanQR;
  final VoidCallback? onSettings;
  final VoidCallback? onAddContact;

  const QuickActionsBar({
    super.key,
    this.searchQuery,
    this.onSearchChanged,
    this.onScanQR,
    this.onSettings,
    this.onAddContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorsManager.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.strokeColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              style: TextStyle(
                color: ColorsManager.bodyText,
                fontSize: 14.sp,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: context.tr('search...'),
                hintStyle: TextStyle(
                  color: ColorsManager.captionText,
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  Icons.search_outlined,
                  color: ColorsManager.captionText,
                  size: 20.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                isDense: true,
              ),
            ),
          ),

          // Quick action buttons
          SizedBox(width: 8.w),
          _buildActionButton(
            icon: Icons.qr_code_scanner_outlined,
            onTap: onScanQR,
            tooltip: 'Scan QR',
          ),
          SizedBox(width: 4.w),
          _buildActionButton(
            icon: Icons.person_add_outlined,
            onTap: onAddContact,
            tooltip: 'Add Contact',
          ),
          SizedBox(width: 4.w),
          _buildActionButton(
            icon: Icons.more_vert_outlined,
            onTap: onSettings,
            tooltip: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          child: Icon(icon, color: ColorsManager.captionText, size: 20.sp),
        ),
      ),
    );
  }
}
