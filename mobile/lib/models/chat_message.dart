import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String senderName;
  final Color senderColor;
  final String? senderLogo;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.senderName,
    required this.senderColor,
    this.senderLogo,
  });
}
