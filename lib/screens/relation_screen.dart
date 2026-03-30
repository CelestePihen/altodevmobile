import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../crypto/relation_storage.dart';
import '../crypto/rsa_crypto.dart';
import '../models/relation_session.dart';
import '../services/element_service.dart';

// RelationScreen class:
// StatefulWidget means it reacts to an user's taps/inputs
class RelationScreen extends StatefulWidget {
  const RelationScreen({super.key}); // Constructor

  @override
  State<RelationScreen> createState() => _RelationScreenState();
}

// _RelationScreenState class:
// It holds the state of the RelationScreen
class _RelationScreenState extends State<RelationScreen> {
  /// Message length is maxed to 200 characters to ensure security
  static const int _messageMaxLength = 200;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();

  final RelationStorage _relationStorage = RelationStorage(const FlutterSecureStorage());

  final Map<String, List<_ChatMessage>> _messagesByContact =
      <String, List<_ChatMessage>>{};
  final Map<String, String> _lastIncomingFingerprintByContact =
      <String, String>{};

  List<RelationSession> _sessions = <RelationSession>[];
  String? _selectedContactId;
  bool _isLoadingSessions = true;
  bool _isSending = false;
  bool _isPolling = false;

  Timer? _incomingPollingTimer;

  /// Gets if the user can send a message (i.e. if the message input is not empty)
  bool get _canSend {
    return !_isLoadingSessions &&
        !_isSending &&
        _selectedSession != null &&
        _messageController.text.trim().isNotEmpty;
  }

  /// Gets the current selected session
  RelationSession? get _selectedSession {
    final selectedId = _selectedContactId;
    if (selectedId == null) return null;
    for (final session in _sessions) {
      if (session.myRelationCode == selectedId) {
        return session;
      }
    }
    return null;
  }

  /// Gets the list of messages sent to the current selected contact
  List<_ChatMessage> get _selectedMessages {
    final selectedId = _selectedContactId;
    if (selectedId == null) return <_ChatMessage>[];
    return _messagesByContact[selectedId] ?? <_ChatMessage>[];
  }

  // Constructor
  @override
  void initState() {
    super.initState();

    _messageController.addListener(() {
      if (!mounted) return;
      setState(() {
        // Rebuild to enable/disable send button based on current input.
      });
    });

    _loadSessionsAndStart();
  }

  // Destructor:
  @override
  void dispose() {
    _incomingPollingTimer?.cancel();
    _messageController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionsAndStart() async {
    final sessions = await _relationStorage.readAllSessions();
    final active = await _relationStorage.readActiveSession();

    if (!mounted) return;

    final String? selectedId = active?.myRelationCode ??
        (sessions.isNotEmpty ? sessions.first.myRelationCode : null);

    setState(() {
      _sessions = sessions;
      _selectedContactId = selectedId;
      _isLoadingSessions = false;
    });

    _startPollingForSelectedContact();
  }

  void _startPollingForSelectedContact() {
    _incomingPollingTimer?.cancel();
    _pollIncomingElement();
    _incomingPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollIncomingElement();
    });
  }

  Future<void> _pollIncomingElement() async {
    final session = _selectedSession;
    if (!mounted || session == null || _isPolling) return;

    _isPolling = true;
    try {
      final element = await ElementService.instance.getElement(
        relationCode: session.myRelationCode,
      );

      if (!mounted || element.isEmpty) return;

      final key = (element['key'] ?? '').trim().toUpperCase();
      final encryptedValue = (element['value'] ?? '').trim();
      final creationDate = (element['creationDate'] ?? '').trim();

      if (key != 'MESSAGE' || encryptedValue.isEmpty) {
        return;
      }

      final contactId = session.myRelationCode;
      final fingerprint = '$creationDate|$encryptedValue';
      if (_lastIncomingFingerprintByContact[contactId] == fingerprint) {
        return;
      }

      String clearText;
      try {
        clearText = rsaDecryptFromBase64(
          myPrivateKeyPem: session.myPrivateKeyPem,
          ciphertextB64: encryptedValue,
        );
      } catch (_) {
        return;
      }

      setState(() {
        _lastIncomingFingerprintByContact[contactId] = fingerprint;
        _messagesByContact.putIfAbsent(contactId, () => <_ChatMessage>[]);
        _messagesByContact[contactId]!.add(
          _ChatMessage(
            contactId: contactId,
            text: clearText,
            timestamp: DateTime.now(),
            isOutgoing: false,
          ),
        );
      });

      _scrollToLatestMessage();
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _sendMessage() async {
    final session = _selectedSession;
    final selectedId = _selectedContactId;
    final text = _messageController.text.trim();

    if (session == null || selectedId == null || text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final encrypted = rsaEncryptToBase64(
        recipientPublicKeyPem: session.peerPublicKeyPem,
        plaintext: text,
      );

      // Backend behavior currently expects the peer relation code inbox.
      await ElementService.instance.sendElement(
        relationCode: session.peerRelationCode,
        type: 'MESSAGE',
        value: encrypted,
      );

      if (!mounted) return;

      setState(() {
        _messagesByContact.putIfAbsent(selectedId, () => <_ChatMessage>[]);
        _messagesByContact[selectedId]!.add(
          _ChatMessage(
            contactId: selectedId,
            text: text,
            timestamp: DateTime.now(),
            isOutgoing: true,
          ),
        );
        _messageController.clear();
      });

      _scrollToLatestMessage();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Scrolls to the latest message
  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesScrollController.hasClients) {
        return;
      }
      _messagesScrollController.animateTo(
        _messagesScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // Build method:
  // It renders the RelationScreen
  @override
  Widget build(BuildContext context) {
    final List<_ChatMessage> messages = _selectedMessages;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // -- Top --
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: _onBackButtonPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          label: const Text(
            'Go back',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoadingSessions
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? _buildNoSessionState()
                : Column(
                    children: [
                      // -- Contact selector --
                      _buildContactSelector(),
                      // -- Selected user info --
                      _buildSelectedUserInfo(),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.grey.shade100, // Background color
                          child: messages.isEmpty
                              ? const Center(
                                  // If no messages, display a message
                                  child: Text(
                                    'No messages yet. Start the conversation!',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : ListView.builder(
                                  // If messages, display them
                                  controller: _messagesScrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  itemCount: messages.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return _MessageBubble(message: messages[index]);
                                  },
                                ),
                        ),
                      ),
                      // -- Message input --
                      _buildMessageInput(),
                    ],
                  ),
      ),
    );
  }

  void _onBackButtonPressed() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Widget _buildNoSessionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No active relation session found.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Go back and pair again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _onBackButtonPressed,
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the contact selector
  Widget _buildContactSelector() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _sessions.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final session = _sessions[index];
          final bool isSelected = session.myRelationCode == _selectedContactId;

          // When tapped, update the selected contact and scroll to latest message.
          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedContactId = session.myRelationCode;
              });
              await _relationStorage.setActiveRelationCode(session.myRelationCode);
              _startPollingForSelectedContact();
              _scrollToLatestMessage();
            },
            child: CircleAvatar(
              // Updates the newly selected contact's avatar
              radius: isSelected ? 30 : 26,
              backgroundColor: isSelected
                  ? Colors.green.shade500
                  : Colors.grey.shade400,
              child: Icon(
                Icons.person,
                size: isSelected ? 32 : 28,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the selected user info
  Widget _buildSelectedUserInfo() {
    final session = _selectedSession;
    final label = session == null ? '-' : session.peerRelationCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          // Display the currently selected contact's label
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // Builds the message input
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              // -- Message input --
              controller: _messageController,
              // For security, limits the message length to 200 characters
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(_messageMaxLength),
              ],
              decoration: const InputDecoration(
                hintText: 'Write something...',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // -- Send button --
          IconButton(
            // Only can be send if the message input is not empty
            onPressed: _canSend ? _sendMessage : null,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}

// Builds a bubble for each message
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message}); // Constructor

  final _ChatMessage message; // The sent message

  // Build method:
  // It renders the _MessageBubble
  @override
  Widget build(BuildContext context) {
    // Whether the message was sent by the user or the contact
    final Alignment alignment = message.isOutgoing
        ? Alignment.centerRight
        : Alignment
              .centerLeft; // Changes the alignment of the bubble based on the message sender
    final Color bubbleColor = message.isOutgoing
        ? const Color(0xff0d47a1)
        : Colors
              .white; // Changes the color of the bubble based on the message sender

    final Color textColor = message.isOutgoing ? Colors.white : Colors.black;
    final Color timestampColor = message.isOutgoing ? Colors.white70 : Colors.black54;

    return Align(
      alignment: alignment,
      child: Container(
        // -- Message bubble --
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateTime(message.timestamp),
              style: TextStyle(fontSize: 11, color: timestampColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a timestamp into a readable string
  String _formatDateTime(DateTime timestamp) {
    final String day = timestamp.day.toString().padLeft(2, '0');
    final String month = timestamp.month.toString().padLeft(2, '0');
    final String year = timestamp.year.toString();
    final String hour = timestamp.hour.toString().padLeft(2, '0');
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }
}

/// _ChatMessage class:
/// Represents a message sent to a contact.
class _ChatMessage {
  const _ChatMessage({
    required this.contactId,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
  });

  final String contactId;
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
}
