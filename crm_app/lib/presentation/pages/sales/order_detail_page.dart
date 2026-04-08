import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../data/models/company_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/crm_card.dart';
import '../../widgets/crm_text_field.dart';
import '../../widgets/error_widget.dart' as app_widgets;
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'sale_detail_page.dart';

const _kOrderStatusKeys = <String>[
  '',
  'pending',
  'open',
  'in_progress',
  'completed',
];

const _kNextActionKeys = <String>[
  '',
  'follow_up',
  'prepare_documents',
  'confirm_delivery',
  'renewal',
];

String _titleCaseSnake(String s) {
  if (s.isEmpty) return s;
  return s.split('_').map((w) {
    if (w.isEmpty) return w;
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }).join(' ');
}

String _labelOrderStatus(String key) {
  if (key.isEmpty) return 'No status';
  return _titleCaseSnake(key);
}

String _labelNextAction(String key) {
  if (key.isEmpty) return 'None';
  return _titleCaseSnake(key);
}

String _normalizeStatus(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final t = raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  if (_kOrderStatusKeys.contains(t)) return t;
  for (final k in _kOrderStatusKeys) {
    if (k.isNotEmpty && _labelOrderStatus(k).toLowerCase() == raw.toLowerCase()) {
      return k;
    }
  }
  return t;
}

String _normalizeNextAction(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final t = raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  if (_kNextActionKeys.contains(t)) return t;
  for (final k in _kNextActionKeys) {
    if (k.isNotEmpty && _labelNextAction(k).toLowerCase() == raw.toLowerCase()) {
      return k;
    }
  }
  return t;
}

List<String> _keysWithUnknown(List<String> base, String current) {
  final out = List<String>.from(base);
  if (current.isNotEmpty && !out.contains(current)) {
    out.add(current);
  }
  return out;
}

/// Matches funnel status pill accents on [SaleDetailPage] (`_buildStatusButton`).
Color _orderStatusChipAccent(ColorScheme cs, String key) {
  switch (key) {
    case '':
      return cs.outline;
    case 'pending':
      return cs.secondary;
    case 'completed':
      return cs.tertiary;
    case 'open':
    case 'in_progress':
    default:
      return cs.primary;
  }
}

/// Distinct accents for “next to do” chips (same pill shell as status).
Color _nextToDoChipAccent(ColorScheme cs, String key) {
  switch (key) {
    case '':
      return cs.outline;
    case 'prepare_documents':
      return cs.secondary;
    case 'confirm_delivery':
    case 'renewal':
      return cs.tertiary;
    case 'follow_up':
    default:
      return cs.primary;
  }
}

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  static const _kAllowedAttachmentExts = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'svg',
  ];

  Order? _order;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  String _statusKey = '';
  String _nextActionKey = '';
  DateTime? _nextActionDate;
  String _forwardedToId = '';
  String? _attachmentFileName;
  String? _attachmentData;

  final TextEditingController _scopeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _scopeController.dispose();
    super.dispose();
  }

  void _applyOrderToForm(Order o) {
    _statusKey = _normalizeStatus(o.status);
    _nextActionKey = _normalizeNextAction(o.nextAction);
    _nextActionDate = o.nextActionDate;
    _forwardedToId = (o.forwardedTo ?? '').trim();
    _scopeController.text = o.orderDetails ?? '';
    _attachmentFileName = null;
    _attachmentData = null;
  }

  bool get _dirty {
    final o = _order;
    if (o == null) return false;
    if (_normalizeStatus(o.status) != _statusKey) return true;
    if (_normalizeNextAction(o.nextAction) != _nextActionKey) return true;
    if (!_sameDate(o.nextActionDate, _nextActionDate)) return true;
    if ((o.forwardedTo ?? '') != _forwardedToId) return true;
    if ((_attachmentData?.isNotEmpty ?? false) &&
        (_attachmentFileName?.isNotEmpty ?? false)) {
      return true;
    }
    return false;
  }

  bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      var o =
          await ref.read(orderRepositoryProvider).getOrderById(widget.orderId);
      o = await _enrichOrder(o);
      if (mounted) {
        setState(() {
          _order = o;
          _error = null;
          _applyOrderToForm(o);
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (silent && _order != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not refresh order. ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final o = _order;
    if (o == null || !_dirty) return;
    setState(() => _saving = true);
    try {
      List<dynamic>? nextAttachments;
      final newName = _attachmentFileName?.trim() ?? '';
      final newData = _attachmentData?.trim() ?? '';
      if (newName.isNotEmpty && newData.isNotEmpty) {
        nextAttachments = [
          ...(o.attachments ?? const <dynamic>[]),
          {'fileName': newName, 'data': newData},
        ];
      }
      await ref.read(orderRepositoryProvider).patchOrder(
            id: o.id,
            status: _statusKey.isEmpty ? null : _statusKey,
            nextAction: _nextActionKey.isEmpty ? null : _nextActionKey,
            nextActionDate: _nextActionDate,
            forwardedTo: _forwardedToId.isEmpty ? '' : _forwardedToId,
            attachments: nextAttachments,
          );
      await ref.read(ordersProvider.notifier).loadOrders();
      if (!mounted) return;
      await _load(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAttachment() async {
    final r = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: _kAllowedAttachmentExts,
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    final dataUrl = _buildDataUrlForFile(f.name, bytes);
    if (dataUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unsupported file type. Use PDF/JPG/JPEG/PNG/SVG.'),
        ),
      );
      return;
    }
    setState(() {
      _attachmentFileName = f.name;
      _attachmentData = dataUrl;
    });
  }

  String? _buildDataUrlForFile(String fileName, List<int> bytes) {
    final ext = fileName.split('.').last.toLowerCase().trim();
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'svg' => 'image/svg+xml',
      _ => '',
    };
    if (mime.isEmpty) return null;
    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  String _attachmentLabel(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final name = (m['fileName'] ?? m['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
      final url = (m['url'] ?? m['path'] ?? '').toString().trim();
      if (url.isNotEmpty) return url;
    }
    final s = raw?.toString().trim() ?? '';
    return s.isEmpty ? 'Attachment' : s;
  }

  String? _attachmentOpenTarget(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final v = (m['url'] ??
              m['path'] ??
              m['attachmentUrl'] ??
              m['attachment_url'] ??
              m['data'])
          ?.toString()
          .trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final s = raw?.toString().trim() ?? '';
    if (s.startsWith('http://') ||
        s.startsWith('https://') ||
        s.startsWith('data:')) {
      return s;
    }
    return null;
  }

  Future<void> _openAttachment(dynamic raw) async {
    final target = _attachmentOpenTarget(raw);
    if (target == null || target.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment preview is unavailable.')),
      );
      return;
    }

    if (target.startsWith('data:image/')) {
      final comma = target.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(target.substring(comma + 1));
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => Dialog(
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          );
          return;
        } catch (_) {}
      }
    }

    final uri = Uri.tryParse(target);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this attachment.')),
    );
  }

  Future<void> _downloadAttachment(dynamic raw) async {
    final target = _attachmentOpenTarget(raw);
    if (target == null || target.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment preview is unavailable.')),
      );
      return;
    }
    if (target.startsWith('data:')) {
      try {
        final uriData = UriData.parse(target);
        final bytes = uriData.contentAsBytes();
        final ext = switch (uriData.mimeType) {
          'application/pdf' => 'pdf',
          'image/jpeg' => 'jpg',
          'image/png' => 'png',
          'image/svg+xml' => 'svg',
          _ => 'bin',
        };
        final suggestedName = (() {
          if (raw is Map) {
            final m = Map<String, dynamic>.from(raw);
            final name = (m['fileName'] ?? m['name'] ?? '').toString().trim();
            if (name.isNotEmpty) return name;
          }
          return 'order_attachment.$ext';
        })();
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save attachment',
          fileName: suggestedName,
          bytes: bytes,
        );
        if (!mounted) return;
        if (savePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attachment saved to $savePath')),
          );
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this attachment.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(target);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not start attachment download.')),
    );
  }

  Future<Order> _enrichOrder(Order o) async {
    final companyIds = <String>{};
    final userIds = <String>{};
    if (o.companyId != null && o.company == null) {
      companyIds.add(o.companyId!);
    }
    if (o.assignTo != null && o.assignToUser == null) {
      userIds.add(o.assignTo!);
    }
    if (o.forwardedTo != null && o.forwardedToUser == null) {
      userIds.add(o.forwardedTo!);
    }
    if (companyIds.isEmpty && userIds.isEmpty) return o;

    final companiesFuture = companyIds.isNotEmpty
        ? ref.read(companyRepositoryProvider).getCompaniesByIds(
              companyIds.toList(),
            )
        : Future.value(<String, Company>{});
    final usersFuture = userIds.isNotEmpty
        ? ref.read(userRepositoryProvider).getUsersByIds(userIds.toList())
        : Future.value(<String, User>{});

    final results = await Future.wait([companiesFuture, usersFuture]);
    final companiesMap = results[0] as Map<String, Company>;
    final usersMap = results[1] as Map<String, User>;

    Company? company = o.company;
    if (company == null && o.companyId != null) {
      company = companiesMap[o.companyId];
    }
    User? assignUser = o.assignToUser;
    if (assignUser == null && o.assignTo != null) {
      assignUser = usersMap[o.assignTo];
    }
    User? fwdUser = o.forwardedToUser;
    if (fwdUser == null && o.forwardedTo != null) {
      fwdUser = usersMap[o.forwardedTo];
    }
    return o.copyWith(
      company: company,
      assignToUser: assignUser,
      forwardedToUser: fwdUser,
    );
  }

  List<DropdownMenuItem<String>> _forwardDropdownItems(List<User> users) {
    final validUsers = users.where((u) => u.id.trim().isNotEmpty).toList();
    final ids = validUsers.map((u) => u.id).toSet();
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('Not forwarded')),
      ...validUsers.map(
        (u) => DropdownMenuItem<String>(value: u.id, child: Text(u.name)),
      ),
    ];
    final fid = _forwardedToId;
    if (fid.isNotEmpty && !ids.contains(fid)) {
      items.add(
        DropdownMenuItem<String>(
          value: fid,
          child: Text(_order?.forwardedToUser?.name ?? fid),
        ),
      );
    }
    return items;
  }

  Future<void> _pickNextActionDue() async {
    final now = DateTime.now();
    final initial = _nextActionDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _nextActionDate = picked);
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _fmtFooter(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('d MMM y').format(d);
  }

  String _formatYmd(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Outlined fields — same border treatment as [OrderFormPage] date rows.
  InputDecoration _outlineFieldDecoration(
    BuildContext context, {
    String? label,
    Widget? suffixIcon,
  }) {
    final b = AppThemeColors.borderColor(context);
    return InputDecoration(
      labelText: label,
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: b),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: b),
      ),
    );
  }

  /// Same pill UI as [SaleDetailPage] `_buildStatusButton`.
  Widget _workflowPill({
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

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final textTertiary = AppThemeColors.textTertiaryColor(context);
    final primary = Theme.of(context).colorScheme.primary;
    final usersState = ref.watch(usersProvider);
    final users = usersState.users;

    return Scaffold(
      backgroundColor: AppThemeColors.backgroundColor(context),
      appBar: AppThemeColors.appBarTitle(
        context,
        'Order details',
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_order != null && !_loading && _error == null) ...[
            if (_dirty)
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : const Text('Save'),
              ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : () => _load(silent: true),
            ),
          ],
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? app_widgets.ErrorWidget(message: _error!, onRetry: _load)
              : _order == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: () => _load(silent: true),
                      child: ListView(
                        padding: AppThemeColors.pagePaddingAll,
                        children: [
                          CRMCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _order!.company?.name ?? 'Order',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _order!.orderDetails?.trim().isNotEmpty == true
                                      ? _order!.orderDetails!
                                      : '—',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (_statusKey.isNotEmpty)
                                      StatusBadge(
                                        status: _statusKey,
                                        type: 'sale',
                                      )
                                    else
                                      Text(
                                        'No status',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textTertiary,
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      _order!.formattedRevenue,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CRMCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dates & assignment',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _row(
                                  textSecondary,
                                  textPrimary,
                                  'Order date',
                                  _fmt(_order!.orderConfirmationDate),
                                ),
                                _row(
                                  textSecondary,
                                  textPrimary,
                                  'Delivery',
                                  _fmt(_order!.deliveryDate),
                                ),
                                _row(
                                  textSecondary,
                                  textPrimary,
                                  'Assign to',
                                  _order!.assignToUser?.name ?? '—',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CRMCard(
                            child: CRMTextField(
                              label: 'Order scope',
                              controller: _scopeController,
                              maxLines: 4,
                              enabled: false,
                              disableAutofill: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CRMCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if ((_order!.attachments ?? const <dynamic>[])
                                    .isNotEmpty) ...[
                                  ...(_order!.attachments ?? const <dynamic>[])
                                      .map(
                                        (a) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: InkWell(
                                            onTap: () => _openAttachment(a),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.attach_file,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          _attachmentLabel(a),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: textPrimary,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.open_in_new,
                                                        size: 14,
                                                        color: textSecondary,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _downloadAttachment(a),
                                                      icon: const Icon(
                                                        Icons.download_rounded,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Download',
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        visualDensity:
                                                            VisualDensity.compact,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 8,
                                                            ),
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  const SizedBox(height: 8),
                                ],
                                if ((_order!.attachments ?? const <dynamic>[])
                                    .isEmpty) ...[
                                  OutlinedButton.icon(
                                    onPressed: _pickAttachment,
                                    icon: const Icon(Icons.upload_file, size: 18),
                                    label: Text(
                                      _attachmentFileName == null ||
                                              _attachmentFileName!.isEmpty
                                          ? 'Add attachment'
                                          : _attachmentFileName!,
                                    ),
                                  ),
                                  if (_attachmentFileName != null &&
                                      _attachmentFileName!.isNotEmpty)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _attachmentFileName = null;
                                            _attachmentData = null;
                                          });
                                        },
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Clear'),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CRMCard(
                            child: Builder(
                              builder: (context) {
                                final cs = Theme.of(context).colorScheme;
                                final statusKeys = _keysWithUnknown(
                                  _kOrderStatusKeys,
                                  _statusKey,
                                );
                                final nextKeys = _keysWithUnknown(
                                  _kNextActionKeys,
                                  _nextActionKey,
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Workflow',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Status',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: statusKeys.map((k) {
                                        final label = k.isEmpty
                                            ? _labelOrderStatus(k)
                                            : (_kOrderStatusKeys.contains(k)
                                                ? _labelOrderStatus(k)
                                                : _titleCaseSnake(k));
                                        final accent =
                                            _orderStatusChipAccent(cs, k);
                                        return _workflowPill(
                                          label: label,
                                          selected: _statusKey == k,
                                          accent: accent,
                                          textPrimary: textPrimary,
                                          onTap: () =>
                                              setState(() => _statusKey = k),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Next to do',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: nextKeys.map((k) {
                                        final label = k.isEmpty
                                            ? _labelNextAction(k)
                                            : (_kNextActionKeys.contains(k)
                                                ? _labelNextAction(k)
                                                : _titleCaseSnake(k));
                                        final accent =
                                            _nextToDoChipAccent(cs, k);
                                        return _workflowPill(
                                          label: label,
                                          selected: _nextActionKey == k,
                                          accent: accent,
                                          textPrimary: textPrimary,
                                          onTap: () => setState(
                                            () => _nextActionKey = k,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _pickNextActionDue,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InputDecorator(
                                          decoration:
                                              _outlineFieldDecoration(
                                            context,
                                            label: 'Next to do due date',
                                            suffixIcon: Icon(
                                              Icons.calendar_month_rounded,
                                              color: primary,
                                            ),
                                          ),
                                          child: Text(
                                            _nextActionDate != null
                                                ? _formatYmd(_nextActionDate!)
                                                : 'Select date',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _nextActionDate != null
                                                  ? textPrimary
                                                  : textSecondary,
                                              fontWeight:
                                                  _nextActionDate != null
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          CRMCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'People',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_order!.createdByUser != null) ...[
                                  _row(
                                    textSecondary,
                                    textPrimary,
                                    'Assign by',
                                    _order!.createdByUser!.name,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Builder(
                                  builder: (context) {
                                    final fwdItems = _forwardDropdownItems(users);
                                    final fwdVal = fwdItems
                                            .any((e) => e.value == _forwardedToId)
                                        ? _forwardedToId
                                        : '';
                                    return InputDecorator(
                                      decoration: _outlineFieldDecoration(
                                        context,
                                        label: 'Forwarded to',
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: fwdVal,
                                          items: fwdItems,
                                          onChanged: (v) => setState(
                                                () => _forwardedToId =
                                                    (v ?? '').trim(),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_order!.salesId != null &&
                              _order!.salesId!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            CRMCard(
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) => SaleDetailPage(
                                      saleId: _order!.salesId!,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.filter_alt_outlined, color: primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Linked funnel deal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Open related deal',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: textTertiary),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Created ${_fmtFooter(_order!.createdAt)} · Updated ${_fmtFooter(_order!.updatedAt)}',
                            style: TextStyle(fontSize: 12, color: textTertiary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ID · ${_order!.id}',
                            style: TextStyle(fontSize: 11, color: textTertiary),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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
