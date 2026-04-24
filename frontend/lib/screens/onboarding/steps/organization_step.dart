import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/validators.dart';
import '../../../utils/formatters.dart';
import '../../../services/onboarding_service.dart';
import '../../../models/onboarding/opening_hour.dart';
import '../../../widgets/onboarding/opening_hours_item.dart';

/// Step 2: Organização (Restaurante + Endereço + Horários)
class OrganizationStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final ValueChanged<bool Function()>? onValidationCallback;

  const OrganizationStep({
    super.key,
    required this.initialData,
    required this.onDataChanged,
    this.onValidationCallback,
  });

  @override
  State<OrganizationStep> createState() => _OrganizationStepState();
}

class _OrganizationStepState extends State<OrganizationStep> {
  final _formKey = GlobalKey<FormState>();
  final OnboardingService _onboardingService = OnboardingService();

  // Controllers - Restaurante
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _cnpjController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _minimumOrderController;
  late TextEditingController _deliveryTimeController;

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

  // Horários de funcionamento
  List<OpeningHour> _openingHours = [];

  bool _isLoadingCep = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controllers - Restaurante
    _nameController = TextEditingController(text: widget.initialData['restaurantName']);
    _slugController = TextEditingController(text: widget.initialData['restaurantSlug']);
    _descriptionController = TextEditingController(text: widget.initialData['restaurantDescription']);
    _phoneController = TextEditingController(text: widget.initialData['restaurantPhoneNumber']);
    _cnpjController = TextEditingController(text: widget.initialData['restaurantCNPJ']);
    _deliveryFeeController = TextEditingController(
      text: widget.initialData['deliveryFee']?.toString() ?? '',
    );
    _minimumOrderController = TextEditingController(
      text: widget.initialData['minimumOrder']?.toString() ?? '',
    );
    _deliveryTimeController = TextEditingController(
      text: widget.initialData['deliveryTimeMin']?.toString() ?? '',
    );

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

    // Inicializar horários
    if (widget.initialData['openingHours'] != null) {
      _openingHours = (widget.initialData['openingHours'] as List)
          .map((e) => OpeningHour.fromJson(e))
          .toList();
    }

    // Auto-gerar slug ao digitar o nome
    _nameController.addListener(_generateSlug);

    // Registrar callback de validação
    widget.onValidationCallback?.call(validate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _cnpjController.dispose();
    _deliveryFeeController.dispose();
    _minimumOrderController.dispose();
    _deliveryTimeController.dispose();
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    // Validar horários de funcionamento
    if (_openingHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um horário de funcionamento'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    for (final hour in _openingHours) {
      if (!hour.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corrija os horários de funcionamento inválidos'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _generateSlug() {
    if (_nameController.text.isNotEmpty) {
      _slugController.text = slugify(_nameController.text);
      _notifyChanges();
    }
  }

  void _notifyChanges() {
    widget.onDataChanged({
      // Restaurante
      'restaurantName': _nameController.text.trim(),
      'restaurantSlug': _slugController.text.trim(),
      'restaurantDescription': _descriptionController.text.trim(),
      'restaurantPhoneNumber': _phoneController.text.trim(),
      'restaurantCNPJ': _cnpjController.text.trim(),
      'deliveryFee': double.tryParse(_deliveryFeeController.text.replaceAll(',', '.')),
      'minimumOrder': double.tryParse(_minimumOrderController.text.replaceAll(',', '.')),
      'deliveryTimeMin': int.tryParse(_deliveryTimeController.text),
      'deliveryTimeMax': int.tryParse(_deliveryTimeController.text),
      // Endereço
      'addressZipCode': _cepController.text.trim(),
      'addressStreet': _streetController.text.trim(),
      'addressNumber': _numberController.text.trim(),
      'addressComplement': _complementController.text.trim(),
      'addressNeighborhood': _neighborhoodController.text.trim(),
      'addressCity': _cityController.text.trim(),
      'addressState': _stateController.text.trim(),
      'addressLatitude': double.tryParse(_latitudeController.text),
      'addressLongitude': double.tryParse(_longitudeController.text),
      // Horários
      'openingHours': _openingHours.map((h) => h.toJson()).toList(),
    });
  }

  Future<void> _searchCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP inválido')),
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço encontrado!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP: $e')),
      );
    } finally {
      setState(() => _isLoadingCep = false);
    }
  }

  void _addOpeningHour() {
    setState(() {
      _openingHours.add(OpeningHour(
        label: '',
        weekday: 1,
        openTime: '09:00:00',
        closeTime: '18:00:00',
        observation: '',
      ));
      _notifyChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SEÇÃO 1: DADOS DO RESTAURANTE
            _buildSectionHeader('Dados do Restaurante', Icons.restaurant),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do restaurante',
                hintText: 'Ex: Pizzaria do João',
                prefixIcon: Icon(Icons.store),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => validateRequired(value, 'Nome do restaurante'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'URL amigável (slug)',
                hintText: 'pizzaria-do-joao',
                prefixIcon: Icon(Icons.link),
                helperText: 'Gerado automaticamente a partir do nome',
              ),
              validator: (value) => validateRequired(value, 'Slug'),
              readOnly: true,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Conte sobre seu restaurante',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => validateRequired(value, 'Descrição'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone do restaurante',
                hintText: '(XX) XXXXX-XXXX',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatterShort],
              validator: (value) => validateRequired(value, 'Telefone'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cnpjController,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                hintText: 'XX.XXX.XXX/XXXX-00',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.text,
              inputFormatters: [CNPJFormatter()],
              validator: validateCNPJ,
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _deliveryFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de entrega',
                      hintText: '0,00',
                      prefixIcon: Icon(Icons.delivery_dining),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyFormatter()],
                    validator: (value) => validateNonNegativeNumber(value, 'Taxa de entrega'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minimumOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Pedido mínimo',
                      hintText: '0,00',
                      prefixIcon: Icon(Icons.shopping_cart),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyFormatter()],
                    validator: (value) => validateNonNegativeNumber(value, 'Pedido mínimo'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _deliveryTimeController,
              decoration: const InputDecoration(
                labelText: 'Tempo de entrega estimado',
                hintText: '30',
                prefixIcon: Icon(Icons.timer),
                suffixText: 'minutos',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [IntegerFormatter()],
              validator: (value) => validatePositiveInteger(value, 'Tempo de entrega'),
              onChanged: (_) => _notifyChanges(),
            ),

            const SizedBox(height: 32),

            // SEÇÃO 2: ENDEREÇO
            _buildSectionHeader('Endereço', Icons.location_on),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepController,
                    decoration: const InputDecoration(
                      labelText: 'CEP',
                      hintText: 'XXXXX-XXX',
                      prefixIcon: Icon(Icons.mail),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [cepFormatter],
                    validator: (value) => validateRequired(value, 'CEP'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoadingCep ? null : _searchCep,
                  icon: _isLoadingCep
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Rua',
                hintText: 'Avenida Paulista',
                prefixIcon: Icon(Icons.streetview),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => validateRequired(value, 'Rua'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      hintText: '123',
                      prefixIcon: Icon(Icons.looks_one),
                    ),
                    validator: (value) => validateRequired(value, 'Número'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _complementController,
                    decoration: const InputDecoration(
                      labelText: 'Complemento',
                      hintText: 'Apto 101',
                      prefixIcon: Icon(Icons.add_home),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _neighborhoodController,
              decoration: const InputDecoration(
                labelText: 'Bairro',
                hintText: 'Centro',
                prefixIcon: Icon(Icons.map),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => validateRequired(value, 'Bairro'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      hintText: 'São Paulo',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => validateRequired(value, 'Cidade'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      hintText: 'SP',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    validator: (value) => validateRequired(value, 'Estado'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Coordenadas (opcional)
            ExpansionTile(
              title: const Text('Coordenadas (opcional)'),
              leading: const Icon(Icons.my_location),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: '-23.550520',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        onChanged: (_) => _notifyChanges(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: '-46.633308',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        onChanged: (_) => _notifyChanges(),
                      ),
                      const SizedBox(height: 16),
                      if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty)
                        _buildMapPreview(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // SEÇÃO 3: HORÁRIOS DE FUNCIONAMENTO
            _buildSectionHeader('Horários de Funcionamento', Icons.schedule),
            const SizedBox(height: 16),

            ..._openingHours.asMap().entries.map((entry) {
              final index = entry.key;
              final hour = entry.value;
              return OpeningHoursItem(
                key: ValueKey(index),
                hour: hour,
                onRemove: () {
                  setState(() {
                    _openingHours.removeAt(index);
                    _notifyChanges();
                  });
                },
                onChanged: (updatedHour) {
                  setState(() {
                    _openingHours[index] = updatedHour;
                    _notifyChanges();
                  });
                },
              );
            }).toList(),

            OutlinedButton.icon(
              onPressed: _addOpeningHour,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar horário'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    final lat = double.tryParse(_latitudeController.text);
    final lng = double.tryParse(_longitudeController.text);

    if (lat == null || lng == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.openbag.frontend',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
