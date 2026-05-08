import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/group_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';

class GroupEditScreen extends ConsumerStatefulWidget {
  final int? groupId;

  const GroupEditScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _groupOverseerId;
  int? _assistantId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.groupId != null) {
      final db = ref.read(databaseProvider);
      final group = await db.getFieldServiceGroup(widget.groupId!);
      if (!mounted) return;
      setState(() {
        _nameController.text = group.name;
        _descriptionController.text = group.description;
        _groupOverseerId = group.groupOverseerId;
        _assistantId = group.assistantId;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.groupId == null;
    final persons = ref.watch(personsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Group' : 'Edit Group'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    persons.when(
                      data: (personList) => Column(
                        children: [
                          DropdownButtonFormField<int?>(
                            initialValue: _groupOverseerId,
                            decoration: const InputDecoration(
                              labelText: 'Group Overseer',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('None')),
                              ...personList.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(formatPersonName(
                                      p.firstName, p.lastName,
                                      ref.watch(nameOrderProvider))))),
                            ],
                            onChanged: (v) =>
                                setState(() => _groupOverseerId = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int?>(
                            initialValue: _assistantId,
                            decoration: const InputDecoration(
                              labelText: 'Assistant',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('None')),
                              ...personList.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(formatPersonName(
                                      p.firstName, p.lastName,
                                      ref.watch(nameOrderProvider))))),
                            ],
                            onChanged: (v) =>
                                setState(() => _assistantId = v),
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Error loading persons'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final congId = ref.read(currentCongregationIdProvider);

    if (widget.groupId == null) {
      await db.insertFieldServiceGroup(FieldServiceGroupsCompanion.insert(
        name: drift.Value(_nameController.text),
        description: drift.Value(_descriptionController.text),
        groupOverseerId: drift.Value(_groupOverseerId),
        assistantId: drift.Value(_assistantId),
        congregationId: drift.Value(congId),
      ));
    } else {
      await db.updateFieldServiceGroup(FieldServiceGroupsCompanion(
        id: drift.Value(widget.groupId!),
        name: drift.Value(_nameController.text),
        description: drift.Value(_descriptionController.text),
        groupOverseerId: drift.Value(_groupOverseerId),
        assistantId: drift.Value(_assistantId),
        congregationId: drift.Value(congId),
        updatedAt: drift.Value(DateTime.now()),
      ));
    }

    ref.invalidate(fieldServiceGroupsProvider);
    if (mounted) Navigator.of(context).pop();
  }
}
