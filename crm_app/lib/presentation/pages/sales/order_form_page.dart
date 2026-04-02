import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/models/company_model.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../providers/company_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/searchable_dropdown.dart';

class OrderFormPage extends ConsumerStatefulWidget {
  const OrderFormPage({super.key});

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _revenueController = TextEditingController();
  String? _companyId;
  String? _saleId;
  String? _assignToId;
  DateTime? _confirmed;
  DateTime? _delivery;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companiesProvider.notifier).loadCompanies();
      ref.read(usersProvider.notifier).loadUsers();
      ref.read(salesProvider.notifier).loadSales();
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required void Function(DateTime) onPick,
  }) async {
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (d != null) onPick(d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null || _companyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a company')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(orderRepositoryProvider).createOrder(
            companyId: _companyId!,
            salesId: _saleId,
            orderDetails: _detailsController.text.trim(),
            revenue: double.tryParse(_revenueController.text.trim()),
            orderConfirmationDate: _confirmed,
            deliveryDate: _delivery,
            assignTo: _assignToId,
          );
      if (mounted) {
        ref.read(ordersProvider.notifier).loadOrders();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesState = ref.watch(companiesProvider);
    final usersState = ref.watch(usersProvider);
    final salesState = ref.watch(salesProvider);
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final borderColor = AppThemeColors.borderColor(context);
    final surfaceColor = AppThemeColors.surfaceColor(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final salesForCompany = _companyId == null
        ? <Sale>[]
        : salesState.sales.where((s) => s.companyId == _companyId).toList();

    return Scaffold(
      backgroundColor: AppThemeColors.backgroundColor(context),
      appBar: AppThemeColors.appBarTitle(context, 'New order'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppThemeColors.pagePaddingAll,
          children: [
            Text(
              'Company *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: SearchableDropdown<Company>(
                items: companiesState.companies,
                value: _companyId != null
                    ? companiesState.companies
                        .where((c) => c.id == _companyId)
                        .firstOrNull
                    : null,
                hintText: 'Select company',
                labelText: 'Company',
                dropdownColor: surfaceColor,
                textColor: textPrimary,
                hintColor: textSecondary,
                itemLabelBuilder: (c) => c.name,
                onChanged: (c) => setState(() {
                  _companyId = c?.id;
                  _saleId = null;
                }),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Linked deal (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              key: ValueKey(_companyId),
              initialValue: _saleId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'None',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ...salesForCompany.map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      s.prospect,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _saleId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              style: TextStyle(color: textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Order details *',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _revenueController,
              style: TextStyle(color: textPrimary),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Revenue',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Order confirmation date',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Text(
                _confirmed != null
                    ? '${_confirmed!.year}-${_confirmed!.month.toString().padLeft(2, '0')}-${_confirmed!.day.toString().padLeft(2, '0')}'
                    : 'Tap to pick',
                style: TextStyle(color: textSecondary),
              ),
              onTap: () => _pickDate(
                current: _confirmed,
                onPick: (d) => setState(() => _confirmed = d),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Delivery date',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Text(
                _delivery != null
                    ? '${_delivery!.year}-${_delivery!.month.toString().padLeft(2, '0')}-${_delivery!.day.toString().padLeft(2, '0')}'
                    : 'Tap to pick',
                style: TextStyle(color: textSecondary),
              ),
              onTap: () => _pickDate(
                current: _delivery,
                onPick: (d) => setState(() => _delivery = d),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign to',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: SearchableDropdown<User>(
                items: usersState.users,
                value: _assignToId != null
                    ? usersState.users
                        .where((u) => u.id == _assignToId)
                        .firstOrNull
                    : null,
                hintText: 'Optional',
                labelText: 'User',
                dropdownColor: surfaceColor,
                textColor: textPrimary,
                hintColor: textSecondary,
                itemLabelBuilder: (u) => '${u.name} (${u.email})',
                onChanged: (u) => setState(() => _assignToId = u?.id),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create order'),
            ),
          ],
        ),
      ),
    );
  }
}
