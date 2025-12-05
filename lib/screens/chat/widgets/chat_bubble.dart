import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import 'package:intl/intl.dart';
import 'provider_card_in_chat.dart';
import '../../client/provider_public_profile_screen.dart';
import '../../../models/user_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    // Check if message has tool calls with provider data
    if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
      print('DEBUG: Message has ${message.toolCalls!.length} tool calls');
      for (var t in message.toolCalls!) {
        print(
            'DEBUG: Tool: ${t['name']}, Output Type: ${t['output']?.runtimeType}, Output: ${t['output']}');
      }
    }

    final hasProviderTool = message.toolCalls?.any((tool) =>
            tool['name'] == 'searchProviders' &&
            tool['output'] != null &&
            (tool['output'] is List) &&
            (tool['output'] as List).isNotEmpty) ??
        false;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Text Message Bubble
            if (message.content.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: isUser ? theme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft:
                        isUser ? const Radius.circular(20) : Radius.zero,
                    bottomRight:
                        isUser ? Radius.zero : const Radius.circular(20),
                  ),
                  boxShadow: [
                    if (!isUser)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : Colors.black87,
                        height: 1.4,
                        fontSize: 16.0, // WhatsApp standard size
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[500],
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),

            // Tool Outputs (Provider Cards)
            if (hasProviderTool) ...[
              const SizedBox(height: 8),
              ..._buildProviderCards(context, message.toolCalls!),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProviderCards(
      BuildContext context, List<Map<String, dynamic>> toolCalls) {
    final cards = <Widget>[];

    for (final tool in toolCalls) {
      if (tool['name'] == 'searchProviders' && tool['output'] != null) {
        final providers = tool['output'] as List;
        for (final provider in providers) {
          // Handle both direct provider objects or nested structure depending on tool output
          final data = provider is Map<String, dynamic> ? provider : {};
          if (data.isEmpty) continue;

          cards.add(
            ProviderCardInChat(
              providerId: data['id'] ?? 'unknown',
              name: data['businessName'] ?? 'Unknown Provider',
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              location: data['address'],
              onTap: () {
                // Construct UserModel from provider data
                final providerUser = UserModel(
                  id: data['id'] ?? 'unknown',
                  email: data['email'] ?? '',
                  businessName: data['businessName'] ?? 'Unknown Provider',
                  timezone: 'UTC', // Default
                  createdAt: DateTime.now(), // Default
                  phoneNumber: data['phoneNumber'],
                  location: data['address'] != null
                      ? UserLocation(
                          latitude: 0,
                          longitude: 0,
                          address: data['address'],
                        )
                      : null,
                  specialties: List<String>.from(data['specialties'] ?? []),
                  industries: List<String>.from(data['industries'] ?? []),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProviderPublicProfileScreen(
                      provider: providerUser,
                    ),
                  ),
                );
              },
            ),
          );
        }
      }
    }
    return cards;
  }
}
