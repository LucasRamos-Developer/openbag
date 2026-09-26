import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

/// CPF e CNH do entregador (cadastro pelo gestor e auto-cadastro)
class CourierDocumentFields extends StatelessWidget {
  final TextEditingController cpf;
  final TextEditingController driverLicense;

  const CourierDocumentFields({super.key, required this.cpf, required this.driverLicense});

  @override
  Widget build(BuildContext context) {
    return AppResponsiveRow(
      breakpoint: 520,
      children: [
        AppTextField(
          controller: cpf,
          labelText: 'CPF',
          hintText: '000.000.000-00',
          variant: TextFieldVariant.filled,
          keyboardType: TextInputType.number,
          inputFormatters: [cpfFormatter],
          validator: validateCPF,
        ),
        AppTextField(
          controller: driverLicense,
          labelText: 'CNH (nº de registro)',
          variant: TextFieldVariant.filled,
          keyboardType: TextInputType.number,
          inputFormatters: [IntegerFormatter()],
          validator: (v) => validateRequired(v, 'CNH'),
        ),
      ],
    );
  }
}
