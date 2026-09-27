import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/store/store.dart';
import '../../../../services/restaurant_panel_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/location.dart';
import '../../../../utils/maps.dart';
import '../../../../widgets/address/address_form.dart';

/// Loja › Endereço: onde os entregadores retiram os pedidos; as coordenadas definem a distância até os clientes
class AddressTab extends StatefulWidget {
  final Store store;

  const AddressTab({super.key, required this.store});

  @override
  State<AddressTab> createState() => _AddressTabState();
}

class _AddressTabState extends State<AddressTab> {
  final _formKey = GlobalKey<FormState>();
  final _address = AddressFormController();
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.store.address;
    if (a != null) {
      _address.fill({
        'zipCode': a.zipCode,
        'street': a.street,
        'number': a.number,
        'complement': a.complement,
        'neighborhood': a.neighborhood,
        'city': a.city,
        'state': a.state,
      });
      _latitude = a.latitude;
      _longitude = a.longitude;
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  bool get _hasCoordinates => _latitude != null && _longitude != null;

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final position = await currentPosition(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
    });
    if (position != null) {
      AppToast.show(context, message: 'Localização atualizada. Salve para aplicar.', type: ToastType.success);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await runWithFeedback(
      context,
      () => context.read<RestaurantPanelService>().updateAddress({
        ..._address.toJson()..remove('reference'),
        'latitude': _latitude,
        'longitude': _longitude,
      }),
      success: 'Endereço salvo',
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return AppPageListView(
      top: 16,
      children: [
        Form(
          key: _formKey,
          child: AppPanelCard(
            title: 'Endereço da loja',
            subtitle: 'Onde os entregadores retiram os pedidos. Digite o CEP para preencher o resto.',
            child: AddressForm(controller: _address, showReference: false),
          ),
        ),
        const SizedBox(height: 16),
        AppPanelCard(
          title: 'Localização no mapa',
          subtitle: 'Usada para calcular a distância até os clientes e mostrar sua loja em "perto de você"',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_hasCoordinates ? Icons.location_on_rounded : Icons.location_off_outlined,
                        color: _hasCoordinates ? c.primaryText : c.textMuted),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _hasCoordinates
                            ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                            : 'Sem localização: a loja não aparece na busca por proximidade',
                        style: TextStyle(
                          color: _hasCoordinates ? c.text : c.textMuted,
                          fontWeight: _hasCoordinates ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_hasCoordinates)
                      AppButton(
                        text: 'Ver no mapa',
                        icon: Icons.map_outlined,
                        variant: ButtonVariant.text,
                        size: ButtonSize.small,
                        onPressed: () => openDirections(latitude: _latitude, longitude: _longitude),
                      ),
                    AppButton(
                      text: 'Usar minha localização',
                      icon: Icons.my_location_rounded,
                      variant: ButtonVariant.outlined,
                      size: ButtonSize.small,
                      isLoading: _locating,
                      onPressed: _locating ? null : _useMyLocation,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            text: 'Salvar endereço',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }
}
