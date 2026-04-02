import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/crm_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/error_widget.dart' as app_widgets;

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  Order? _order;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await ref
          .read(orderRepositoryProvider)
          .getOrderById(widget.orderId);
      if (mounted) setState(() => _order = o);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);

    return Scaffold(
      backgroundColor: AppThemeColors.backgroundColor(context),
      appBar: AppThemeColors.appBarTitle(context, 'Order'),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? app_widgets.ErrorWidget(message: _error!, onRetry: _load)
              : _order == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: AppThemeColors.pagePaddingAll,
                      children: [
                        CRMCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order!.company?.name ?? 'Company',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _order!.orderDetails ?? '—',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (_order!.status != null)
                                    StatusBadge(
                                      status: _order!.status!,
                                      type: 'sale',
                                    ),
                                  const Spacer(),
                                  Text(
                                    _order!.formattedRevenue,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _line(
                                textSecondary,
                                textPrimary,
                                'Confirmed',
                                _fmt(_order!.orderConfirmationDate),
                              ),
                              _line(
                                textSecondary,
                                textPrimary,
                                'Delivery',
                                _fmt(_order!.deliveryDate),
                              ),
                              if (_order!.assignToUser != null)
                                _line(
                                  textSecondary,
                                  textPrimary,
                                  'Assignee',
                                  _order!.assignToUser!.name,
                                ),
                              if (_order!.nextAction != null)
                                _line(
                                  textSecondary,
                                  textPrimary,
                                  'Next action',
                                  _order!.nextAction!,
                                ),
                              _line(
                                textSecondary,
                                textPrimary,
                                'Next action date',
                                _fmt(_order!.nextActionDate),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _line(
    Color secondary,
    Color primary,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: primary),
            ),
          ),
        ],
      ),
    );
  }
}
