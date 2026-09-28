import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Erro de API com a mensagem já pronta para exibir ao usuário
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  @override
  String toString() => message;
}

/// Cliente HTTP autenticado (Dio): injeta o token JWT e converte erros do backend em [ApiException]
class ApiClient {
  final String? Function() _tokenProvider;
  final void Function()? _onUnauthorized;

  late final Dio dio;

  ApiClient({
    required String? Function() tokenProvider,
    void Function()? onUnauthorized,
  })  : _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _tokenProvider();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? data}) => _send(() => dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) => _send(() => dio.put(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) => _send(() => dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _send(() => dio.delete(path));

  /// Baixa um arquivo gerado pelo backend (ex: CSV da lista de associados)
  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await dio.get<List<int>>(path,
          queryParameters: _clean(query), options: Options(responseType: ResponseType.bytes));
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      // O erro também chega em bytes: converte para JSON para aproveitar a mensagem do backend
      final data = e.response?.data;
      if (data is List<int>) {
        try {
          e.response!.data = jsonDecode(utf8.decode(data));
        } catch (_) {}
      }
      throw toApiException(e);
    }
  }

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return Map.fromEntries(query.entries.where((e) => e.value != null && e.value != ''));
  }

  /// Extrai a mensagem de erro do corpo padrão do backend ({message, fieldErrors} ou {error})
  static ApiException toApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException('Erro de conexão. Verifique sua internet e tente novamente.');
    }

    final data = response.data;
    var message = 'Erro inesperado (${response.statusCode})';
    var fieldErrors = <String, String>{};

    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? message).toString();
      if (data['fieldErrors'] is Map) {
        fieldErrors = Map<String, String>.from(
          (data['fieldErrors'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
        if (fieldErrors.isNotEmpty) {
          message = '$message: ${fieldErrors.values.join('; ')}';
        }
      }
    } else if (response.statusCode == 403) {
      message = 'Você não tem permissão para esta ação';
    }

    return ApiException(message, statusCode: response.statusCode, fieldErrors: fieldErrors);
  }
}
