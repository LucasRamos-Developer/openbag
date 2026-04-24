import 'package:flutter/material.dart';
import '../../models/onboarding/opening_hour.dart';

/// Widget para editar um item de horário de funcionamento
class OpeningHoursItem extends StatefulWidget {
  final OpeningHour hour;
  final VoidCallback onRemove;
  final ValueChanged<OpeningHour> onChanged;

  const OpeningHoursItem({
    super.key,
    required this.hour,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<OpeningHoursItem> createState() => _OpeningHoursItemState();
}

class _OpeningHoursItemState extends State<OpeningHoursItem> {
  late TextEditingController _labelController;
  late TextEditingController _observationController;

  static const weekdayLabels = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.hour.label);
    _observationController = TextEditingController(text: widget.hour.observation);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = !widget.hour.isValid();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Ex: Almoço, Jantar',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      widget.onChanged(widget.hour.copyWith(label: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remover horário',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dia da semana
            DropdownButtonFormField<int>(
              value: widget.hour.weekday,
              decoration: const InputDecoration(
                labelText: 'Dia da semana',
                isDense: true,
              ),
              items: List.generate(7, (index) {
                final weekday = index + 1;
                return DropdownMenuItem(
                  value: weekday,
                  child: Text(weekdayLabels[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  widget.onChanged(widget.hour.copyWith(weekday: value));
                }
              },
            ),
            const SizedBox(height: 12),

            // Horários
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    label: 'Abre',
                    value: widget.hour.openTime,
                    onChanged: (time) {
                      widget.onChanged(widget.hour.copyWith(openTime: time));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    label: 'Fecha',
                    value: widget.hour.closeTime,
                    onChanged: (time) {
                      widget.onChanged(widget.hour.copyWith(closeTime: time));
                    },
                    hasError: hasError,
                  ),
                ),
              ],
            ),

            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Horário de fechamento deve ser depois do horário de abertura',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            
            // Observação
            TextField(
              controller: _observationController,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                hintText: 'Ex: Não abrimos em feriados',
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (value) {
                widget.onChanged(widget.hour.copyWith(observation: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool hasError = false,
  }) {
    return InkWell(
      onTap: () async {
        final timeParts = value.split(':');
        final initialTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 0,
          minute: int.tryParse(timeParts[1]) ?? 0,
        );

        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final formatted = '${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}:00';
          onChanged(formatted);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          errorText: hasError ? '' : null,
          errorStyle: const TextStyle(height: 0),
          suffixIcon: const Icon(Icons.access_time, size: 20),
        ),
        child: Text(
          value.substring(0, 5), // Exibe apenas HH:mm
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
