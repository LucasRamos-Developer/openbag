import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding/restaurant_onboarding_data.dart';

class OnboardingService {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String draftKey = 'restaurant_onboarding_draft';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Salva o progresso do onboarding localmente
  Future<void> saveDraft(RestaurantOnboardingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data.toJson());
      await prefs.setString(draftKey, jsonString);
    } catch (e) {
      print('Erro ao salvar progresso: $e');
    }
  }

  /// Carrega o progresso salvo do onboarding
  Future<RestaurantOnboardingData?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(draftKey);
      
      if (jsonString != null) {
        final jsonData = json.decode(jsonString);
        return RestaurantOnboardingData.fromJson(jsonData);
      }
      
      return null;
    } catch (e) {
      print('Erro ao carregar progresso: $e');
      return null;
    }
  }

  /// Limpa o progresso salvo
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(draftKey);
    } catch (e) {
      print('Erro ao limpar progresso: $e');
    }
  }

  /// Verifica se existe progresso salvo
  Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(draftKey);
    } catch (e) {
      return false;
    }
  }

  /// Envia o onboarding para o backend
  /// Retorna o restaurantId, slug e message em caso de sucesso
  Future<Map<String, dynamic>> submitOnboarding({
    required RestaurantOnboardingData data,
    String? ownerFullNameOverride,
    String? ownerEmailOverride,
    String? ownerPhoneNumberOverride,
  }) async {
    try {
      // Preparar a parte JSON (data)
      final jsonData = data.toApiJson(
        ownerFullNameOverride: ownerFullNameOverride,
        ownerEmailOverride: ownerEmailOverride,
        ownerPhoneNumberOverride: ownerPhoneNumberOverride,
      );

      // Preparar FormData
      final formData = FormData.fromMap({
        'data': jsonEncode(jsonData),
      });

      // Adicionar logo se existir
      if (data.logoFile != null) {
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(
            data.logoFile!.path,
            filename: 'logo${_getFileExtension(data.logoFile!.path)}',
          ),
        ));
      }

      // Adicionar banner se existir
      if (data.bannerFile != null) {
        formData.files.add(MapEntry(
          'banner',
          await MultipartFile.fromFile(
            data.bannerFile!.path,
            filename: 'banner${_getFileExtension(data.bannerFile!.path)}',
          ),
        ));
      }

      // Enviar requisição
      final response = await _dio.post(
        '$baseUrl/auth/register/restaurant',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'restaurantId': response.data['restaurantId'],
          'slug': response.data['slug'],
          'message': response.data['message'] ?? 'Restaurante cadastrado com sucesso!',
        };
      } else {
        throw Exception('Erro ao cadastrar restaurante: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Tratar erros específicos do Dio
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
                           e.response?.data['error'] ?? 
                           'Erro ao cadastrar restaurante';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
    } catch (e) {
      throw Exception('Erro ao cadastrar restaurante: $e');
    }
  }

  /// Busca informações de endereço por CEP usando ViaCEP
  Future<Map<String, String>?> fetchAddressByCEP(String cep) async {
    try {
      final cleanCEP = cep.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanCEP.length != 8) {
        return null;
      }

      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanCEP/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ViaCEP retorna {"erro": true} se o CEP não existe
        if (data['erro'] == true) {
          return null;
        }

        return {
          'street': data['logradouro'] ?? '',
          'neighborhood': data['bairro'] ?? '',
          'city': data['localidade'] ?? '',
          'state': data['uf'] ?? '',
        };
      }

      return null;
    } catch (e) {
      print('Erro ao buscar CEP: $e');
      return null;
    }
  }

  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }
}
