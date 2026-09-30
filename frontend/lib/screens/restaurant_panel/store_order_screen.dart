import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../models/order/order.dart';
import '../../services/api_client.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/restaurant_orders_service.dart';
import '../../services/restaurant_panel_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/address/address_form.dart';
import '../../widgets/cart/cart_line_tile.dart';
import '../../widgets/menu/menu_picker.dart';
import '../../widgets/order/order_ticket.dart';
import '../../widgets/order/price_summary.dart';
import 'restaurant_section.dart';

/// Endereço da tela de novo pedido da loja
const storeOrderPath = '/restaurante/pedidos/novo';

/// Pedido registrado pela loja (balcão, telefone ou WhatsApp) para um cliente sem conta.
///
/// Entra já aceito e segue o fluxo dos pedidos do app: cozinha, despacho (na entrega) e caixa.
/// Em telas largas o cardápio fica ao lado do pedido; no celular ele abre em tela cheia pelo "Adicionar item".
class StoreOrderScreen extends StatefulWidget {
  const StoreOrderScreen({super.key});

  @override
  State<StoreOrderScreen> createState() => _StoreOrderScreenState();
}

class _StoreOrderScreenState extends State<StoreOrderScreen> {
  static const _wideWidth = 1000.0;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  final _changeFor = TextEditingController();
  final _address = AddressFormController();

  final List<CartLine> _lines = [];
  OrderChannel _channel = OrderChannel.COUNTER;
  FulfillmentType _fulfillment = FulfillmentType.PICKUP;
  bool _fulfillmentChosen = false;
  PaymentMethod _payment = PaymentMethod.PIX;
  bool _needsChange = false;
  bool _isSubmitting = false;

  // Taxa pelo endereço (fixa da loja ou pela distância), calculada no servidor
  DeliveryQuote? _quote;
  bool _quoting = false;
  Timer? _quoteDebounce;
  String? _quotedAddress;

  RestaurantPanelService get _panel => context.read<RestaurantPanelService>();

  @override
  void initState() {
    super.initState();
    for (final field in [_address.street, _address.number, _address.city, _address.state]) {
      field.addListener(_scheduleQuote);
    }
    if (_panel.menu == null && !_panel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _panel.load().then((_) => _prefillCity()));
    } else {
      _prefillCity();
    }
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    for (final c in [_name, _phone, _notes, _changeFor]) {
      c.dispose();
    }
    _address.dispose();
    super.dispose();
  }

  /// A maioria dos pedidos por telefone é da mesma cidade da loja
  void _prefillCity() {
    final address = _panel.store?.address;
    if (address == null || !mounted) return;
    if (_address.city.text.isEmpty) _address.city.text = address.city;
    if (_address.state.text.isEmpty) _address.state.text = address.state;
  }

  bool get _delivery => _fulfillment == FulfillmentType.DELIVERY;

  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.totalPrice);

  double get _deliveryFee => _delivery ? (_quote?.fee ?? 0) : 0;

  double get _total => _subtotal + _deliveryFee;

  // ============= Itens =============

  void _addLine(CartLine line) {
    setState(() {
      final existing = _lines.where((l) => l.key == line.key).firstOrNull;
      if (existing != null) {
        existing.quantity = (existing.quantity + line.quantity).clamp(1, 50);
      } else {
        _lines.add(line);
      }
    });
  }

  void _setQuantity(CartLine line, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _lines.remove(line);
      } else {
        line.quantity = quantity;
      }
    });
  }

  Future<void> _openPicker(Menu menu) async {
    final line = await showMenuPickerPage(context, menu: menu);
    if (line != null) _addLine(line);
  }

  // ============= Origem e entrega =============

  void _setChannel(OrderChannel channel) {
    setState(() {
      _channel = channel;
      // Até a loja escolher: balcão costuma ser retirada; telefone e WhatsApp, entrega
      if (!_fulfillmentChosen) {
        _fulfillment = channel == OrderChannel.COUNTER ? FulfillmentType.PICKUP : FulfillmentType.DELIVERY;
      }
    });
    _scheduleQuote();
  }

  void _setFulfillment(FulfillmentType fulfillment) {
    setState(() {
      _fulfillment = fulfillment;
      _fulfillmentChosen = true;
    });
    _scheduleQuote();
  }

  void _scheduleQuote() {
    final restaurantId = _panel.selectedId;
    if (!_delivery || restaurantId == null) return;
    final address = _address.toJson();
    if ([address['street'], address['number'], address['city'], address['state']].any((v) => v == null)) return;
    final key = json.encode(address);
    if (key == _quotedAddress) return;

    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 700), () => _fetchQuote(restaurantId, address, key));
  }

  Future<void> _fetchQuote(int restaurantId, Map<String, dynamic> address, String key) async {
    setState(() => _quoting = true);
    try {
      final quote = await context.read<OrderService>().quoteDelivery(restaurantId, address);
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _quotedAddress = key;
      });
    } on ApiException catch (_) {
      // Sem a cotação, o pedido calcula a taxa no servidor ao ser criado
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  // ============= Envio =============

  Future<void> _submit() async {
    if (_lines.isEmpty) {
      AppToast.show(context, message: 'Adicione pelo menos um item', type: ToastType.warning);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      AppToast.show(context, message: 'Confira os dados do pedido', type: ToastType.warning);
      return;
    }
    final changeFor = _payment == PaymentMethod.CASH && _needsChange ? parseMoney(_changeFor.text) : null;
    if (changeFor != null && changeFor < _total) {
      AppToast.show(context, message: 'O troco deve ser para um valor maior que o total', type: ToastType.warning);
      return;
    }

    final panel = _panel;
    setState(() => _isSubmitting = true);
    try {
      final order = await context.read<RestaurantOrdersService>().createStoreOrder(panel.selectedId!, {
        'channel': _channel.name,
        'fulfillment': _fulfillment.name,
        'customerName': _name.text.trim(),
        'customerPhone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'items': _lines.map((l) => l.toOrderItem()).toList(),
        'address': _delivery ? _address.toJson() : null,
        'paymentMethod': _payment.name,
        'changeFor': changeFor,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      if (!mounted) return;
      AppToast.show(context, message: 'Pedido ${order.displayCode ?? ''} enviado para a cozinha', type: ToastType.success);
      // Entra já aceito: imprime a comanda como no aceite, se a loja usa a impressão automática
      if (panel.store?.autoPrintTicket == true) {
        printOrderTicket(order, restaurantName: panel.store?.name ?? 'OpenBag');
      }
      _close(created: true);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Volta ao quadro; [created] avisa o quadro para mostrar a coluna em que o pedido entrou
  void _close({bool created = false}) => context.canPop() ? context.pop(created) : context.go(RestaurantSection.orders.path);

  // ============= Tela =============

  @override
  Widget build(BuildContext context) {
    final panel = context.watch<RestaurantPanelService>();
    final menu = panel.menu;
    final wide = MediaQuery.sizeOf(context).width >= _wideWidth;

    final appBar = AppBar(
      leading: IconButton(tooltip: 'Fechar', icon: const Icon(Icons.close), onPressed: _close),
      titleSpacing: 0,
      title: const Text('Novo pedido'),
    );

    if (menu == null) {
      return Scaffold(
        appBar: appBar,
        body: panel.error == null
            ? const Center(child: CircularProgressIndicator())
            : AppEmptyState(
                icon: Icons.cloud_off_outlined,
                message: panel.error!,
                actionLabel: 'Tentar novamente',
                onAction: panel.load,
              ),
      );
    }

    final submit = AppButton(
      text: 'Enviar para a cozinha  ·  ${formatMoney(_total)}',
      size: ButtonSize.large,
      fullWidth: true,
      isLoading: _isSubmitting,
      onPressed: _isSubmitting ? null : _submit,
    );

    if (!wide) {
      return Scaffold(
        appBar: appBar,
        body: Form(
          key: _formKey,
          child: _formScroll(const EdgeInsets.fromLTRB(16, 8, 16, 24), onAddItem: () => _openPicker(menu)),
        ),
        bottomNavigationBar: AppStickyActionBar(children: [submit]),
      );
    }

    final colors = context.appColors;
    return Scaffold(
      appBar: appBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ColoredBox(
              color: colors.background,
              child: MenuPicker(menu: menu, onPick: _addLine, padding: const EdgeInsets.fromLTRB(24, 16, 24, 24)),
            ),
          ),
          VerticalDivider(width: 1, color: colors.border),
          SizedBox(
            width: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: _formScroll(const EdgeInsets.fromLTRB(24, 8, 24, 24)),
                  ),
                ),
                AppStickyActionBar(children: [submit]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formulário rolável; em Column (e não ListView) para a validação alcançar os campos fora da tela
  Widget _formScroll(EdgeInsets padding, {VoidCallback? onAddItem}) => SingleChildScrollView(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _formChildren(onAddItem: onAddItem)),
      );

  /// Campos do pedido; [onAddItem] mostra o botão que abre o cardápio (celular)
  List<Widget> _formChildren({VoidCallback? onAddItem}) {
    final muted = context.appColors.textMuted;
    const chipsPadding = EdgeInsets.symmetric(vertical: 10);

    return [
      const AppSectionHeader(title: 'Como o pedido chegou', padding: EdgeInsets.only(top: 12)),
      AppFilterChips<OrderChannel>(
        items: [for (final c in OrderChannel.storeChannels) SelectItem(value: c, label: c.label, icon: c.icon)],
        value: _channel,
        onSelected: _setChannel,
        padding: chipsPadding,
      ),
      AppSectionHeader(
        title: 'Itens',
        padding: const EdgeInsets.only(top: 20),
        subtitle: onAddItem == null && _lines.isEmpty ? 'Toque nos itens do cardápio ao lado para adicionar' : null,
      ),
      for (final line in _lines)
        CartLineTile(
          key: ValueKey(line.key),
          line: line,
          showImage: false,
          onQuantityChanged: (v) => _setQuantity(line, v),
        ),
      if (_lines.isEmpty && onAddItem == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Nenhum item ainda.', style: TextStyle(color: muted)),
        ),
      if (onAddItem != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppButton(
            text: 'Adicionar item',
            icon: Icons.add,
            variant: ButtonVariant.outlined,
            fullWidth: true,
            onPressed: onAddItem,
          ),
        ),
      const AppSectionHeader(title: 'Cliente', padding: EdgeInsets.only(top: 28, bottom: 12)),
      AppTextField(
        controller: _name,
        labelText: 'Nome',
        hintText: 'Como chamar o cliente',
        variant: TextFieldVariant.filled,
        textCapitalization: TextCapitalization.words,
        validator: (v) => validateRequired(v, 'Nome'),
      ),
      const SizedBox(height: 20),
      AppTextField(
        controller: _phone,
        labelText: _delivery ? 'Telefone (para o entregador)' : 'Telefone (opcional)',
        hintText: '(XX) XXXXX-XXXX',
        variant: TextFieldVariant.filled,
        keyboardType: TextInputType.phone,
        inputFormatters: [PhoneFormatter()],
      ),
      const AppSectionHeader(title: 'Entrega ou retirada', padding: EdgeInsets.only(top: 28)),
      AppFilterChips<FulfillmentType>(
        items: [for (final f in FulfillmentType.values) SelectItem(value: f, label: f.label, icon: f.icon)],
        value: _fulfillment,
        onSelected: _setFulfillment,
        padding: chipsPadding,
      ),
      if (_delivery) ...[
        const SizedBox(height: 8),
        AddressForm(controller: _address),
      ] else
        Text('O cliente busca o pedido pronto no balcão.', style: TextStyle(color: muted)),
      AppSectionHeader(
        title: _delivery ? 'Pagamento na entrega' : 'Pagamento na retirada',
        padding: const EdgeInsets.only(top: 28, bottom: 4),
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
          title: const Text('Precisa de troco'),
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
        labelText: 'Observações (opcional)',
        hintText: 'Ex: sem cebola, cliente chega às 19h',
        variant: TextFieldVariant.filled,
        maxLines: 2,
        maxLength: 300,
        textCapitalization: TextCapitalization.sentences,
      ),
      const AppSectionHeader(title: 'Resumo', padding: EdgeInsets.only(top: 12, bottom: 8)),
      PriceSummary(
        subtotal: _subtotal,
        deliveryFee: _delivery ? _deliveryFee : null,
        total: _total,
        deliveryDistanceKm: _quote?.byDistance == true ? _quote?.distanceKm : null,
        calculating: _quoting,
      ),
      if (_delivery && _quote == null && !_quoting)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('A taxa de entrega aparece quando o endereço estiver completo.',
              style: TextStyle(color: muted, fontSize: 12)),
        ),
    ];
  }
}
