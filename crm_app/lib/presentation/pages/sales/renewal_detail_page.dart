import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../data/models/renewal_model.dart';
import '../../../data/repositories/renewal_repository.dart';
import '../../widgets/crm_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as app_widgets;
import 'renewal_form_page.dart';

class RenewalDetailPage extends ConsumerStatefulWidget {
  final String renewalId;

  const RenewalDetailPage({super.key, required this.renewalId});

  @override
  ConsumerState<RenewalDetailPage> createState() => _RenewalDetailPageState();
}

class _RenewalDetailPageState extends ConsumerState<RenewalDetailPage> {
  Renewal? _renewal;
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
      final r = await ref
          .read(renewalRepositoryProvider)
          .getRenewalById(widget.renewalId);
      if (mounted) setState(() => _renewal = r);
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
      appBar: AppThemeColors.appBarTitle(
        context,
        'Renewal',
        actions: _renewal != null
            ? [
                IconButton(
                  tooltip: 'Edit renewal',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RenewalFormPage(renewal: _renewal!),
                      ),
                    );
                    if (saved == true && mounted) await _load();
                  },
                ),
              ]
            : null,
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? app_widgets.ErrorWidget(message: _error!, onRetry: _load)
              : _renewal == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: AppThemeColors.pagePaddingAll,
                      children: [
                        CRMCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _renewal!.company?.name ?? 'Company',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _renewal!.productDetails ?? '—',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _row(
                                textSecondary,
                                textPrimary,
                                'Type',
                                _renewal!.renewalType ?? '—',
                              ),
                              _row(
                                textSecondary,
                                textPrimary,
                                'Source',
                                _renewal!.source?.isNotEmpty == true
                                    ? _renewal!.source!
                                    : '—',
                              ),
                              _row(
                                textSecondary,
                                textPrimary,
                                'Renewal date',
                                _fmt(_renewal!.renewalDate),
                              ),
                              if (_renewal!.kamUser != null)
                                _row(
                                  textSecondary,
                                  textPrimary,
                                  'KAM',
                                  _renewal!.kamUser!.name,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _row(
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
            width: 110,
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
