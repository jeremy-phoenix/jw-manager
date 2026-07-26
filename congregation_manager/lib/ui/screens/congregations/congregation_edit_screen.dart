import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';

class CongregationEditScreen extends ConsumerStatefulWidget {
  final int? congregationId;

  const CongregationEditScreen({super.key, required this.congregationId});

  @override
  ConsumerState<CongregationEditScreen> createState() =>
      _CongregationEditScreenState();
}

class _CongregationEditScreenState
    extends ConsumerState<CongregationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _cityController = TextEditingController();
  final _circuitController = TextEditingController();
  final _coNameController = TextEditingController();
  final _coSpouseController = TextEditingController();
  final _coPhoneController = TextEditingController();
  final _coEmailController = TextEditingController();
  final _coAddressController = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.congregationId != null) {
      _loadCongregation();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadCongregation() async {
    final db = ref.read(databaseProvider);
    final cong = await db.getCongregation(widget.congregationId!);
    _nameController.text = cong.name;
    _numberController.text = cong.number;
    _cityController.text = cong.city;
    _circuitController.text = cong.circuitNumber;
    _coNameController.text = cong.circuitOverseerName;
    _coSpouseController.text = cong.circuitOverseerSpouseName;
    _coPhoneController.text = cong.circuitOverseerPhone;
    _coEmailController.text = cong.circuitOverseerEmail;
    _coAddressController.text = cong.circuitOverseerAddress;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _cityController.dispose();
    _circuitController.dispose();
    _coNameController.dispose();
    _coSpouseController.dispose();
    _coPhoneController.dispose();
    _coEmailController.dispose();
    _coAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.congregationId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Congregation' : 'Edit Congregation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Congregation Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _numberController,
                          decoration: const InputDecoration(
                            labelText: 'Congregation Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _circuitController,
                          decoration: const InputDecoration(
                            labelText: 'Circuit Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.route),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Circuit Overseer',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _coNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _coSpouseController,
                          decoration: const InputDecoration(
                            labelText: "Spouse's Name",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _coPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _coEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty || v.contains('@'))
                                  ? null
                                  : 'Enter a valid email address',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _coAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.home),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);

    if (widget.congregationId == null) {
      final id = await db.insertCongregation(CongregationsCompanion.insert(
        name: drift.Value(_nameController.text.trim()),
        number: drift.Value(_numberController.text.trim()),
        city: drift.Value(_cityController.text.trim()),
        circuitNumber: drift.Value(_circuitController.text.trim()),
        circuitOverseerName: drift.Value(_coNameController.text.trim()),
        circuitOverseerSpouseName: drift.Value(_coSpouseController.text.trim()),
        circuitOverseerPhone: drift.Value(_coPhoneController.text.trim()),
        circuitOverseerEmail: drift.Value(_coEmailController.text.trim()),
        circuitOverseerAddress: drift.Value(_coAddressController.text.trim()),
      ));
      // Auto-select the newly created congregation
      await ref.read(currentCongregationIdProvider.notifier).set(id);
    } else {
      await db.updateCongregation(CongregationsCompanion(
        id: drift.Value(widget.congregationId!),
        name: drift.Value(_nameController.text.trim()),
        number: drift.Value(_numberController.text.trim()),
        city: drift.Value(_cityController.text.trim()),
        circuitNumber: drift.Value(_circuitController.text.trim()),
        circuitOverseerName: drift.Value(_coNameController.text.trim()),
        circuitOverseerSpouseName: drift.Value(_coSpouseController.text.trim()),
        circuitOverseerPhone: drift.Value(_coPhoneController.text.trim()),
        circuitOverseerEmail: drift.Value(_coEmailController.text.trim()),
        circuitOverseerAddress: drift.Value(_coAddressController.text.trim()),
        updatedAt: drift.Value(DateTime.now()),
      ));
    }

    ref.invalidate(congregationsProvider);
    if (mounted) Navigator.of(context).pop();
  }
}
