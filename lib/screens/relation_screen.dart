import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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

  /// MOCK: Simulates a list of contacts to interact with
  final List<_MockContact> _contacts = <_MockContact>[
    const _MockContact(id: 'alice', name: 'Alice'),
    const _MockContact(id: 'bob', name: 'Bob'),
  ];

  /// Maps a contact ID to a list of messages sent to that contact
  /// The 'late' keyword means it will be initialized later
  late final Map<String, List<_MockMessage>> _messagesByContact;
  late String
  _selectedContactId; // For now, we don't know the current selected contact!

  /// Gets if the user can send a message (i.e. if the message input is not empty)
  /// The 'get' keyword means it is a getter anonymous function
  bool get _canSend => _messageController.text.trim().isNotEmpty;

  /// Gets the current selected contact
  _MockContact get _selectedContact =>
      _contacts.firstWhere((contact) => contact.id == _selectedContactId);

  /// Gets the list of messages sent to the current selected contact
  List<_MockMessage> get _selectedMessages =>
      _messagesByContact[_selectedContactId] ?? <_MockMessage>[];

  // Constructor
  @override
  void initState() {
    super.initState();
    _selectedContactId = _contacts
        .first
        .id; // Sets the contact ID to the first contact in the list
    // MOCK: Simulates a list of messages sent to each contact
    _messagesByContact = <String, List<_MockMessage>>{
      'alice': <_MockMessage>[
        _MockMessage(
          contactId: 'alice',
          text: 'This is a test!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
          isOutgoing: false,
        ),
        _MockMessage(
          contactId: 'alice',
          text: 'Sending you an anwser right now.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 36)),
          isOutgoing: true,
        ),
      ],
      'bob': <_MockMessage>[
        _MockMessage(
          contactId: 'bob',
          text: 'Hello, I am using Alto too!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isOutgoing: false,
        ),
      ],
    };

    _messageController.addListener(() {
      setState(() {
        // Rebuild to enable/disable send button based on current input.
      });
    });
  }

  // Destructor:
  @override
  void dispose() {
    _messageController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  // Build method:
  // It renders the RelationScreen
  @override
  Widget build(BuildContext context) {
    final List<_MockMessage> messages = _selectedMessages;

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
        child: Column(
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
    context.pop();
  }

  // Builds the contact selector
  Widget _buildContactSelector() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _MockContact contact = _contacts[index];
          final bool isSelected = contact.id == _selectedContactId;

          // When taped, update the selected contact and scroll to the latest message
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedContactId = contact.id;
              });
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          // Display the currently selected contact's name
          _selectedContact.name,
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
            icon: const Icon(Icons.send),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  /// MOCK: Simulates sending a message
  /// TODO [BACKEND]: Replace with actual message sending
  void _sendMessage() {
    final String text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messagesByContact.putIfAbsent(
        _selectedContactId,
        () => <_MockMessage>[],
      );
      _messagesByContact[_selectedContactId]!.add(
        _MockMessage(
          contactId: _selectedContactId,
          text: text,
          timestamp: DateTime.now(),
          isOutgoing: true,
        ),
      );
      _messageController.clear();
    });

    _scrollToLatestMessage();
  }

  /// Scrolls to the latest message
  /// TODO [BACKEND]: Replace with actual scrolling to the latest message
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
}

// Builds a bubble for each message
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message}); // Constructor

  final _MockMessage message; // The sent message

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
        ? Color(0xff0d47a1)
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

/// Data classes:
///
/// _MockContact class:
/// Represents a mock contact with an ID and a name.
///
/// _MockMessage class:
/// Represents a mock message sent to a contact.
class _MockContact {
  const _MockContact({required this.id, required this.name});

  final String id;
  final String name;
}

class _MockMessage {
  const _MockMessage({
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
