import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/group_providers.dart';

class PersonEditScreen extends ConsumerStatefulWidget {
  final int? personId;

  const PersonEditScreen({super.key, required this.personId});

  @override
  ConsumerState<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends ConsumerState<PersonEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Basic info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _otherNamesController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _birthDate;
  DateTime? _baptismDate;
  Gender _gender = Gender.unknown;
  HopeClass _hopeClass = HopeClass.unknown;
  CongregationRole _congregationRole = CongregationRole.none;
  PioneerType _pioneerType = PioneerType.none;
  bool _isActive = true;
  DateTime? _inactiveDate;
  int? _fieldServiceGroupId;

  // Related data
  List<_PhoneNumberEntry> _phoneNumbers = [];
  List<_EmergencyContactEntry> _emergencyContacts = [];
  List<_AuxPioneerEntry> _auxPioneerPeriods = [];

  // Service reports
  List<_ServiceReportEntry> _serviceReports = [];
  int? _filterYear;
  late int _newServiceYear;
  late TextEditingController _newYearController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final now = DateTime.now();
    _newServiceYear = now.month >= 9 ? now.year + 1 : now.year;
    _newYearController = TextEditingController(text: '$_newServiceYear');
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.personId != null) {
      final db = ref.read(databaseProvider);
      final person = await db.getPerson(widget.personId!);
      final phones = await db.getPhoneNumbers(widget.personId!);
      final contacts = await db.getEmergencyContacts(widget.personId!);
      final periods = await db.getAuxiliaryPioneerPeriods(widget.personId!);
      final reports = await db.getServiceReports(personId: widget.personId!);

      if (!mounted) return;
      setState(() {
        _firstNameController.text = person.firstName;
        _lastNameController.text = person.lastName;
        _otherNamesController.text = person.otherNames;
        _addressController.text = person.address;
        _birthDate = person.birthDate;
        _baptismDate = person.baptismDate;
        _gender = person.gender;
        _hopeClass = person.hopeClass;
        _congregationRole = person.congregationRole;
        _pioneerType = person.pioneerType;
        _isActive = person.isActive;
        _inactiveDate = person.inactiveDate;
        _fieldServiceGroupId = person.fieldServiceGroupId;
        _phoneNumbers = phones
            .map(
              (p) => _PhoneNumberEntry(
                id: p.id,
                numberController: TextEditingController(text: p.number),
                phoneType: p.phoneType,
                isPrimary: p.isPrimary,
              ),
            )
            .toList();
        _emergencyContacts = contacts
            .map(
              (c) => _EmergencyContactEntry(
                id: c.id,
                nameController: TextEditingController(text: c.name),
                phoneController: TextEditingController(text: c.phoneNumber),
                relationship: c.relationship,
                isPrimary: c.isPrimary,
              ),
            )
            .toList();
        _auxPioneerPeriods = periods
            .map(
              (a) => _AuxPioneerEntry(
                id: a.id,
                startMonth: a.startMonth,
                startYear: a.startYear,
                endMonth: a.endMonth,
                endYear: a.endYear,
              ),
            )
            .toList();
        _serviceReports = reports
            .map(
              (r) => _ServiceReportEntry(
                id: r.id,
                year: r.year,
                month: r.month,
                sharedInMinistry: r.sharedInMinistry,
                bibleStudies: r.bibleStudies,
                isAuxiliaryPioneer: r.isAuxiliaryPioneer,
                hours: r.hours,
                note: r.note,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otherNamesController.dispose();
    _addressController.dispose();
    _newYearController.dispose();
    for (final p in _phoneNumbers) {
      p.numberController.dispose();
    }
    for (final c in _emergencyContacts) {
      c.nameController.dispose();
      c.phoneController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.personId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Publisher' : 'Edit Publisher'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _save,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Phone Numbers'),
            Tab(text: 'Emergency Contacts'),
            Tab(text: 'Pioneer Periods'),
            Tab(text: 'Field Service Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildPhoneNumbersTab(),
                  _buildEmergencyContactsTab(),
                  _buildPioneerPeriodsTab(),
                  _buildFieldServiceReportsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoTab() {
    final groups = ref.watch(fieldServiceGroupsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 400;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _responsiveRow(isWide, [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherNamesController,
                decoration: const InputDecoration(
                  labelText: 'Other Names',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _responsiveRow(isWide, [
                _DatePickerField(
                  label: 'Date of Birth',
                  value: _birthDate,
                  onChanged: (d) => setState(() => _birthDate = d),
                ),
                _DatePickerField(
                  label: 'Baptism Date',
                  value: _baptismDate,
                  onChanged: (d) => setState(() => _baptismDate = d),
                ),
              ]),
              const SizedBox(height: 16),
              _responsiveRow(isWide, [
                DropdownButtonFormField<Gender>(
                  isExpanded: true,
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: Gender.values
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _gender = v ?? Gender.unknown),
                ),
                DropdownButtonFormField<HopeClass>(
                  isExpanded: true,
                  initialValue: _hopeClass,
                  decoration: const InputDecoration(
                    labelText: 'Hope',
                    border: OutlineInputBorder(),
                  ),
                  items: HopeClass.values
                      .map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Text(h.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _hopeClass = v ?? HopeClass.unknown),
                ),
              ]),
              const SizedBox(height: 12),
              _responsiveRow(isWide, [
                DropdownButtonFormField<CongregationRole>(
                  isExpanded: true,
                  initialValue: _congregationRole,
                  decoration: const InputDecoration(
                    labelText: 'Congregation Role',
                    border: OutlineInputBorder(),
                  ),
                  items: CongregationRole.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(
                    () => _congregationRole = v ?? CongregationRole.none,
                  ),
                ),
                DropdownButtonFormField<PioneerType>(
                  isExpanded: true,
                  initialValue: _pioneerType,
                  decoration: const InputDecoration(
                    labelText: 'Pioneer Type',
                    border: OutlineInputBorder(),
                  ),
                  items: PioneerType.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _pioneerType = v ?? PioneerType.none),
                ),
              ]),
              const SizedBox(height: 12),
              groups.when(
                data: (groupList) => DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _fieldServiceGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Field Service Group',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...groupList.map(
                      (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _fieldServiceGroupId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Error loading groups'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() {
                  _isActive = v;
                  if (!v && _inactiveDate == null) {
                    _inactiveDate = DateTime.now();
                  } else if (v) {
                    _inactiveDate = null;
                  }
                }),
              ),
              if (!_isActive)
                ListTile(
                  title: const Text('Inactive Since'),
                  subtitle: Text(
                    _inactiveDate != null
                        ? DateFormat.yMMMd().format(_inactiveDate!)
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _inactiveDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _inactiveDate = picked);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _responsiveRow(bool isWide, List<Widget> children) {
    if (isWide) {
      return Row(
        children:
            children
                .expand(
                  (child) => [
                    Expanded(child: child),
                    const SizedBox(width: 12),
                  ],
                )
                .toList()
              ..removeLast(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          children
              .expand((child) => [child, const SizedBox(height: 12)])
              .toList()
            ..removeLast(),
    );
  }

  Widget _buildPhoneNumbersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('Add Phone'),
                onPressed: () {
                  setState(() {
                    _phoneNumbers.add(
                      _PhoneNumberEntry(
                        numberController: TextEditingController(),
                      ),
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _phoneNumbers.length,
              itemBuilder: (context, index) {
                final entry = _phoneNumbers[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: entry.numberController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<PhoneType>(
                            initialValue: entry.phoneType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: PhoneType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => entry.phoneType = v ?? PhoneType.mobile,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: entry.isPrimary,
                          onChanged: (v) =>
                              setState(() => entry.isPrimary = v ?? false),
                        ),
                        const Text('Primary'),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              setState(() => _phoneNumbers.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('Add Contact'),
                onPressed: () {
                  setState(() {
                    _emergencyContacts.add(
                      _EmergencyContactEntry(
                        nameController: TextEditingController(),
                        phoneController: TextEditingController(),
                      ),
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _emergencyContacts.length,
              itemBuilder: (context, index) {
                final entry = _emergencyContacts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: entry.nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: entry.phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Relationship>(
                                initialValue: entry.relationship,
                                decoration: const InputDecoration(
                                  labelText: 'Relationship',
                                  border: OutlineInputBorder(),
                                ),
                                items: Relationship.values
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r.displayName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => entry.relationship =
                                      v ?? Relationship.other,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Checkbox(
                              value: entry.isPrimary,
                              onChanged: (v) =>
                                  setState(() => entry.isPrimary = v ?? false),
                            ),
                            const Text('Primary'),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(
                                () => _emergencyContacts.removeAt(index),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPioneerPeriodsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('Add Period'),
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _auxPioneerPeriods.add(
                      _AuxPioneerEntry(
                        startMonth: now.month,
                        startYear: now.year,
                      ),
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _auxPioneerPeriods.length,
              itemBuilder: (context, index) {
                final entry = _auxPioneerPeriods[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MonthYearPicker(
                            label: 'Start',
                            month: entry.startMonth,
                            year: entry.startYear,
                            onMonthChanged: (m) => setState(
                              () => entry.startMonth = m ?? entry.startMonth,
                            ),
                            onYearChanged: (y) => setState(
                              () => entry.startYear = y ?? entry.startYear,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MonthYearPicker(
                            label: 'End (optional)',
                            month: entry.endMonth,
                            year: entry.endYear,
                            allowNull: true,
                            onMonthChanged: (m) =>
                                setState(() => entry.endMonth = m),
                            onYearChanged: (y) =>
                                setState(() => entry.endYear = y),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(
                            () => _auxPioneerPeriods.removeAt(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Service year month ordering: Sep, Oct, Nov, Dec, Jan, Feb, Mar, Apr, May, Jun, Jul, Aug
  // ──────────────────────────────────────────────────
  static const _serviceYearMonths = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8];

  static int _serviceMonthIndex(int month) => (month + 3) % 12;

  List<int> get _availableYears {
    final years = _serviceReports.map((r) => r.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<_ServiceReportEntry> get _filteredReports {
    var reports = _serviceReports.toList();
    if (_filterYear != null) {
      reports = reports.where((r) => r.year == _filterYear).toList();
    }
    reports.sort((a, b) {
      final yearCmp = b.year.compareTo(a.year);
      if (yearCmp != 0) return yearCmp;
      return _serviceMonthIndex(b.month).compareTo(_serviceMonthIndex(a.month));
    });
    return reports;
  }

  void _addServiceYear() {
    final year = _newServiceYear;
    var added = 0;
    for (final month in _serviceYearMonths) {
      final exists = _serviceReports.any(
        (r) => r.year == year && r.month == month,
      );
      if (exists) continue;
      _serviceReports.add(_ServiceReportEntry(year: year, month: month));
      added++;
    }
    if (added > 0) setState(() {});
  }

  void _deleteServiceYear() {
    if (_filterYear == null) return;
    setState(() {
      _serviceReports.removeWhere((r) => r.year == _filterYear);
      _filterYear = null;
    });
  }

  static String _monthName(int month) =>
      DateFormat.MMMM().format(DateTime(2000, month));

  Widget _buildFieldServiceReportsTab() {
    if (widget.personId == null) {
      return const Center(
        child: Text('Save the publisher first to add service reports.'),
      );
    }

    final filtered = _filteredReports;
    final years = _availableYears;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _filterYear,
                  decoration: const InputDecoration(
                    labelText: 'Filter Year',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...years.map(
                      (y) => DropdownMenuItem(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterYear = v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Clear filter',
                onPressed: () => setState(() => _filterYear = null),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _newYearController,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) _newServiceYear = parsed;
                  },
                ),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('Add Year'),
                onPressed: _addServiceYear,
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete Year'),
                onPressed: _filterYear != null ? _deleteServiceYear : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No service reports.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return _buildReportCards(filtered);
                      }
                      return _buildReportTable(filtered);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCards(List<_ServiceReportEntry> reports) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthName(r.month)} ${r.year}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: r.sharedInMinistry,
                      onChanged: (v) =>
                          setState(() => r.sharedInMinistry = v ?? false),
                    ),
                    const Text('Shared'),
                    const SizedBox(width: 16),
                    Checkbox(
                      value: r.isAuxiliaryPioneer,
                      onChanged: (v) =>
                          setState(() => r.isAuxiliaryPioneer = v ?? false),
                    ),
                    const Text('Aux Pioneer'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: r.bibleStudies > 0
                            ? r.bibleStudies.toString()
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Studies',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => r.bibleStudies = int.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: r.hours > 0 ? r.hours.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => r.hours = double.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: r.note,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => r.note = v,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportTable(List<_ServiceReportEntry> reports) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Year')),
                DataColumn(label: Text('Month')),
                DataColumn(label: Text('Shared')),
                DataColumn(label: Text('Studies')),
                DataColumn(label: Text('Aux Pioneer')),
                DataColumn(label: Text('Hours')),
                DataColumn(label: Text('Note')),
              ],
              rows: reports.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text('${r.year}')),
                    DataCell(Text(_monthName(r.month))),
                    DataCell(
                      Checkbox(
                        value: r.sharedInMinistry,
                        onChanged: (v) =>
                            setState(() => r.sharedInMinistry = v ?? false),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: r.bibleStudies > 0
                              ? r.bibleStudies.toString()
                              : '',
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) =>
                              r.bibleStudies = int.tryParse(v) ?? 0,
                        ),
                      ),
                    ),
                    DataCell(
                      Checkbox(
                        value: r.isAuxiliaryPioneer,
                        onChanged: (v) =>
                            setState(() => r.isAuxiliaryPioneer = v ?? false),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: r.hours > 0 ? r.hours.toString() : '',
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => r.hours = double.tryParse(v) ?? 0,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: r.note,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (v) => r.note = v,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final congId = ref.read(currentCongregationIdProvider);
    final now = DateTime.now();

    // inactiveDate is managed directly by the UI toggle and date picker
    final inactiveDate = _inactiveDate;

    if (widget.personId == null) {
      // Create new person
      final personId = await db.insertPerson(
        PersonsCompanion.insert(
          firstName: drift.Value(_firstNameController.text),
          lastName: drift.Value(_lastNameController.text),
          otherNames: drift.Value(_otherNamesController.text),
          address: drift.Value(_addressController.text),
          birthDate: drift.Value(_birthDate),
          baptismDate: drift.Value(_baptismDate),
          gender: drift.Value(_gender),
          hopeClass: drift.Value(_hopeClass),
          congregationRole: drift.Value(_congregationRole),
          pioneerType: drift.Value(_pioneerType),
          isActive: drift.Value(_isActive),
          inactiveDate: drift.Value(inactiveDate),
          fieldServiceGroupId: drift.Value(_fieldServiceGroupId),
          congregationId: drift.Value(congId),
        ),
      );

      await _saveRelatedData(db, personId);
    } else {
      // Update existing
      await db.updatePerson(
        PersonsCompanion(
          id: drift.Value(widget.personId!),
          firstName: drift.Value(_firstNameController.text),
          lastName: drift.Value(_lastNameController.text),
          otherNames: drift.Value(_otherNamesController.text),
          address: drift.Value(_addressController.text),
          birthDate: drift.Value(_birthDate),
          baptismDate: drift.Value(_baptismDate),
          gender: drift.Value(_gender),
          hopeClass: drift.Value(_hopeClass),
          congregationRole: drift.Value(_congregationRole),
          pioneerType: drift.Value(_pioneerType),
          isActive: drift.Value(_isActive),
          inactiveDate: drift.Value(inactiveDate),
          fieldServiceGroupId: drift.Value(_fieldServiceGroupId),
          congregationId: drift.Value(congId),
          updatedAt: drift.Value(now),
        ),
      );

      // Replace related data
      await db.deletePhoneNumbersForPerson(widget.personId!);
      await db.deleteEmergencyContactsForPerson(widget.personId!);
      await db.deleteAuxiliaryPioneerPeriodsForPerson(widget.personId!);
      await db.deleteServiceReportsForPerson(widget.personId!);
      await _saveRelatedData(db, widget.personId!);
    }

    ref.invalidate(personsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveRelatedData(AppDatabase db, int personId) async {
    for (final phone in _phoneNumbers) {
      await db.insertPhoneNumber(
        PhoneNumbersCompanion.insert(
          number: drift.Value(phone.numberController.text),
          phoneType: drift.Value(phone.phoneType),
          isPrimary: drift.Value(phone.isPrimary),
          personId: personId,
        ),
      );
    }
    for (final contact in _emergencyContacts) {
      await db.insertEmergencyContact(
        EmergencyContactsCompanion.insert(
          name: drift.Value(contact.nameController.text),
          phoneNumber: drift.Value(contact.phoneController.text),
          relationship: drift.Value(contact.relationship),
          isPrimary: drift.Value(contact.isPrimary),
          personId: personId,
        ),
      );
    }
    for (final period in _auxPioneerPeriods) {
      await db.insertAuxiliaryPioneerPeriod(
        AuxiliaryPioneerPeriodsCompanion.insert(
          startMonth: period.startMonth,
          startYear: period.startYear,
          endMonth: drift.Value(period.endMonth),
          endYear: drift.Value(period.endYear),
          personId: personId,
        ),
      );
    }
    for (final report in _serviceReports) {
      await db.insertServiceReport(
        ServiceReportsCompanion.insert(
          year: report.year,
          month: report.month,
          sharedInMinistry: drift.Value(report.sharedInMinistry),
          bibleStudies: drift.Value(report.bibleStudies),
          isAuxiliaryPioneer: drift.Value(report.isAuxiliaryPioneer),
          hours: drift.Value(report.hours),
          note: drift.Value(report.note),
          personId: personId,
        ),
      );
    }
  }
}

// ──────────────────────────────────────────────────
// Helper classes
// ──────────────────────────────────────────────────

class _PhoneNumberEntry {
  int? id;
  TextEditingController numberController;
  PhoneType phoneType;
  bool isPrimary;

  _PhoneNumberEntry({
    this.id,
    required this.numberController,
    this.phoneType = PhoneType.mobile,
    this.isPrimary = false,
  });
}

class _EmergencyContactEntry {
  int? id;
  TextEditingController nameController;
  TextEditingController phoneController;
  Relationship relationship;
  bool isPrimary;

  _EmergencyContactEntry({
    this.id,
    required this.nameController,
    required this.phoneController,
    this.relationship = Relationship.other,
    this.isPrimary = false,
  });
}

class _AuxPioneerEntry {
  int? id;
  int startMonth;
  int startYear;
  int? endMonth;
  int? endYear;

  _AuxPioneerEntry({
    this.id,
    required this.startMonth,
    required this.startYear,
    this.endMonth,
    this.endYear,
  });
}

class _ServiceReportEntry {
  int? id;
  int year;
  int month;
  bool sharedInMinistry;
  int bibleStudies;
  bool isAuxiliaryPioneer;
  double hours;
  String note;

  _ServiceReportEntry({
    this.id,
    required this.year,
    required this.month,
    this.sharedInMinistry = false,
    this.bibleStudies = 0,
    this.isAuxiliaryPioneer = false,
    this.hours = 0,
    this.note = '',
  });
}

// ──────────────────────────────────────────────────
// Reusable widgets
// ──────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? dateFormat.format(value!) : '',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _MonthYearPicker extends StatelessWidget {
  final String label;
  final int? month;
  final int? year;
  final bool allowNull;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const _MonthYearPicker({
    required this.label,
    required this.month,
    required this.year,
    this.allowNull = false,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      if (allowNull)
        const DropdownMenuItem<int?>(value: null, child: Text('–')),
      ...List.generate(
        12,
        (i) => DropdownMenuItem<int?>(
          value: i + 1,
          child: Text(DateFormat.MMMM().format(DateTime(2000, i + 1))),
        ),
      ),
    ];

    final currentYear = DateTime.now().year;
    final years = [
      if (allowNull)
        const DropdownMenuItem<int?>(value: null, child: Text('–')),
      ...List.generate(
        30,
        (i) => DropdownMenuItem<int?>(
          value: currentYear - 15 + i,
          child: Text('${currentYear - 15 + i}'),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: month,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: months,
                onChanged: onMonthChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<int?>(
                initialValue: year,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: years,
                onChanged: onYearChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
