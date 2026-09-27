import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/address/address_form.dart';
import '../../widgets/order/price_summary.dart';
import '../../widgets/navigation/storefront_scaffold.dart';

/// Finalização do pedido: endereço, pagamento na entrega, observações e resumo
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _lastAddressKey = 'last_delivery_address';

  final _formKey = GlobalKey<FormState>();
  final _address = AddressFormController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  final _changeFor = TextEditingController();

  PaymentMethod _payment = PaymentMethod.PIX;
  bool _needsChange = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phone.text = context.read<AuthService>().currentUser?.phoneNumber ?? '';
    _restoreAddress();
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _notes.dispose();
    _changeFor.dispose();
    super.dispose();
  }

  Future<void> _restoreAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastAddressKey);
    if (raw != null && mounted) {
      setState(() => _address.fill(Map<String, dynamic>.from(json.decode(raw))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.show(context, message: 'Confira o endereço de entrega', type: ToastType.warning);
      return;
    }
    final cart = context.read<CartService>();
    final changeFor = _payment == PaymentMethod.CASH && _needsChange ? parseMoney(_changeFor.text) : null;
    if (changeFor != null && changeFor < cart.total) {
      AppToast.show(context, message: 'O troco deve ser para um valor maior que o total', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final address = _address.toJson();
      final order = await context.read<OrderService>().createOrder({
        'restaurantId': cart.restaurant!.id,
        'items': cart.toOrderItems(),
        'address': address,
        'paymentMethod': _payment.name,
        'changeFor': changeFor,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'customerPhone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastAddressKey, json.encode(address));
      cart.clear();

      if (!mounted) return;
      AppToast.show(context, message: 'Pedido ${order.displayCode ?? ''} enviado!', type: ToastType.success);
      context.go('/pedidos/${order.id}');
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    if (cart.isEmpty) {
      return StorefrontScaffold(
        title: 'Finalizar pedido',
        body: AppEmptyState(
          icon: Icons.shopping_bag_outlined,
          message: 'Seu carrinho está vazio.',
          actionLabel: 'Ver restaurantes',
          onAction: () => context.go('/home'),
        ),
      );
    }

    return StorefrontScaffold(
      title: 'Finalizar pedido',
      // Largura útil da lista (720 menos o padding de 16 de cada lado), para alinhar o título
      maxWidth: 720 - 32,
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppSectionHeader(title: 'Entregar em'),
                AddressForm(controller: _address),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _phone,
                  labelText: 'Telefone para contato',
                  hintText: '(XX) XXXXX-XXXX',
                  variant: TextFieldVariant.filled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneFormatterShort],
                ),
                const SizedBox(height: 32),
                const AppSectionHeader(
                  title: 'Pagamento na entrega',
                  subtitle: 'Você paga ao receber o pedido',
                ),
                for (final method in PaymentMethod.values)
                  AppChoiceTile(
                    leading: Icon(method.icon),
                    title: method.label,
                    selected: _payment == method,
                    onTap: () => setState(() => _payment = method),
                  ),
                if (_payment == PaymentMethod.CASH) ...[
                  SwitchListTile(
                    title: const Text('Preciso de troco'),
                    value: _needsChange,
                    onChanged: (v) => setState(() => _needsChange = v),
                  ),
                  if (_needsChange)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppTextField(
                        controller: _changeFor,
                        labelText: 'Troco para quanto?',
                        prefixText: 'R\$ ',
                        variant: TextFieldVariant.filled,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MoneyFormatter()],
                        validator: (v) => _needsChange && (parseMoney(v ?? '') ?? 0) <= 0 ? 'Informe o valor' : null,
                      ),
                    ),
                ],
                const SizedBox(height: 28),
                AppTextField(
                  controller: _notes,
                  labelText: 'Observações para o restaurante (opcional)',
                  hintText: 'Ex: interfone quebrado, ligar ao chegar',
                  variant: TextFieldVariant.filled,
                  maxLines: 2,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                AppSectionHeader(title: 'Resumo', subtitle: cart.restaurant?.name),
                for (final line in cart.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${line.quantity}x  ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.name),
                              if (line.options.isNotEmpty)
                                Text(line.optionsSummary, style: TextStyle(color: muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(formatMoney(line.totalPrice)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                PriceSummary(subtotal: cart.subtotal, deliveryFee: cart.deliveryFee, total: cart.total),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            text: 'Fazer pedido  ·  ${formatMoney(cart.total)}',
            size: ButtonSize.large,
            fullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ),
      ),
    );
  }
}
