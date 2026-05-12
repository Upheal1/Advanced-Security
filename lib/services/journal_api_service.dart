import 'package:dio/dio.dart';
import '../models/journal_entry.dart';
import '../utils/api_exceptions.dart';
import 'supabase_service.dart';
import 'upheal_api.dart' show uphealBaseUrl;

/// Service for journal API operations.
/// Handles all backend communication for journal entries.
class JournalApiService {
  final Dio _dio;

  JournalApiService({Dio? dio}) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: uphealBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    // Attach Supabase JWT on every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SupabaseService.idToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  /// Save a journal entry to the backend
  Future<void> saveEntry(JournalEntry entry) async {
    try {
      await _dio.post(
        '/api/journal',
        data: entry.toJson(),
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Get all journal entries from backend
  Future<List<JournalEntry>> getEntries() async {
    try {
      final response = await _dio.get('/api/journal');
      // Backend returns JournalListResponse: {"entries": [...], "total_count": ..., ...}
      final data = response.data;
      List<dynamic>? list;
      if (data is Map<String, dynamic>) {
        list = data['entries'] as List<dynamic>?;
      } else if (data is List) {
        list = data;
      }
      return (list ?? [])
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    }
  }

  /// Get a journal entry by date (fetches all and filters client-side —
  /// backend has no date query param)
  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    try {
      final entries = await getEntries();
      final dateOnly = DateTime(date.year, date.month, date.day);
      return entries.firstWhere(
        (e) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          return d == dateOnly;
        },
        orElse: () => throw NotFoundException('No entry for $dateOnly'),
      );
    } on NotFoundException {
      return null;
    }
  }

  /// Get entries within a date range (filters client-side)
  Future<List<JournalEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    final entries = await getEntries();
    return entries.where((e) {
      return !e.date.isBefore(start) && !e.date.isAfter(end);
    }).toList();
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String id) async {
    try {
      await _dio.delete('/api/journal/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw NetworkException();
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 0;
      final message = e.response!.data?['message'] ?? e.message ?? 'API error';

      switch (statusCode) {
        case 401:
          throw UnauthorizedException(message);
        case 404:
          throw NotFoundException(message);
        case 500:
        case 502:
        case 503:
          throw ServerException(message);
        default:
          throw ApiException(message, statusCode);
      }
    }

    throw NetworkException();
  }
}

