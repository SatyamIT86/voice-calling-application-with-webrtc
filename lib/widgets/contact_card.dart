// lib/widgets/contact_card.dart
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ContactCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContactCard({
    Key? key,
    required this.contact,
    this.onTap,
    this.onCall,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

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
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Helpers.getRandomColor(contact.name),
                child: Text(
                  Helpers.getInitials(contact.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (contact.phone != null)
                      Text(
                        contact.phone!,
                        style: AppStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (contact.email != null)
                      Text(
                        contact.email!,
                        style: AppStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Call Button
              if (onCall != null)
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.callIncoming),
                  onPressed: onCall,
                  tooltip: 'Call',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
