import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/validators.dart';
import '../../../utils/formatters.dart';
import '../../../services/onboarding_service.dart';
import '../../../core/ui/ui.dart';

/// Step 3: Endereço do Restaurante
class AddressStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final ValueChanged<bool Function()>? onValidationCallback;

  const AddressStep({
    super.key,
    required this.initialData,
    required this.onDataChanged,
    this.onValidationCallback,
  });

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  final _formKey = GlobalKey<FormState>();
  final OnboardingService _onboardingService = OnboardingService();

  // Controllers - Endereço
  late TextEditingController _cepController;
  late TextEditingController _streetController;
  late TextEditingController _numberController;
  late TextEditingController _complementController;
  late TextEditingController _neighborhoodController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoadingCep = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controllers - Endereço
    _cepController = TextEditingController(text: widget.initialData['addressZipCode']);
    _streetController = TextEditingController(text: widget.initialData['addressStreet']);
    _numberController = TextEditingController(text: widget.initialData['addressNumber']);
    _complementController = TextEditingController(text: widget.initialData['addressComplement']);
    _neighborhoodController = TextEditingController(text: widget.initialData['addressNeighborhood']);
    _cityController = TextEditingController(text: widget.initialData['addressCity']);
    _stateController = TextEditingController(text: widget.initialData['addressState']);
    _latitudeController = TextEditingController(
      text: widget.initialData['addressLatitude']?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.initialData['addressLongitude']?.toString() ?? '',
    );

    // Registrar callback de validação
    widget.onValidationCallback?.call(validate);
  }

  @override
  void dispose() {
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'addressZipCode': _cepController.text.trim(),
      'addressStreet': _streetController.text.trim(),
      'addressNumber': _numberController.text.trim(),
      'addressComplement': _complementController.text.trim(),
      'addressNeighborhood': _neighborhoodController.text.trim(),
      'addressCity': _cityController.text.trim(),
      'addressState': _stateController.text.trim().toUpperCase(),
      'addressLatitude': _latitudeController.text.isEmpty ? null : double.tryParse(_latitudeController.text),
      'addressLongitude': _longitudeController.text.isEmpty ? null : double.tryParse(_longitudeController.text),
    });
  }

  Future<void> _searchCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      AppToast.show(
        context,
        message: 'CEP inválido',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoadingCep = true);

    try {
      final address = await _onboardingService.fetchAddressByCEP(cep);
      
      if (address != null) {
        _streetController.text = address['street'] ?? '';
        _neighborhoodController.text = address['neighborhood'] ?? '';
        _cityController.text = address['city'] ?? '';
        _stateController.text = address['state'] ?? '';
        _notifyChanges();
        
        if (mounted) {
          AppToast.show(
            context,
            message: 'Endereço encontrado!',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            message: 'CEP não encontrado',
            type: ToastType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Erro ao buscar CEP: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCep = false);
      }
    }
  }

  Future<void> _getLocation() async {
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Serviço de localização desabilitado. Ative nas configurações do navegador.',
            type: ToastType.warning,
          );
        }
        return;
      }

      // Verificar permissão
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppToast.show(
              context,
              message: 'Permissão de localização negada',
              type: ToastType.error,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Permissão de localização permanentemente negada. Ative nas configurações.',
            type: ToastType.error,
          );
        }
        return;
      }

      // Obter localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Preencher campos
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });

      _notifyChanges();

      if (mounted) {
        AppToast.show(
          context,
          message: 'Coordenadas obtidas com sucesso!',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Erro ao obter localização: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Endereço',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Localização do seu estabelecimento',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            // CEP com botão de buscar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cepController,
                    labelText: 'CEP',
                    hintText: 'XXXXX-XXX',
                    variant: TextFieldVariant.filled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [cepFormatter],
                    validator: (value) => validateRequired(value, 'CEP'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48, // Mesma altura do input
                  child: _isLoadingCep
                      ? AppButton(
                          text: 'Buscar',
                          onPressed: null,
                          variant: ButtonVariant.outlined,
                          isLoading: true,
                          borderWidth: 1,
                        )
                      : AppButton(
                          text: 'Buscar',
                          onPressed: _searchCep,
                          variant: ButtonVariant.outlined,
                          icon: Icons.search,
                          borderWidth: 1,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rua e Número (8/10 e 2/10)
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: AppTextField(
                    controller: _streetController,
                    labelText: 'Rua',
                    hintText: 'Avenida Paulista',
                    variant: TextFieldVariant.filled,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => validateRequired(value, 'Rua'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _numberController,
                    labelText: 'Número',
                    hintText: '123',
                    variant: TextFieldVariant.filled,
                    validator: (value) => validateRequired(value, 'Número'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Complemento e Bairro
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _complementController,
                    labelText: 'Complemento',
                    hintText: 'Apto 101',
                    variant: TextFieldVariant.filled,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _neighborhoodController,
                    labelText: 'Bairro',
                    hintText: 'Centro',
                    variant: TextFieldVariant.filled,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => validateRequired(value, 'Bairro'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cidade e Estado
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _cityController,
                    labelText: 'Cidade',
                    hintText: 'São Paulo',
                    variant: TextFieldVariant.filled,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => validateRequired(value, 'Cidade'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: AppTextField(
                    controller: _stateController,
                    labelText: 'UF',
                    hintText: 'SP',
                    variant: TextFieldVariant.filled,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    validator: (value) => validateRequired(value, 'Estado'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Latitude, Longitude e Botão de coordenadas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _latitudeController,
                    labelText: 'Latitude',
                    hintText: '-23.550520',
                    variant: TextFieldVariant.filled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (value) => validateCoordinate(value, 'Latitude'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _longitudeController,
                    labelText: 'Longitude',
                    hintText: '-46.633308',
                    variant: TextFieldVariant.filled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (value) => validateCoordinate(value, 'Longitude'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48, // Mesma altura do input
                  child: AppButton(
                    text: 'Coordenadas',
                    onPressed: _getLocation,
                    variant: ButtonVariant.outlined,
                    icon: Icons.my_location,
                    borderColor: const Color(0xFF00AB55),
                    textColor: const Color(0xFF00AB55),
                    borderWidth: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
