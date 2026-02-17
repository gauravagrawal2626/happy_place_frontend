/// Invites Screen
///
/// Shows sent and received requests from GET /api/requests.
/// Each row is clickable and opens the profile modal (with back button).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/profile_modal.dart';
import '../model/request_model.dart';
import '../repository/requests_repository.dart';

class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> {
  GetRequestsResponse? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<RequestsRepository>();
      final data = await repo.getRequests();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _openProfile(RequestListItem item) {
    final state = context.read<AppBloc>().state;
    if (state is! AppAuthenticated) return;
    final role = state.authResponse.role == 'LISTER'
        ? ProfileModalRole.lister
        : ProfileModalRole.seeker;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileModal(
        args: ProfileModalArgs(
          userId: item.personDetails.userId,
          flatId: item.flatId,
          role: role,
          showBackButton: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Invite sent/accept details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textDark),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.textDark,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section(
                          title: 'Invite Sent',
                          total: _data?.sentTotal ?? 0,
                          items: _data?.sent ?? [],
                        ),
                        const SizedBox(height: 24),
                        _section(
                          title: 'Invite Received',
                          total: _data?.receivedTotal ?? 0,
                          items: _data?.received ?? [],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _section({
    required String title,
    required int total,
    required List<RequestListItem> items,
  }) {
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
        if (total > 0)
          Text(
            '$total ${total == 1 ? 'item' : 'items'}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withOpacity(0.7),
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
                padding: const EdgeInsets.only(bottom: 10),
                child: _requestRow(item),
              )),
      ],
    );
  }

  Widget _requestRow(RequestListItem item) {
    final personName = item.personDetails.fullName.isNotEmpty
        ? item.personDetails.fullName
        : 'Unknown';
    final btn = item.buttonInfo;
    final hasAction = btn.action != null && btn.action!.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openProfile(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  personName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasAction && btn.enabled
                      ? AppColors.textDark.withOpacity(0.08)
                      : AppColors.textDark.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  btn.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasAction && btn.enabled
                        ? AppColors.textDark
                        : AppColors.textDark.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
