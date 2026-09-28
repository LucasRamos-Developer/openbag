import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../models/order/order_review.dart';
import '../../services/review_service.dart';
import '../../utils/feedback.dart';

/// Avaliação do pedido entregue: nota da loja (obrigatória) e, se foi um entregador do app, nota do entregador.
/// Retorna a avaliação enviada, ou null se o cliente fechou sem enviar.
Future<OrderReview?> showOrderReviewSheet(BuildContext context, {required Order order}) =>
    showModalBottomSheet<OrderReview>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => OrderReviewSheet(order: order),
    );

class OrderReviewSheet extends StatefulWidget {
  final Order order;

  const OrderReviewSheet({super.key, required this.order});

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  int? _restaurantRating;
  int? _courierRating;
  final _restaurantComment = TextEditingController();
  final _courierComment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _restaurantComment.dispose();
    _courierComment.dispose();
    super.dispose();
  }

  static String? _text(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text.trim();

  Future<void> _send() async {
    setState(() => _sending = true);
    OrderReview? review;
    final ok = await runWithFeedback(context, () async {
      review = await context.read<ReviewService>().reviewOrder(
            widget.order.id,
            restaurantRating: _restaurantRating!,
            restaurantComment: _text(_restaurantComment),
            courierRating: _courierRating,
            courierComment: _courierRating != null ? _text(_courierComment) : null,
          );
    }, success: 'Obrigado pela avaliação!');
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(review);
    } else {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final courier = widget.order.courier;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Como foi o seu pedido?',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 20),
            _Section(
              title: widget.order.restaurant.name,
              subtitle: 'Comida, embalagem e atendimento',
              rating: _restaurantRating,
              onRating: (v) => setState(() => _restaurantRating = v),
              comment: _restaurantComment,
            ),
            if (courier != null) ...[
              const SizedBox(height: 24),
              _Section(
                title: courier.fullName,
                subtitle: 'Entrega (opcional)',
                rating: _courierRating,
                onRating: (v) => setState(() => _courierRating = v),
                comment: _courierComment,
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              text: 'Enviar avaliação',
              isLoading: _sending,
              onPressed: _restaurantRating == null || _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? rating;
  final ValueChanged<int> onRating;
  final TextEditingController comment;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.onRating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, fontSize: 13)),
        const SizedBox(height: 8),
        Center(child: AppRatingInput(value: rating, onChanged: onRating)),
        if (rating != null) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: comment,
            hintText: 'Quer contar mais? (opcional)',
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
          ),
        ],
      ],
    );
  }
}
