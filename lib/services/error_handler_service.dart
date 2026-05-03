import 'package:flutter/foundation.dart';

enum ErrorMessageType { error, success, info }

class ErrorMessage {
  final String message;
  final ErrorMessageType type;
  final Duration duration;

  ErrorMessage({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
  });
}

class ErrorHandlerModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingMessage;
  ErrorMessage? _activeMessage;
  final List<ErrorMessage> _queue = [];

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  ErrorMessage? get activeMessage => _activeMessage;
  String? get currentError => _activeMessage?.type == ErrorMessageType.error ? _activeMessage?.message : null;
  List<ErrorMessage> get errorQueue => [if (_activeMessage != null) _activeMessage!, ..._queue];

  void showError(String message, {Duration? duration}) {
    _enqueue(ErrorMessage(message: message, type: ErrorMessageType.error, duration: duration ?? const Duration(seconds: 3)));
  }

  void showSuccess(String message, {Duration? duration}) {
    _enqueue(ErrorMessage(message: message, type: ErrorMessageType.success, duration: duration ?? const Duration(seconds: 3)));
  }

  void showInfo(String message, {Duration? duration}) {
    _enqueue(ErrorMessage(message: message, type: ErrorMessageType.info, duration: duration ?? const Duration(seconds: 3)));
  }

  void showLoading(String? message) {
    _loadingMessage = message;
    _isLoading = true;
    notifyListeners();
  }

  void hideLoading() {
    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
  }

  void consumeActive() {
    _activeMessage = null;
    if (_queue.isNotEmpty) {
      _activeMessage = _queue.removeAt(0);
    }
    notifyListeners();
  }

  void _enqueue(ErrorMessage message) {
    _queue.add(message);
    if (_activeMessage == null) {
      _activeMessage = _queue.removeAt(0);
    }
    notifyListeners();
  }
}
