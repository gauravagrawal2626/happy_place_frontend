import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../model/message_model.dart';
import '../repository/chat_exceptions.dart';
import '../repository/chat_repository.dart';
import '../service/ably_chat_service.dart';
import '../utils/message_merge.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherPersonName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  late final AblyChatService _ablyService;

  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  bool _hasMore = true;
  String? _error;
  String? _pendingBody;

  @override
  void initState() {
    super.initState();
    _ablyService = createAblyChatService(context.read<ChatRepository>());
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _messageFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _ablyService.disconnect();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadMessages();
    if (!mounted) return;
    try {
      await _ablyService.connect(
        conversationId: widget.conversationId,
        onMessage: (message) {
          if (!mounted) return;
          setState(() {
            _messages = mergeMessages(_messages, [message]);
          });
          _scrollToBottom();
        },
      );
    } catch (_) {
      // History still usable if Ably fails.
    }
  }

  Future<void> _loadMessages({String? before}) async {
    if (before == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingOlder = true);
    }

    try {
      final response = await context.read<ChatRepository>().getMessages(
            widget.conversationId,
            before: before,
          );
      if (!mounted) return;
      setState(() {
        if (before == null) {
          _messages = response.messages;
          _hasMore = response.messages.length >= 50;
        } else {
          _messages = mergeMessages(response.messages, _messages);
          _hasMore = response.messages.isNotEmpty;
        }
        _loading = false;
        _loadingOlder = false;
      });
      if (before == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } on ChatAccessDeniedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      Navigator.of(context).pop();
    } on ChatNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadingOlder = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _loadingOlder = false;
      });
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingOlder || _messages.isEmpty) return;
    if (_scrollController.position.pixels <= 48) {
      _loadMessages(before: _messages.first.id);
    }
  }

  Future<void> _sendMessage() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _pendingBody = body;
    });
    _textController.clear();

    try {
      final message = await context.read<ChatRepository>().sendMessage(
            widget.conversationId,
            body,
          );
      if (!mounted) return;
      setState(() {
        _messages = mergeMessages(_messages, [message]);
        _pendingBody = null;
      });
      _scrollToBottom();
      _messageFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _textController.text = _pendingBody ?? body);
      _pendingBody = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _messageFocusNode.requestFocus();
    } finally {
      if (mounted && _sending) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String? get _currentUserId {
    final state = context.read<AppBloc>().state;
    if (state is AppAuthenticated) return state.authResponse.userId;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.otherPersonName.isNotEmpty
        ? widget.otherPersonName
        : 'Chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textDark),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loadMessages(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Say hello!',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textDark.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length + (_loadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_loadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final messageIndex = _loadingOlder ? index - 1 : index;
        final message = _messages[messageIndex];
        final isMine = message.senderId == _currentUserId;
        return _MessageBubble(message: message, isMine: isMine);
      },
    );
  }

  Widget _buildInputBar() {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _messageFocusNode,
                  enabled: !_sending,
                  maxLength: 1000,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onTap: () => _messageFocusNode.requestFocus(),
                  decoration: InputDecoration(
                  hintText: 'Type a message...',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                  onSubmitted: _sending ? null : (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.textDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.body,
          style: TextStyle(
            fontSize: 15,
            color: isMine ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
