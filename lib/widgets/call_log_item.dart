// lib/widgets/call_log_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/call_log_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CallLogItem extends StatelessWidget {
  final CallLogModel callLog;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CallLogItem({
    Key? key,
    required this.callLog,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  IconData _getCallIcon() {
    switch (callLog.callType) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
    }
  }

  Color _getCallColor() {
    switch (callLog.callType) {
      case CallType.incoming:
        return AppColors.callIncoming;
      case CallType.outgoing:
        return AppColors.callOutgoing;
      case CallType.missed:
        return AppColors.callMissed;
    }
  }

  String _getCallTypeText() {
    switch (callLog.callType) {
      case CallType.incoming:
        return 'Incoming';
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Call Type Icon
              CircleAvatar(
                radius: 24,
                backgroundColor: _getCallColor().withOpacity(0.2),
                child: Icon(_getCallIcon(), color: _getCallColor(), size: 24),
              ),
              const SizedBox(width: 12),

              // Call Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      callLog.contactName,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _getCallTypeText(),
                          style: AppStyles.bodySmall.copyWith(
                            color: _getCallColor(),
                          ),
                        ),
                        const Text(' • ', style: AppStyles.bodySmall),
                        Text(
                          Helpers.formatDateTime(callLog.timestamp),
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Duration: ${callLog.formattedDuration}',
                      style: AppStyles.bodySmall,
                    ),
                  ],
                ),
              ),

              // Delete Button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
