import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/store/store.dart';
import '../../../../services/restaurant_panel_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../widgets/restaurant/opening_hours_editor.dart';

/// Loja › Horários: turnos de funcionamento por dia da semana
class HoursTab extends StatefulWidget {
  final Store store;

  const HoursTab({super.key, required this.store});

  @override
  State<HoursTab> createState() => _HoursTabState();
}

class _HoursTabState extends State<HoursTab> {
  late List<OpeningHour> _hours = List.of(widget.store.openingHours);
  bool _dirty = false;
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await runWithFeedback(context, () => context.read<RestaurantPanelService>().updateOpeningHours(_hours),
        success: 'Horários salvos');
    if (mounted) {
      setState(() {
        _isSaving = false;
        _dirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageListView(
      top: 16,
      children: [
        AppPanelCard(
          title: 'Horário de funcionamento',
          subtitle: _hours.isEmpty
              ? 'Sem horários: a loja segue apenas a opção "Abrir/Fechar loja" do menu'
              : 'Toque em um turno para editar. Turnos que passam da meia-noite continuam no dia seguinte.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OpeningHoursEditor(
                hours: _hours,
                onChanged: (hours) => setState(() {
                  _hours = hours;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  text: 'Salvar horários',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _dirty && !_isSaving ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
