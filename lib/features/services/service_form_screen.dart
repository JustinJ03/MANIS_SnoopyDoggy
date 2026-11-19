import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/service.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/readable.dart';
import '../../theme/manis_theme.dart';

const maxNameLength = 60;

/// Up to RM 9999.99, at most two decimals.
final _pricePattern = RegExp(r'^\d{1,4}(\.\d{1,2})?$');

/// Trims and collapses inner whitespace, so "Gel  Manicure " matches
/// "Gel Manicure" in the duplicate check.
String _clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Add (no [serviceId]) or edit a service.
class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({super.key, this.serviceId});
  final String? serviceId;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController(text: '$minDuration');
  var _type = serviceTypes.first;
  var _active = true;
  var _saving = false;
  Service? _original;
  var _loaded = false;
  String? _photoPath;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _load(List<Service> all) {
    if (_loaded) return;
    _loaded = true;
    final s = all.where((s) => s.serviceId == widget.serviceId).firstOrNull;
    if (s == null) return;
    _original = s;
    _name.text = s.name;
    _price.text = s.priceRm.toStringAsFixed(2);
    _duration.text = '${s.durationMax}';
    _type = s.serviceType;
    _active = s.isActive;
  }

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // shortcut: local preview only; upload to storage is M3.
      // A 12 MP camera photo is ~4032×3024; 2048 px is plenty for a design
      // reference and is the file M3 will upload.
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _photoPath = file.path);
    } catch (_) {
      // Photo access denied or the picker failed to open.
      showSnack(
        messenger,
        "Couldn't open your photos. Allow photo access for MANIS in Settings.",
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final service = Service(
      serviceId: _original?.serviceId ?? '',
      name: _clean(_name.text),
      serviceType: _type,
      priceRm: double.parse(_price.text.trim()),
      durationMax: int.parse(_duration.text.trim()),
      isActive: _active,
    );
    setState(() => _saving = true);
    try {
      await ref.read(serviceRepositoryProvider).save(service);
      // Booking providers watch servicesProvider, so names refresh too.
      ref.invalidate(servicesProvider);
      showSnack(messenger, 'Saved ${service.name}.');
      if (mounted) context.go('/more/services');
    } catch (_) {
      // Fields keep their values so the owner can retry.
      showSnack(messenger, "Couldn't save. Your changes are still here.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = _original!;
    final ok = await confirmAction(
      context,
      title: 'Delete ${s.name}?',
      message: 'If this service has bookings it will be deactivated instead, so past appointments keep their details.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final deleted = await ref
          .read(serviceRepositoryProvider)
          .delete(s.serviceId);
      ref.invalidate(servicesProvider);
      showSnack(
        messenger,
        deleted
            ? 'Deleted ${s.name}.'
            : '${s.name} has bookings, so it was deactivated instead of deleted.',
      );
      if (mounted) context.go('/more/services');
    } catch (_) {
      showSnack(messenger, "Couldn't delete. Try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    if (services.value case final all?) _load(all);
    final enabled = !_saving && ref.watch(onlineProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceId == null ? 'Add service' : 'Edit service'),
        actions: [
          if (widget.serviceId != null)
            IconButton(
              tooltip: 'Delete service',
              icon: const Icon(CupertinoIcons.delete),
              onPressed: enabled && _original != null ? _delete : null,
            ),
        ],
      ),
      body: AsyncView(
        value: services,
        onRetry: () => ref.invalidate(servicesProvider),
        builder: (all) {
          if (widget.serviceId != null && _original == null) {
            return const EmptyState('Service not found');
          }
          return Readable(
            builder: (_, insets) => _buildForm(all, enabled, insets),
          );
        },
      ),
    );
  }

  Future<void> _pickType() async {
    final type = await showCupertinoModalPopup<String>(
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: const Text('Service type'),
        actions: [
          for (final t in {...serviceTypes, _type})
            CupertinoActionSheetAction(
              isDefaultAction: t == _type,
              onPressed: () => Navigator.pop(c, t),
              child: Text(t),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (type != null) setState(() => _type = type);
  }

  Widget _buildForm(List<Service> all, bool enabled, EdgeInsets insets) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: ListView(
        padding: insets,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              final name = _clean(v ?? '');
              if (name.isEmpty) return 'Enter a name.';
              if (name.length > maxNameLength) {
                return 'Keep the name to $maxNameLength characters or fewer.';
              }
              final duplicate = all.any(
                (s) =>
                    s.serviceId != _original?.serviceId &&
                    _clean(s.name).toLowerCase() == name.toLowerCase(),
              );
              return duplicate
                  ? 'A service called "$name" already exists.'
                  : null;
            },
          ),
          const SizedBox(height: ManisSpace.s4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Type'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_type, style: text.bodyMedium),
                const Icon(CupertinoIcons.chevron_forward),
              ],
            ),
            onTap: _pickType,
          ),
          const SizedBox(height: ManisSpace.s4),
          TextFormField(
            controller: _price,
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixText: 'RM ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Enter a price.';
              // Rejects NaN, Infinity, 1e3 and sub-sen amounts that
              // double.tryParse would accept.
              if (!_pricePattern.hasMatch(s)) {
                return 'Enter a price like 60 or 60.50.';
              }
              if (double.parse(s) <= 0) return 'Price must be more than RM 0.';
              return null;
            },
          ),
          const SizedBox(height: ManisSpace.s4),
          TextFormField(
            controller: _duration,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              helperText: '$minDuration–$maxDuration minutes',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              final d = int.tryParse(v?.trim() ?? '');
              if (d == null || d < minDuration || d > maxDuration) {
                return 'Duration must be $minDuration–$maxDuration minutes.';
              }
              return null;
            },
          ),
          const SizedBox(height: ManisSpace.s2),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: Text(
              _active ? 'Bookable on WhatsApp' : 'Hidden from booking',
            ),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          const SizedBox(height: ManisSpace.s2),
          Text('Design photo', style: text.titleSmall),
          const SizedBox(height: ManisSpace.s2),
          if (_photoPath case final path?)
            Padding(
              padding: const EdgeInsets.only(bottom: ManisSpace.s2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ManisRadius.md),
                // Decode at the preview's pixel width, not the photo's:
                // ~3.5 MB in memory instead of ~48 MB for a 12 MP original.
                child: LayoutBuilder(
                  builder: (context, box) => Image.file(
                    File(path),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    cacheWidth:
                        (box.maxWidth * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    semanticLabel: 'Design photo preview',
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(CupertinoIcons.photo_on_rectangle),
              label: Text(_photoPath == null ? 'Pick photo' : 'Change photo'),
            ),
          ),
          const SizedBox(height: ManisSpace.s6),
          FilledButton(
            onPressed: enabled ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
