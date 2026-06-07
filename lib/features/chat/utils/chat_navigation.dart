import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../repository/chat_exceptions.dart';
import '../repository/chat_repository.dart';

bool isChatEligibleRequestStatus(String status) {
  final normalized = status.toUpperCase();
  return normalized == 'ACCEPTED' || normalized == 'COMPLETED';
}

Future<void> openChatForRequest(BuildContext context, String requestId) async {
  try {
    final conversation =
        await context.read<ChatRepository>().getByRequestId(requestId);
    if (!context.mounted) return;
    final name = Uri.encodeComponent(conversation.otherPerson.fullName);
    context.push('/chat/${conversation.id}?name=$name');
  } on ChatAccessDeniedException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } on ChatNotFoundException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

void openConversation(
  BuildContext context,
  String conversationId,
  String otherPersonName,
) {
  final name = Uri.encodeComponent(otherPersonName);
  context.push('/chat/$conversationId?name=$name');
}
