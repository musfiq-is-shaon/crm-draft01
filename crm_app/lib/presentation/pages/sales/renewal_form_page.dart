import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/models/company_model.dart';
import '../../../data/repositories/renewal_repository.dart';
import '../../providers/company_provider.dart';
import '../../providers/renewal_provider.dart';
import '../../widgets/searchable_dropdown.dart';

class RenewalFormPage extends ConsumerStatefulWidget {
  const RenewalFormPage({super.key});

  @override
  ConsumerState<RenewalFormPage> createState() => _RenewalFormPageState();
}

class _RenewalFormPageState extends ConsumerState<RenewalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _sourceController = TextEditingController();
  String? _companyId;
  String _renewalType = 'existing';
  DateTime? _renewalDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companiesProvider.notifier).loadCompanies();
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null || _companyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a company')),
      );
      return;
    }
    if (_renewalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a renewal date')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(renewalRepositoryProvider).createRenewal(
            companyId: _companyId!,
            productDetails: _detailsController.text.trim(),
            renewalType: _renewalType,
            source: _sourceController.text.trim().isEmpty
                ? null
                : _sourceController.text.trim(),
            renewalDate: _renewalDate!,
          );
      if (mounted) {
        ref.read(renewalsProvider.notifier).loadRenewals();
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
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final borderColor = AppThemeColors.borderColor(context);
    final surfaceColor = AppThemeColors.surfaceColor(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppThemeColors.backgroundColor(context),
      appBar: AppThemeColors.appBarTitle(context, 'New renewal'),
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
                onChanged: (c) => setState(() => _companyId = c?.id),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              style: TextStyle(color: textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Product / contract details *',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _renewalType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Renewal type',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'existing', child: Text('Existing')),
                DropdownMenuItem(value: 'potential', child: Text('Potential')),
              ],
              onChanged: (v) =>
                  setState(() => _renewalType = v ?? 'existing'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Source (optional)',
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
                'Renewal date *',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Text(
                _renewalDate != null
                    ? '${_renewalDate!.year}-${_renewalDate!.month.toString().padLeft(2, '0')}-${_renewalDate!.day.toString().padLeft(2, '0')}'
                    : 'Tap to pick',
                style: TextStyle(color: textSecondary),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _renewalDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                );
                if (d != null) setState(() => _renewalDate = d);
              },
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
                  : const Text('Create renewal'),
            ),
          ],
        ),
      ),
    );
  }
}
