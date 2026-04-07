import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/models/company_model.dart';
import '../../../data/models/renewal_model.dart';
import '../../../data/repositories/renewal_repository.dart';
import '../../providers/company_provider.dart';
import '../../providers/renewal_provider.dart';
import '../../widgets/crm_card.dart';
import '../../widgets/searchable_dropdown.dart';

/// Create a renewal, or pass [renewal] to edit an existing one (same fields + layout).
class RenewalFormPage extends ConsumerStatefulWidget {
  final Renewal? renewal;

  const RenewalFormPage({super.key, this.renewal});

  bool get isEdit => renewal != null;

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

  bool get _isEdit => widget.isEdit;

  @override
  void initState() {
    super.initState();
    final r = widget.renewal;
    if (r != null) {
      _companyId = r.companyId;
      _detailsController.text = r.productDetails ?? '';
      _sourceController.text = r.source ?? '';
      final t = (r.renewalType ?? 'existing').toLowerCase().trim();
      _renewalType = t == 'potential' ? 'potential' : 'existing';
      _renewalDate = r.renewalDate;
    }
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

  String _formatYmd(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Same pill shell as deal status / order workflow (rounded, selected shadow).
  Widget _selectionPill({
    required String label,
    required bool selected,
    required Color accent,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    Color onAccent(Color bg) {
      final k = bg.toARGB32();
      if (k == cs.primary.toARGB32()) return cs.onPrimary;
      if (k == cs.secondary.toARGB32()) return cs.onSecondary;
      if (k == cs.tertiary.toARGB32()) return cs.onTertiary;
      if (k == cs.outline.toARGB32()) return cs.onSurface;
      return cs.onPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: selected ? accent : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? accent
              : cs.outlineVariant.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? onAccent(accent) : textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _renewalDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (d != null) setState(() => _renewalDate = d);
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
      if (_isEdit) {
        await ref.read(renewalRepositoryProvider).updateRenewal(
              id: widget.renewal!.id,
              companyId: _companyId,
              productDetails: _detailsController.text.trim(),
              renewalType: _renewalType,
              source: _sourceController.text.trim().isEmpty
                  ? null
                  : _sourceController.text.trim(),
              renewalDate: _renewalDate,
            );
      } else {
        await ref.read(renewalRepositoryProvider).createRenewal(
              companyId: _companyId!,
              productDetails: _detailsController.text.trim(),
              renewalType: _renewalType,
              source: _sourceController.text.trim().isEmpty
                  ? null
                  : _sourceController.text.trim(),
              renewalDate: _renewalDate!,
            );
      }
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppThemeColors.backgroundColor(context),
      appBar: AppThemeColors.appBarTitle(
        context,
        _isEdit ? 'Edit renewal' : 'New renewal',
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppThemeColors.pagePaddingAll,
          children: [
            Text(
              _isEdit ? 'Renewal' : 'New renewal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit
                  ? 'Update the same fields as when you created this renewal.'
                  : 'Add a contract renewal to your pipeline.',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            CRMCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Company *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
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
                  const SizedBox(height: AppSpacing.md),
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
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Renewal type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _selectionPill(
                        label: 'Existing',
                        selected: _renewalType == 'existing',
                        accent: cs.primary,
                        textPrimary: textPrimary,
                        onTap: () =>
                            setState(() => _renewalType = 'existing'),
                      ),
                      _selectionPill(
                        label: 'Potential',
                        selected: _renewalType == 'potential',
                        accent: cs.tertiary,
                        textPrimary: textPrimary,
                        onTap: () =>
                            setState(() => _renewalType = 'potential'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _sourceController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Source (optional)',
                      labelStyle: TextStyle(color: textSecondary),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Renewal date *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Tap calendar to choose',
                          suffixIcon: Icon(
                            Icons.calendar_month_rounded,
                            color: primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Text(
                          _renewalDate != null
                              ? _formatYmd(_renewalDate!)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _renewalDate != null
                                ? textPrimary
                                : textSecondary,
                            fontWeight: _renewalDate != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                  : Text(_isEdit ? 'Save changes' : 'Create renewal'),
            ),
          ],
        ),
      ),
    );
  }
}
