import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/delivery/staff_courier.dart';
import '../../../../services/restaurant_delivery_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/validators.dart';

/// Equipe própria da loja: entregadores sem o app. A loja escolhe quem leva o pedido e marca a saída e a entrega.
class StaffSection extends StatelessWidget {
  const StaffSection({super.key});

  Future<void> _edit(BuildContext context, [StaffCourier? staff]) async {
    await showDialog<void>(context: context, builder: (_) => _StaffDialog(staff: staff));
  }

  Future<void> _remove(BuildContext context, StaffCourier staff) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Remover ${staff.name}?',
      message: 'Ele sai da lista para novos pedidos. As entregas já feitas continuam no caixa.',
      confirmLabel: 'Remover',
    );
    if (!confirmed || !context.mounted) return;
    await runWithFeedback(context, () => context.read<RestaurantDeliveryService>().removeStaff(staff.id),
        success: '${staff.name} removido da equipe');
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<RestaurantDeliveryService>().staff;
    final c = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Equipe da loja',
          subtitle: 'Entregadores seus, sem o app. Escolha um deles no pedido e marque a saída e a entrega no quadro.',
          action: AppButton(text: 'Adicionar', icon: Icons.add, variant: ButtonVariant.outlined, onPressed: () => _edit(context)),
        ),
        if (staff.isEmpty)
          Text('Ninguém na equipe ainda.', style: TextStyle(color: c.textMuted))
        else
          for (final person in staff)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderColor: c.border,
                borderWidth: 1,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: c.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.badge_outlined, color: c.primaryText, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            [
                              if (person.phone != null) person.phone!,
                              person.feePerDelivery != null
                                  ? '${formatMoney(person.feePerDelivery!)} por entrega'
                                  : 'Recebe a taxa de entrega do pedido',
                            ].join(' · '),
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, person)),
                    IconButton(
                      tooltip: 'Remover',
                      icon: Icon(Icons.delete_outline, color: c.danger),
                      onPressed: () => _remove(context, person),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _StaffDialog extends StatefulWidget {
  final StaffCourier? staff;

  const _StaffDialog({this.staff});

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.staff?.name);
  late final _phone = TextEditingController(text: PhoneFormatter.format(widget.staff?.phone ?? ''));
  late final _fee = TextEditingController(
      text: widget.staff?.feePerDelivery != null ? moneyInput(widget.staff!.feePerDelivery!) : '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _fee]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<RestaurantDeliveryService>().saveStaff(
            id: widget.staff?.id,
            name: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            feePerDelivery: _fee.text.trim().isEmpty ? null : parseMoney(_fee.text),
          ),
      success: widget.staff == null ? '${_name.text.trim()} entrou na equipe' : 'Dados salvos',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.staff == null ? 'Novo entregador da equipe' : 'Editar entregador'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _name,
                labelText: 'Nome',
                variant: TextFieldVariant.filled,
                textCapitalization: TextCapitalization.words,
                validator: (v) => validateRequired(v, 'Nome'),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _phone,
                labelText: 'Telefone (opcional)',
                variant: TextFieldVariant.filled,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneFormatter()],
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _fee,
                labelText: 'Valor por entrega (opcional)',
                helperText: 'Em branco, ele recebe a taxa de entrega cobrada do cliente',
                prefixText: 'R\$ ',
                variant: TextFieldVariant.filled,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyFormatter()],
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: _saving ? null : () => Navigator.of(context).pop()),
        AppButton(text: 'Salvar', icon: Icons.check, isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
