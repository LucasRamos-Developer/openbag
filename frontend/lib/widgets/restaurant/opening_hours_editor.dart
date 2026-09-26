import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/store/store.dart';

/// Editor de horários de funcionamento: turnos por dia da semana (vários por dia),
/// inclusive turnos que viram a noite (ex: 18:00–02:00)
class OpeningHoursEditor extends StatelessWidget {
  final List<OpeningHour> hours;
  final ValueChanged<List<OpeningHour>> onChanged;

  const OpeningHoursEditor({super.key, required this.hours, required this.onChanged});

  List<OpeningHour> _shiftsOf(int weekday) =>
      hours.where((h) => h.weekday == weekday).toList()..sort((a, b) => a.openTime.compareTo(b.openTime));

  Future<String?> _pickTime(BuildContext context, String initial, String help) async {
    final parts = initial.split(':');
    final picked = await showTimePicker(
      context: context,
      helpText: help,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(picked.hour)}:${two(picked.minute)}';
  }

  Future<void> _editShift(BuildContext context, OpeningHour? shift, int weekday) async {
    final open = await _pickTime(context, shift?.openTime ?? '11:00', 'Abre às');
    if (open == null || !context.mounted) return;
    final close = await _pickTime(context, shift?.closeTime ?? '23:00', 'Fecha às');
    if (close == null) return;
    if (open == close) {
      if (context.mounted) {
        AppToast.show(context, message: 'Abertura e fechamento não podem ser iguais', type: ToastType.warning);
      }
      return;
    }

    final updated = OpeningHour(weekday: weekday, openTime: open, closeTime: close);
    onChanged([
      for (final h in hours)
        if (!identical(h, shift)) h,
      updated,
    ]);
  }

  void _removeShift(OpeningHour shift) => onChanged([for (final h in hours) if (!identical(h, shift)) h]);

  void _copyMondayToAll() {
    final monday = _shiftsOf(1);
    onChanged([
      for (var day = 1; day <= 7; day++)
        for (final shift in monday) shift.copyWith(weekday: day),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var day = 1; day <= 7; day++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(OpeningHour.weekdayNames[day - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_shiftsOf(day).isEmpty) Text('Fechado', style: TextStyle(color: muted)),
                      for (final shift in _shiftsOf(day))
                        InputChip(
                          label: Text('${shift.openTime} – ${shift.closeTime}${shift.overnight ? ' (+1 dia)' : ''}'),
                          onPressed: () => _editShift(context, shift, day),
                          onDeleted: () => _removeShift(shift),
                          deleteButtonTooltipMessage: 'Remover turno',
                        ),
                      IconButton(
                        tooltip: 'Adicionar turno',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _editShift(context, null, day),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            text: 'Copiar horários de segunda para todos os dias',
            icon: Icons.copy_all_outlined,
            variant: ButtonVariant.text,
            onPressed: _shiftsOf(1).isEmpty ? null : _copyMondayToAll,
          ),
        ),
      ],
    );
  }
}
