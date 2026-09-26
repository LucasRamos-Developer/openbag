import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/association_summary.dart';
import '../../services/api_client.dart';
import '../../services/courier_service.dart';
import '../association/association_logo.dart';

/// Escolha da associação do entregador: código de convite (entra ativo na hora) ou pedido de entrada
/// em uma associação da lista (fica aguardando aprovação do gestor)
class AssociationPicker extends StatefulWidget {
  final AssociationChoice? value;
  final ValueChanged<AssociationChoice?> onChanged;
  final String? initialInviteCode;

  const AssociationPicker({super.key, required this.value, required this.onChanged, this.initialInviteCode});

  @override
  State<AssociationPicker> createState() => _AssociationPickerState();
}

class _AssociationPickerState extends State<AssociationPicker> {
  late final _code = TextEditingController(text: widget.initialInviteCode);
  late bool _useInvite = true;
  bool _validating = false;
  String? _codeError;
  List<AssociationSummary>? _associations;
  String? _listError;

  @override
  void initState() {
    super.initState();
    if (widget.initialInviteCode?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateCode());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Informe o código');
      return;
    }
    setState(() {
      _validating = true;
      _codeError = null;
    });
    try {
      final association = await context.read<CourierService>().validateInvite(code);
      widget.onChanged(AssociationChoice.invite(code, association));
    } on ApiException catch (e) {
      widget.onChanged(null);
      setState(() => _codeError = e.message);
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  Future<void> _loadAssociations() async {
    setState(() => _listError = null);
    try {
      final list = await context.read<CourierService>().fetchActiveAssociations();
      if (mounted) setState(() => _associations = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _listError = e.message);
    }
  }

  void _switchMode(bool useInvite) {
    setState(() => _useInvite = useInvite);
    widget.onChanged(null);
    if (!useInvite && _associations == null) _loadAssociations();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, icon: Icon(Icons.confirmation_number_outlined), label: Text('Tenho um convite')),
            ButtonSegment(value: false, icon: Icon(Icons.search), label: Text('Escolher associação')),
          ],
          selected: {_useInvite},
          onSelectionChanged: (s) => _switchMode(s.first),
        ),
        const SizedBox(height: 16),
        if (_useInvite) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _code,
                  labelText: 'Código de convite',
                  variant: TextFieldVariant.filled,
                  textCapitalization: TextCapitalization.characters,
                  errorText: _codeError,
                  onSubmitted: (_) => _validateCode(),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppButton(
                  text: 'Validar',
                  variant: ButtonVariant.outlined,
                  isLoading: _validating,
                  onPressed: _validating ? null : _validateCode,
                ),
              ),
            ],
          ),
          if (selected != null && selected.isInvite) ...[
            const SizedBox(height: 12),
            _AssociationTile(association: selected.association, selected: true, onTap: () {}),
            const SizedBox(height: 4),
            Text('Com o convite você entra como associado ativo na hora.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ] else if (_listError != null)
          AppEmptyState(
            icon: Icons.cloud_off_outlined,
            message: _listError!,
            actionLabel: 'Tentar novamente',
            onAction: _loadAssociations,
          )
        else if (_associations == null)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_associations!.isEmpty)
          const AppEmptyState(icon: Icons.groups_outlined, message: 'Nenhuma associação disponível no momento.')
        else ...[
          for (final association in _associations!) ...[
            _AssociationTile(
              association: association,
              selected: selected != null && !selected.isInvite && selected.organizationId == association.id,
              onTap: () => widget.onChanged(AssociationChoice.request(association)),
            ),
            const SizedBox(height: 8),
          ],
          Text('O gestor da associação precisa aprovar o seu pedido de entrada.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _AssociationTile extends StatelessWidget {
  final AssociationSummary association;
  final bool selected;
  final VoidCallback onTap;

  const _AssociationTile({required this.association, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppChoiceTile(
      title: association.tradingName,
      subtitle: [association.type.label, if (association.location != null) association.location!].join(' · '),
      leading: AssociationLogo(logoUrl: association.logoUrl, name: association.tradingName, size: 40),
      selected: selected,
      onTap: onTap,
    );
  }
}
