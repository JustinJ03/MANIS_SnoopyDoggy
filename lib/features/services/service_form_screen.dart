import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/service.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../theme/manis_theme.dart';

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
    // shortcut: local preview only; upload to storage is M3.
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final service = Service(
      serviceId: _original?.serviceId ?? '',
      name: _name.text.trim(),
      serviceType: _type,
      priceRm: double.parse(_price.text.trim()),
      durationMax: int.parse(_duration.text.trim()),
      isActive: _active,
    );
    setState(() => _saving = true);
    try {
      await ref.read(serviceRepositoryProvider).save(service);
      ref.invalidate(servicesProvider);
      ref.invalidate(bookingsProvider);
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
              icon: const Icon(Icons.delete_outline),
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
          return _buildForm(all, enabled);
        },
      ),
    );
  }

  Widget _buildForm(List<Service> all, bool enabled) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(ManisSpace.s4),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              final name = v?.trim() ?? '';
              if (name.isEmpty) return 'Enter a name.';
              final duplicate = all.any(
                (s) =>
                    s.serviceId != _original?.serviceId &&
                    s.name.toLowerCase() == name.toLowerCase(),
              );
              return duplicate
                  ? 'A service called "$name" already exists.'
                  : null;
            },
          ),
          const SizedBox(height: ManisSpace.s4),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final t in {...serviceTypes, _type})
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
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
              final p = double.tryParse(v?.trim() ?? '');
              if (p == null) return 'Enter a price.';
              if (p <= 0) return 'Price must be more than RM 0.';
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
          SwitchListTile(
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
                child: Image.file(
                  File(path),
                  height: 180,
                  fit: BoxFit.cover,
                  semanticLabel: 'Design photo preview',
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined),
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
