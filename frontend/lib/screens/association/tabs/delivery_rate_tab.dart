import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/delivery/delivery_rate.dart';
import '../../../services/association_service.dart';
import '../../../utils/feedback.dart';
import '../../../widgets/delivery/delivery_rate_fields.dart';

/// Tabela de valores de entrega da associação: o entregador recebe 100% do valor calculado
class DeliveryRateTab extends StatefulWidget {
  const DeliveryRateTab({super.key});

  @override
  State<DeliveryRateTab> createState() => _DeliveryRateTabState();
}

class _DeliveryRateTabState extends State<DeliveryRateTab> {
  final _formKey = GlobalKey<FormState>();
  DeliveryRate? _draft;
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await runWithFeedback(context, () => context.read<AssociationService>().updateDeliveryRate(_draft!),
        success: 'Tabela de entrega salva');
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<AssociationService>().association!.deliveryRate;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(
                    title: 'Tabela de entrega',
                    subtitle: 'Quanto o entregador recebe por entrega. Ele fica com 100% do valor. '
                        'Restaurantes cuja taxa for menor que esta tabela precisam assumir a diferença. '
                        'Com uma loja parceira, vocês podem combinar uma tabela especial em Lojas parceiras.',
                  ),
                  if (!saved.configured)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppColors.warningLighter.withValues(alpha: 0.4),
                        child: Text(
                          'Enquanto a tabela não for definida, os associados não conseguem ficar online.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  DeliveryRateFields(initial: saved, onChanged: (rate) => _draft = rate),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: 'Salvar tabela',
                      icon: Icons.check,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
