/// Invites tab content: Invite Sent and Invite Received sections.
/// Frame 53 design: rows with avatar, name, "View Profile" (blue outline) or "Accepted" (filled blue); subtext for Accepted.

import 'package:flutter/material.dart';
import '../../../features/chat/utils/chat_navigation.dart';
import '../../../features/profile/model/request_model.dart';
import '../../theme/app_colors.dart';

class InvitesTabContent extends StatelessWidget {
  final List<RequestListItem> sent;
  final List<RequestListItem> received;
  final void Function(RequestListItem item) onItemTap;

  const InvitesTabContent({
    super.key,
    required this.sent,
    required this.received,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(title: 'Invite Sent', items: sent, onItemTap: onItemTap),
          const SizedBox(height: 24),
          _Section(title: 'Invite Received', items: received, onItemTap: onItemTap),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<RequestListItem> items;
  final void Function(RequestListItem item) onItemTap;

  const _Section({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No ${title.toLowerCase()} yet.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withOpacity(0.7),
              ),
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InviteRow(item: item, onTap: () => onItemTap(item)),
              )),
      ],
    );
  }
}

class _InviteRow extends StatelessWidget {
  final RequestListItem item;
  final VoidCallback onTap;

  const _InviteRow({required this.item, required this.onTap});

  /// True if button text indicates "Accepted" state (show filled blue + subtext).
  bool get _isAccepted {
    final t = item.buttonInfo.text.toLowerCase();
    return t.contains('accept') && !t.contains('view');
  }

  @override
  Widget build(BuildContext context) {
    final name = item.personDetails.fullName.isNotEmpty
        ? item.personDetails.fullName
        : 'Unknown';
    final isAccepted = _isAccepted;
    final canMessage = isChatEligibleRequestStatus(item.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.textDark.withOpacity(0.15),
                    child: Icon(
                      Icons.person,
                      color: AppColors.textDark.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (canMessage) ...[
                    TextButton(
                      onPressed: () => openChatForRequest(context, item.id),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.info,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  _Button(
                    text: item.buttonInfo.text,
                    isAccepted: isAccepted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isAccepted) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Text(
              'Contact details are shared on your WhatsApp',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDark.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Status-only chip (PENDING, View Profile, Accepted, COMPLETED). Not tappable; row tap opens profile.
class _Button extends StatelessWidget {
  final String text;
  final bool isAccepted;

  const _Button({
    required this.text,
    required this.isAccepted,
  });

  @override
  Widget build(BuildContext context) {
    if (isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.info),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.info,
        ),
      ),
    );
  }
}
