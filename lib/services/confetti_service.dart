// lib/services/confetti_service.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiService extends ChangeNotifier {
  final ConfettiController _controller = ConfettiController(
    duration: const Duration(seconds: 1),
  );

  ConfettiController get controller => _controller;

  void playConfetti() {
    _controller.play();
  }

  // Temizleme metodu
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
