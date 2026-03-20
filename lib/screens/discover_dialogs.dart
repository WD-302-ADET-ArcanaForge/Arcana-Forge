part of 'discover_screen.dart';

class _DiscoverFilterSheet extends StatefulWidget {
  const _DiscoverFilterSheet({
    required this.selectedGameTypes,
    required this.selectedSessionTypes,
    required this.selectedVenueTypes,
    required this.onlyJoinableSessions,
    required this.availableGameTypes,
    required this.availableSessionTypes,
    required this.availableVenueTypes,
    required this.venueTypeLabelBuilder,
  });

  final Set<String> selectedGameTypes;
  final Set<String> selectedSessionTypes;
  final Set<String> selectedVenueTypes;
  final bool onlyJoinableSessions;
  final List<String> availableGameTypes;
  final List<String> availableSessionTypes;
  final List<String> availableVenueTypes;
  final String Function(String) venueTypeLabelBuilder;

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  late Set<String> _selectedGameTypes;
  late Set<String> _selectedSessionTypes;
  late Set<String> _selectedVenueTypes;
  late bool _onlyJoinable;

  @override
  void initState() {
    super.initState();
    _selectedGameTypes = Set<String>.from(widget.selectedGameTypes);
    _selectedSessionTypes = Set<String>.from(widget.selectedSessionTypes);
    _selectedVenueTypes = Set<String>.from(widget.selectedVenueTypes);
    _onlyJoinable = widget.onlyJoinableSessions;
  }

  void _toggleValue(Set<String> target, String value) {
    setState(() {
      if (!target.add(value)) {
        target.remove(value);
      }
    });
  }

  Widget _buildChips({
    required String title,
    required List<String> values,
    required Set<String> selected,
    required void Function(String) onTap,
    String Function(String)? labelBuilder,
  }) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final isSelected = selected.contains(value);
              return FilterChip(
                selected: isSelected,
                label: Text(labelBuilder?.call(value) ?? value),
                onSelected: (_) => onTap(value),
                selectedColor: const Color(0xFFAA00FF),
                backgroundColor: const Color(0xFF2D1B4E),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: const BorderSide(color: Color(0xFF7A52B5)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Only Joinable Sessions',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Hide full sessions and sessions you already joined.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      activeColor: const Color(0xFFAA00FF),
                      value: _onlyJoinable,
                      onChanged: (value) => setState(() => _onlyJoinable = value),
                    ),
                    const Divider(color: Colors.white12),
                    _buildChips(
                      title: 'Game Type',
                      values: widget.availableGameTypes,
                      selected: _selectedGameTypes,
                      onTap: (value) => _toggleValue(_selectedGameTypes, value),
                    ),
                    _buildChips(
                      title: 'Session Type',
                      values: widget.availableSessionTypes,
                      selected: _selectedSessionTypes,
                      onTap: (value) => _toggleValue(_selectedSessionTypes, value),
                    ),
                    _buildChips(
                      title: 'Venue Mode',
                      values: widget.availableVenueTypes,
                      selected: _selectedVenueTypes,
                      onTap: (value) => _toggleValue(_selectedVenueTypes, value),
                      labelBuilder: widget.venueTypeLabelBuilder,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedGameTypes.clear();
                      _selectedSessionTypes.clear();
                      _selectedVenueTypes.clear();
                      _onlyJoinable = false;
                    });
                  },
                  child: const Text('Clear All'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _DiscoverFilterDraft(
                        gameTypes: _selectedGameTypes,
                        sessionTypes: _selectedSessionTypes,
                        venueTypes: _selectedVenueTypes,
                        onlyJoinable: _onlyJoinable,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFAA00FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSheetEmptyState extends StatelessWidget {
  const _StatSheetEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog({
    this.title = 'Create Session',
    this.submitLabel = 'Create',
    this.initialSession,
    this.venueSuggestions = const [],
  });

  final String title;
  final String submitLabel;
  final _SessionItem? initialSession;
  final List<String> venueSuggestions;

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  static const List<String> _gameTypeOptions = [
    'DND',
    'Pathfinder',
    'MTG',
    'Warhammer',
    'Board Games',
    'Pokemon TCG',
    'Call of Cthulhu',
    'Starfinder',
    'Other',
  ];

  static const Map<_VenueType, List<String>> _venuePresets = {
    _VenueType.inPerson: [
      'Local Game Store',
      'Public Library',
      'Community Center',
      'Cafe',
      'Host Home',
    ],
    _VenueType.online: [
      'Discord Voice Channel',
      'Zoom',
      'Google Meet',
      'Roll20',
      'Foundry VTT',
    ],
    _VenueType.hybrid: [
      'Local Store + Discord',
      'Cafe + Zoom',
      'Community Hub + Roll20',
    ],
  };

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _dateController;
  late final TextEditingController _playersController;
  late final TextEditingController _venueController;
  late final TextEditingController _provinceController;
  late final TextEditingController _customGameTypeController;
  Timer? _venueSearchDebounce;
  bool _isLoadingVenueSearch = false;
  List<String> _remoteVenueSuggestions = const [];

  late String _selectedGameType;
  late String _selectedSessionType;
  late _VenueType _selectedVenueType;

  bool get _isCustomGameType => _selectedGameType == 'Other';

  String _gameTypeForSubmit() {
    if (!_isCustomGameType) {
      return _selectedGameType;
    }

    final customValue = _customGameTypeController.text.trim();
    return customValue.isEmpty ? 'Custom Game' : customValue;
  }

  _VenueType _venueTypeFromStorage(String? value) {
    switch (value) {
      case 'online':
        return _VenueType.online;
      case 'hybrid':
        return _VenueType.hybrid;
      case 'in_person':
      default:
        return _VenueType.inPerson;
    }
  }

  String _venueTypeToStorage(_VenueType value) {
    switch (value) {
      case _VenueType.online:
        return 'online';
      case _VenueType.hybrid:
        return 'hybrid';
      case _VenueType.inPerson:
        return 'in_person';
    }
  }

  String _venueLabelForType(_VenueType value) {
    switch (value) {
      case _VenueType.online:
        return 'Online';
      case _VenueType.hybrid:
        return 'Hybrid';
      case _VenueType.inPerson:
        return 'In-Person';
    }
  }

  String _venueInputLabel() {
    switch (_selectedVenueType) {
      case _VenueType.online:
        return 'Platform or Room (e.g. Discord, Roll20)';
      case _VenueType.hybrid:
        return 'Hybrid Venue Details';
      case _VenueType.inPerson:
        return 'Venue';
    }
  }

  String _formatDateTime(DateTime value) {
    final month = _monthNames[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');
    final year = value.year;
    final hour12 = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour12:$minute $period';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (selectedTime == null) {
      return;
    }

    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      _dateController.text = _formatDateTime(combined);
    });
  }

  List<String> get _autocompleteVenueSuggestions {
    final query = _venueController.text.trim().toLowerCase();
    final suggestions = <String>[];
    final seen = <String>{};

    for (final preset in _venuePresets[_selectedVenueType]!) {
      final key = preset.toLowerCase();
      if (seen.add(key)) {
        suggestions.add(preset);
      }
    }

    for (final venue in widget.venueSuggestions) {
      final normalized = venue.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final key = normalized.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }

      if (_selectedVenueType == _VenueType.online &&
          !(key.contains('discord') ||
              key.contains('zoom') ||
              key.contains('meet') ||
              key.contains('roll20') ||
              key.contains('foundry'))) {
        continue;
      }

      suggestions.add(normalized);
    }

    for (final remote in _remoteVenueSuggestions) {
      final key = remote.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      suggestions.add(remote);
    }

    final filtered = query.isEmpty
        ? suggestions
        : suggestions.where((option) => option.toLowerCase().contains(query)).toList();

    return filtered.take(6).toList();
  }

  bool get _shouldQueryRemoteVenues {
    return _selectedVenueType == _VenueType.inPerson || _selectedVenueType == _VenueType.hybrid;
  }

  Future<List<String>> _fetchRemoteVenueSuggestions(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'limit': '6',
      'q': query,
    });

    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'ArcanaForge/1.0 (venue-search)'},
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((entry) => (entry['display_name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .take(6)
        .toList();
  }

  void _onVenueInputChanged(String value) {
    setState(() {});

    _venueSearchDebounce?.cancel();

    final query = value.trim();
    if (!_shouldQueryRemoteVenues || query.length < 3) {
      setState(() {
        _isLoadingVenueSearch = false;
        _remoteVenueSuggestions = const [];
      });
      return;
    }

    _venueSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingVenueSearch = true;
      });

      final suggestions = await _fetchRemoteVenueSuggestions(query);
      if (!mounted) {
        return;
      }

      if (_venueController.text.trim() != query) {
        setState(() {
          _isLoadingVenueSearch = false;
        });
        return;
      }

      setState(() {
        _remoteVenueSuggestions = suggestions;
        _isLoadingVenueSearch = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    final initialGameType = widget.initialSession?.gameType ?? 'DND';
    final isKnown = _gameTypeOptions.contains(initialGameType) && initialGameType != 'Other';
    _selectedGameType = isKnown ? initialGameType : 'Other';
    _selectedSessionType = widget.initialSession?.sessionType ?? 'Campaign';
    _selectedVenueType = _venueTypeFromStorage(widget.initialSession?.venueType);
    _nameController = TextEditingController(text: widget.initialSession?.name ?? '');
    _hostController = TextEditingController(text: widget.initialSession?.host ?? '');
    _dateController = TextEditingController(text: widget.initialSession?.date ?? '');
    _playersController = TextEditingController(text: widget.initialSession?.players ?? '');
    _venueController = TextEditingController(text: widget.initialSession?.venue ?? '');
    _provinceController = TextEditingController(text: widget.initialSession?.province ?? '');
    _customGameTypeController = TextEditingController(text: isKnown ? '' : initialGameType);
  }

  @override
  void dispose() {
    _venueSearchDebounce?.cancel();
    _nameController.dispose();
    _hostController.dispose();
    _dateController.dispose();
    _playersController.dispose();
    _venueController.dispose();
    _provinceController.dispose();
    _customGameTypeController.dispose();
    super.dispose();
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF2D1B4E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFAA00FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF241340),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedGameType,
                dropdownColor: const Color(0xFF2D1B4E),
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Game Type'),
                items: _gameTypeOptions
                    .map((gameType) => DropdownMenuItem(value: gameType, child: Text(gameType)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGameType = value);
                  }
                },
              ),
              if (_isCustomGameType) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customGameTypeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDecoration('Custom Game Type'),
                  validator: (value) {
                    if (_isCustomGameType && (value == null || value.trim().isEmpty)) {
                      return 'Enter a game type';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedSessionType,
                dropdownColor: const Color(0xFF2D1B4E),
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Session Type'),
                items: const [
                  DropdownMenuItem(value: 'Campaign', child: Text('Campaign')),
                  DropdownMenuItem(value: 'One Shot', child: Text('One Shot')),
                  DropdownMenuItem(value: 'Casual', child: Text('Casual')),
                  DropdownMenuItem(value: 'Competitive', child: Text('Competitive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSessionType = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Session Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a session name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hostController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Host Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a host name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                style: const TextStyle(color: Colors.white),
                readOnly: true,
                onTap: _pickDateTime,
                decoration: _dialogInputDecoration('Date and Time'),
                onChanged: (_) {},
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter date and time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _playersController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Players (e.g. 3-5 players)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter player range';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              SegmentedButton<_VenueType>(
                segments: [
                  ButtonSegment<_VenueType>(
                    value: _VenueType.inPerson,
                    label: Text(_venueLabelForType(_VenueType.inPerson)),
                    icon: const Icon(Icons.location_on_outlined, size: 16),
                  ),
                  ButtonSegment<_VenueType>(
                    value: _VenueType.online,
                    label: Text(_venueLabelForType(_VenueType.online)),
                    icon: const Icon(Icons.videocam_outlined, size: 16),
                  ),
                  ButtonSegment<_VenueType>(
                    value: _VenueType.hybrid,
                    label: Text(_venueLabelForType(_VenueType.hybrid)),
                    icon: const Icon(Icons.hub_outlined, size: 16),
                  ),
                ],
                selected: {_selectedVenueType},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedVenueType = selection.first;
                    _remoteVenueSuggestions = const [];
                    _isLoadingVenueSearch = false;
                  });
                  _onVenueInputChanged(_venueController.text);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _venueController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(_venueInputLabel()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter venue';
                  }
                  return null;
                },
                onChanged: _onVenueInputChanged,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _provinceController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: _dialogInputDecoration('Province'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter province';
                  }
                  return null;
                },
              ),
              if (_isLoadingVenueSearch)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (_autocompleteVenueSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _autocompleteVenueSuggestions
                        .map(
                          (option) => ActionChip(
                            label: Text(option),
                            onPressed: () => setState(() => _venueController.text = option),
                            backgroundColor: const Color(0xFF3A245F),
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _venuePresets[_selectedVenueType]!
                      .map(
                        (preset) => ActionChip(
                          label: Text(preset),
                          onPressed: () => setState(() => _venueController.text = preset),
                          backgroundColor: const Color(0xFF2D1B4E),
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              _SessionItemDraft(
                gameType: _gameTypeForSubmit(),
                sessionType: _selectedSessionType,
                name: _nameController.text.trim(),
                host: _hostController.text.trim(),
                date: _dateController.text.trim(),
                players: _playersController.text.trim(),
                venue: _venueController.text.trim(),
                venueType: _venueTypeToStorage(_selectedVenueType),
                province: _provinceController.text.trim(),
              ),
            );
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
