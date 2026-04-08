import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const Color _defaultUiColor = Colors.white;
  static const List<Color> _colorOptions = <Color>[
    Color(0xFFFFCDD2),
    Color(0xFFFFE0B2),
    Color(0xFFFFF9C4),
    Color(0xFFC8E6C9),
    Color(0xFFB2EBF2),
    Color(0xFFC5CAE9),
    Color(0xFFD1C4E9),
    Color(0xFFF8BBD0),
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();

  final RelationStorage _relationStorage = RelationStorage(
    const FlutterSecureStorage(),
  );

  final Map<String, List<_ChatMessage>> _messagesByContact =
      <String, List<_ChatMessage>>{};
  final Map<String, String> _lastIncomingFingerprintByContact =
      <String, String>{};
  final Map<String, Color> _uiColorByContact = <String, Color>{};

  List<RelationSession> _sessions = <RelationSession>[];
  String? _selectedContactId;
  bool _isLoadingSessions = true;
  bool _isSending = false;
  bool _isPolling = false;

  Timer? _incomingPollingTimer;
  Color _selectedColorToSend = _colorOptions.first;

  Map<String, IconData> options = {
    'LINK': Icons.add_link,
    'COLOR': Icons.color_lens,
    'MESSAGE': Icons.message,
  };
  String dropdownValue = 'MESSAGE';

  bool get _isColorMode => dropdownValue == 'COLOR';
  bool get _isLinkMode => dropdownValue == 'LINK';

  Uri? get _currentInputLinkUri =>
      _buildLaunchUri(_messageController.text.trim());

  Color get _activeUiColor {
    final selectedId = _selectedContactId;
    if (selectedId == null) return _defaultUiColor;
    return _uiColorByContact[selectedId] ?? _defaultUiColor;
  }

  /// Gets if the user can send a message (i.e. if the message input is not empty)
  bool get _canSend {
    final text = _messageController.text.trim();
    return !_isLoadingSessions &&
        !_isSending &&
        _selectedSession != null &&
        (_isColorMode || (_isLinkMode ? _currentInputLinkUri != null : text.isNotEmpty));
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

    final String? selectedId =
        active?.myRelationCode ??
        (sessions.isNotEmpty ? sessions.first.myRelationCode : null);

    final Map<String, Color> initialColors = <String, Color>{};
    for (final session in sessions) {
      final colorHex = session.uiColorHex;
      if (colorHex == null || colorHex.isEmpty) continue;
      final parsed = _parseColorFromHex(colorHex);
      if (parsed != null) {
        initialColors[session.myRelationCode] = parsed;
      }
    }

    setState(() {
      _sessions = sessions;
      _selectedContactId = selectedId;
      _uiColorByContact
        ..clear()
        ..addAll(initialColors);
      _isLoadingSessions = false;
    });

    _startPollingForSelectedContact();
  }

  void _startPollingForSelectedContact() {
    _incomingPollingTimer?.cancel();
    _pollIncomingElement();
    _incomingPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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

      if ((key != 'MESSAGE' && key != 'COLOR') || encryptedValue.isEmpty) {
        return;
      }

      final contactId = session.myRelationCode;
      final fingerprint = '$key|$creationDate|$encryptedValue';
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

      Color? colorToPersist;

      setState(() {
        _lastIncomingFingerprintByContact[contactId] = fingerprint;
        if (key == 'COLOR') {
          final Color? parsedColor = _parseColorFromHex(clearText);
          if (parsedColor != null) {
            _uiColorByContact[contactId] = parsedColor;
            colorToPersist = parsedColor;
          }
          return;
        }
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

      if (colorToPersist != null) {
        await _persistUiColorForContact(contactId, colorToPersist!);
        return;
      }

      _scrollToLatestMessage();
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _sendMessage() async {
    final session = _selectedSession;
    final selectedId = _selectedContactId;
    final text = _messageController.text.trim();
    final bool isColorType = dropdownValue == 'COLOR';
    final bool isLinkType = dropdownValue == 'LINK';

    if (session == null || selectedId == null || _isSending) {
      return;
    }

    if (!isColorType && text.isEmpty) {
      return;
    }

    final Uri? linkUri = isLinkType ? _buildLaunchUri(text) : null;
    if (isLinkType && linkUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid link.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final String payload = isColorType
          ? _colorToHex(_selectedColorToSend)
          : (isLinkType ? linkUri.toString() : text);
      final encrypted = rsaEncryptToBase64(
        recipientPublicKeyPem: session.peerPublicKeyPem,
        plaintext: payload,
      );

      // Backend behavior currently expects the peer relation code inbox.
      await ElementService.instance.sendElement(
        relationCode: session.peerRelationCode,
        // LINK still uses MESSAGE to keep receiver compatibility.
        type: isColorType ? 'COLOR' : 'MESSAGE',
        value: encrypted,
      );

      if (!mounted) return;

      setState(() {
        if (isColorType) {
          _uiColorByContact[selectedId] = _selectedColorToSend;
          return;
        }
        _messagesByContact.putIfAbsent(selectedId, () => <_ChatMessage>[]);
        _messagesByContact[selectedId]!.add(
          _ChatMessage(
            contactId: selectedId,
            text: payload,
            timestamp: DateTime.now(),
            isOutgoing: true,
          ),
        );
        _messageController.clear();
      });

      if (!isColorType) {
        _scrollToLatestMessage();
      } else {
        await _persistUiColorForContact(selectedId, _selectedColorToSend);
      }
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

  String _colorToHex(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Uri? _buildLaunchUri(String rawValue) {
    final String value = rawValue.trim();
    if (value.isEmpty) return null;

    final Uri? parsed = Uri.tryParse(value);
    if (parsed == null) return null;

    if (parsed.hasScheme) {
      final String scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return parsed;
      return null;
    }

    if (!value.contains('.')) return null;
    return Uri.tryParse('https://$value');
  }

  Color? _parseColorFromHex(String value) {
    final String normalized = value.trim().replaceFirst('#', '');
    if (normalized.length != 6) return null;
    final int? rgb = int.tryParse(normalized, radix: 16);
    if (rgb == null) return null;
    return Color(0xFF000000 | rgb);
  }

  Future<void> _persistUiColorForContact(String contactId, Color color) async {
    RelationSession? current;
    int currentIndex = -1;
    for (int i = 0; i < _sessions.length; i++) {
      if (_sessions[i].myRelationCode == contactId) {
        current = _sessions[i];
        currentIndex = i;
        break;
      }
    }

    if (current == null) return;

    final updated = current.copyWith(uiColorHex: _colorToHex(color));
    await _relationStorage.upsertSession(updated);

    if (!mounted) return;
    setState(() {
      _sessions[currentIndex] = updated;
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
            const Text('Go back and pair again.', textAlign: TextAlign.center),
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
    return Container(
      color: _activeUiColor,
      child: SizedBox(
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
                await _relationStorage.setActiveRelationCode(
                  session.myRelationCode,
                );
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
      ),
    );
  }

  /// Builds the selected user info
  Widget _buildSelectedUserInfo() {
    final session = _selectedSession;
    final label = session == null ? '-' : session.peerRelationCode;

    return Container(
      color: _activeUiColor,
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

  Widget _buildColorPickerInput() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _colorOptions.map((Color color) {
          final bool isSelected =
              color.toARGB32() == _selectedColorToSend.toARGB32();
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColorToSend = color;
              });
            },
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.black26,
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Builds the message input
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 17, 12, 12),
      decoration: BoxDecoration(color: _activeUiColor),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 40,
            child: DropdownButtonHideUnderline(
              // -- Types selection --
              child: DropdownButton<String>(
                value: dropdownValue,
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() {
                    dropdownValue = value;
                  });
                },
                items: options.entries.map<DropdownMenuItem<String>>((entry) {
                  final String value = entry.key;
                  final IconData icon = entry.value;
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                selectedItemBuilder: (BuildContext context) {
                  return options.keys.map<Widget>((String value) {
                    final icon = options[value]!;
                    return Center(
                      child: Icon(icon, color: Colors.black),
                    );
                  }).toList();
                },
                isExpanded: false,
              ),
            ),
          ),
          Expanded(
            child: _isColorMode
                ? _buildColorPickerInput()
                : TextField(
                    // -- Message input --
                    controller: _messageController,
                    // For security, limits the message length to 200 characters
                    maxLines: 4,
                    minLines: 1,
                    maxLength: _messageMaxLength,
                    textInputAction: TextInputAction.newline,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(_messageMaxLength),
                    ],
                    decoration: InputDecoration(
                      hintText: _isLinkMode
                          ? 'https://example.com'
                          : 'Write something...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      counterText:
                          '${_messageController.text.length} / $_messageMaxLength',
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
    final Uri? linkUri = _tryParseLink(message.text);

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
    final Color timestampColor = message.isOutgoing
        ? Colors.white70
        : Colors.black54;

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
            linkUri == null
                ? Text(
                    message.text,
                    style: TextStyle(fontSize: 16, color: textColor),
                  )
                : GestureDetector(
                    onTap: () => _openLink(context, linkUri),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: message.isOutgoing
                            ? Colors.white
                            : Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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

  Uri? _tryParseLink(String rawValue) {
    final String value = rawValue.trim();
    if (value.isEmpty) return null;

    final Uri? parsed = Uri.tryParse(value);
    if (parsed == null) return null;

    if (parsed.hasScheme) {
      final String scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return parsed;
      return null;
    }

    if (!value.contains('.')) return null;
    return Uri.tryParse('https://$value');
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
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
