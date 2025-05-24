import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodHistoryScreen extends StatefulWidget {
  final String userId;

  const MoodHistoryScreen({super.key, required this.userId});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class FilterOptions {
  double minMood;
  double maxMood;
  bool onlyFavorites;
  bool onlyWithComments;
  DateTime? startDate;
  DateTime? endDate;

  FilterOptions({
    this.minMood = 0.0,
    this.maxMood = 5.0,
    this.onlyFavorites = false,
    this.onlyWithComments = false,
    this.startDate,
    this.endDate,
  });

  bool matches(Map<String, dynamic> data) {
    final moodValue = (data['moodValue'] as num).toDouble();
    final isFavorite = (data['isFavorite'] as bool?) ?? false;
    final comment = (data['comment'] as String?) ?? '';
    final timestamp = (data['timestamp'] as Timestamp).toDate();

    // Проверяем диапазон настроения (строгая проверка)
    if (!(moodValue >= minMood && moodValue <= maxMood)) {
      return false;
    }

    // Проверяем комментарии (строгая проверка на наличие текста)
    if (onlyWithComments) {
      final trimmedComment = comment.trim();
      if (trimmedComment.isEmpty) {
        return false;
      }
    }

    // Проверяем избранное
    if (onlyFavorites && !isFavorite) {
      return false;
    }

    // Проверяем диапазон дат
    if (startDate != null) {
      final startOfDay = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
      );
      if (timestamp.isBefore(startOfDay)) {
        return false;
      }
    }

    if (endDate != null) {
      final endOfDay = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23,
        59,
        59,
      );
      if (timestamp.isAfter(endOfDay)) {
        return false;
      }
    }

    return true;
  }
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, bool> _expandedDays = {};
  final ScrollController _scrollController = ScrollController();
  Map<String, List<QueryDocumentSnapshot>>? _entriesByDay;
  Map<String, List<QueryDocumentSnapshot>>? _filteredEntriesByDay;
  Map<String, dynamic>? _statistics;
  double? _savedScrollPosition;
  FilterOptions _filterOptions = FilterOptions();
  bool _isFiltered = false;
  Stream<QuerySnapshot>? _moodStream;
  bool _showCalendar = false;
  DateTime _selectedMonth = DateTime.now();
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _loadExpandedState();
    _loadScrollPosition();
    _initializeStream();

    _scrollController.addListener(() {
      _saveScrollPosition();
    });
  }

  @override
  void dispose() {
    _saveExpandedState();
    _saveScrollPosition();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final expandedDays = prefs.getStringList('expanded_days') ?? [];
    if (!mounted) return;
    setState(() {
      _expandedDays.clear();
      for (var day in expandedDays) {
        _expandedDays[day] = true;
      }
    });
  }

  Future<void> _saveExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final expandedDays =
        _expandedDays.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
    await prefs.setStringList('expanded_days', expandedDays);
  }

  Future<void> _loadScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _savedScrollPosition = prefs.getDouble('scroll_position');
    });
  }

  Future<void> _saveScrollPosition() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('scroll_position', _scrollController.offset);
  }

  void _initializeStream() {
    _moodStream = _firestoreService.getUserMoodHistory(widget.userId);
    _moodStream?.listen((QuerySnapshot snapshot) {
      if (!mounted) return;

      final entries = snapshot.docs;
      final entriesByDay = <String, List<QueryDocumentSnapshot>>{};

      for (var doc in entries) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-M-d').format(timestamp);

        if (!entriesByDay.containsKey(dateKey)) {
          entriesByDay[dateKey] = [];
        }
        entriesByDay[dateKey]!.add(doc);
      }

      // Sort entries within each day
      for (var entries in entriesByDay.values) {
        entries.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
          final bTime =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
          return bTime.compareTo(aTime);
        });
      }

      // Calculate statistics
      final stats = _calculateStatistics(entries);

      setState(() {
        _entriesByDay = entriesByDay;
        _statistics = stats;
        if (_isFiltered) {
          _applyFilter();
        }
      });
    });
  }

  Map<String, dynamic> _calculateStatistics(
    List<QueryDocumentSnapshot> entries,
  ) {
    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'averageRating': 0.0,
        'mostFrequentRating': 0.0,
      };
    }

    double sum = 0;
    Map<double, int> ratingFrequency = {};

    for (var doc in entries) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = (data['moodValue'] as num).toDouble();
      sum += rating;
      ratingFrequency[rating] = (ratingFrequency[rating] ?? 0) + 1;
    }

    // Find most frequent rating
    double mostFrequentRating =
        ratingFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'totalEntries': entries.length,
      'averageRating': (sum / entries.length).toStringAsFixed(1),
      'mostFrequentRating': mostFrequentRating.toStringAsFixed(1),
    };
  }

  String _getMoodEmoji(double value) {
    if (value >= 4) return '😄';
    if (value >= 3) return '🙂';
    if (value >= 2) return '😐';
    if (value >= 1) return '☹️';
    return '😢';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Фильтр'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Начальная дата'),
                      subtitle: Text(
                        _filterOptions.startDate != null
                            ? DateFormat(
                              'd MMMM yyyy',
                            ).format(_filterOptions.startDate!)
                            : 'Не выбрана',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _filterOptions.startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: _filterOptions.endDate ?? DateTime.now(),
                          cancelText: 'Отмена',
                          confirmText: 'Выбрать',
                          helpText: 'Выберите начальную дату',
                        );
                        if (picked != null) {
                          setState(() => _filterOptions.startDate = picked);
                        }
                      },
                      trailing:
                          _filterOptions.startDate != null
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed:
                                    () => setState(
                                      () => _filterOptions.startDate = null,
                                    ),
                              )
                              : null,
                    ),
                    ListTile(
                      title: const Text('Конечная дата'),
                      subtitle: Text(
                        _filterOptions.endDate != null
                            ? DateFormat(
                              'd MMMM yyyy',
                            ).format(_filterOptions.endDate!)
                            : 'Не выбрана',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _filterOptions.endDate ?? DateTime.now(),
                          firstDate: _filterOptions.startDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                          cancelText: 'Отмена',
                          confirmText: 'Выбрать',
                          helpText: 'Выберите конечную дату',
                        );
                        if (picked != null) {
                          setState(() => _filterOptions.endDate = picked);
                        }
                      },
                      trailing:
                          _filterOptions.endDate != null
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed:
                                    () => setState(
                                      () => _filterOptions.endDate = null,
                                    ),
                              )
                              : null,
                    ),
                    const Divider(),
                    const Text('Диапазон настроения:'),
                    RangeSlider(
                      values: RangeValues(
                        _filterOptions.minMood,
                        _filterOptions.maxMood,
                      ),
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      labels: RangeLabels(
                        _filterOptions.minMood.toStringAsFixed(1),
                        _filterOptions.maxMood.toStringAsFixed(1),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _filterOptions.minMood = values.start;
                          _filterOptions.maxMood = values.end;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Только избранные'),
                      value: _filterOptions.onlyFavorites,
                      onChanged: (value) {
                        setState(() {
                          _filterOptions.onlyFavorites = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Только с комментариями'),
                      value: _filterOptions.onlyWithComments,
                      onChanged: (value) {
                        setState(() {
                          _filterOptions.onlyWithComments = value!;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      _applyFilter();
                      Navigator.pop(context);
                    },
                    child: const Text('Применить'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _applyFilter() {
    if (_entriesByDay == null) return;

    setState(() {
      _filteredEntriesByDay = {};
      bool hasAnyMatches = false;

      print('\n=== APPLYING FILTER ===');
      print('Initial state:');
      print('_isFiltered: $_isFiltered');
      print('Filter options:');
      print('- Mood range: ${_filterOptions.minMood} - ${_filterOptions.maxMood}');
      print('- Only with comments: ${_filterOptions.onlyWithComments}');
      print('- Only favorites: ${_filterOptions.onlyFavorites}');

      for (var entry in _entriesByDay!.entries) {
        final filteredDocs = entry.value.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _filterOptions.matches(data);
        }).toList();

        if (filteredDocs.isNotEmpty) {
          _filteredEntriesByDay![entry.key] = filteredDocs;
          hasAnyMatches = true;
        }
      }

      // Устанавливаем _isFiltered в true, когда фильтр применен, независимо от результатов
      _isFiltered = true;
      
      print('\nFilter results:');
      print('hasAnyMatches: $hasAnyMatches');
      print('_isFiltered after: $_isFiltered');
      print('_filteredEntriesByDay is empty: ${_filteredEntriesByDay?.isEmpty}');
      print('=== END OF FILTER APPLICATION ===\n');
    });
  }

  void _resetFilter() {
    setState(() {
      _filterOptions = FilterOptions();
      _filteredEntriesByDay = null;
      _isFiltered = false;
    });
  }

  Future<void> _showMoodDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String moodId,
    String dateKey,
  ) async {
    final contextCopy = context;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final formattedDate = DateFormat('d MMMM yyyy, HH:mm').format(timestamp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            (data['isFavorite'] as bool?) ?? false
                                ? Icons.star
                                : Icons.star_border,
                            color:
                                (data['isFavorite'] as bool?) ?? false
                                    ? Colors.amber
                                    : Colors.grey,
                          ),
                          onPressed: () async {
                            final newValue =
                                !((data['isFavorite'] as bool?) ?? false);
                            await _toggleFavorite(
                              moodId,
                              dateKey,
                              newValue,
                              data as Map<String, dynamic>,
                            );
                            if (contextCopy.mounted) {
                              Navigator.pop(contextCopy);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _firestoreService.deleteMoodEntry(
                              widget.userId,
                              moodId,
                            );
                            if (!mounted) return;
                            setState(() {
                              if (_entriesByDay != null &&
                                  _entriesByDay!.containsKey(dateKey)) {
                                _entriesByDay![dateKey]!.removeWhere(
                                  (doc) => doc.id == moodId,
                                );
                                if (_entriesByDay![dateKey]!.isEmpty) {
                                  _entriesByDay!.remove(dateKey);
                                }
                                if (_isFiltered) {
                                  _applyFilter();
                                }
                                _initializeStream(); // Обновляем статистику после удаления
                              }
                            });
                            if (contextCopy.mounted) {
                              Navigator.pop(contextCopy);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (data['comment'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Комментарий:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['comment'] as String,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Оценка: ${(data['moodValue'] as num).toDouble()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> statistics) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Всего записей',
                  statistics['totalEntries'].toString(),
                  Icons.note_alt_outlined,
                ),
                _buildStatItem(
                  'Средняя оценка',
                  statistics['averageRating'].toString(),
                  Icons.star_half_outlined,
                ),
                _buildStatItem(
                  'Частая оценка',
                  statistics['mostFrequentRating'].toString(),
                  Icons.trending_up_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF6C63FF)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getMoodColor(double value) {
    if (value <= 1.0) return const Color(0xFFF8CECC); // Красный (плохо)
    if (value <= 2.0)
      return const Color(0xFFFFE6CC); // Оранжевый (ниже среднего)
    if (value <= 3.0) return const Color(0xFFFFF2CC); // Жёлтый (средне)
    if (value <= 4.0) return const Color(0xFFD5E8D4); // Зелёный (хорошо)
    return const Color(0xFF97D077); // Зелёный (отлично)
  }

  Future<void> _toggleFavorite(
    String moodId,
    String dateKey,
    bool newValue,
    Map<String, dynamic> entryData,
  ) async {
    // Немедленно обновляем UI
    setState(() {
      entryData['isFavorite'] = newValue;

      // Обновляем в основном списке
      if (_entriesByDay != null && _entriesByDay!.containsKey(dateKey)) {
        final entries = _entriesByDay![dateKey]!;
        final index = entries.indexWhere((doc) => doc.id == moodId);
        if (index != -1) {
          (entries[index].data() as Map<String, dynamic>)['isFavorite'] =
              newValue;
        }
      }

      // Обновляем в отфильтрованном списке если он есть
      if (_isFiltered &&
          _filteredEntriesByDay != null &&
          _filteredEntriesByDay!.containsKey(dateKey)) {
        final entries = _filteredEntriesByDay![dateKey]!;
        final index = entries.indexWhere((doc) => doc.id == moodId);
        if (index != -1) {
          (entries[index].data() as Map<String, dynamic>)['isFavorite'] =
              newValue;
        }
      }
    });

    // Затем обновляем в базе данных
    try {
      await _firestoreService.toggleFavorite(widget.userId, moodId, newValue);
    } catch (e) {
      if (!mounted) return;

      // В случае ошибки возвращаем предыдущее состояние
      setState(() {
        entryData['isFavorite'] = !newValue;

        if (_entriesByDay != null && _entriesByDay!.containsKey(dateKey)) {
          final entries = _entriesByDay![dateKey]!;
          final index = entries.indexWhere((doc) => doc.id == moodId);
          if (index != -1) {
            (entries[index].data() as Map<String, dynamic>)['isFavorite'] =
                !newValue;
          }
        }

        if (_isFiltered &&
            _filteredEntriesByDay != null &&
            _filteredEntriesByDay!.containsKey(dateKey)) {
          final entries = _filteredEntriesByDay![dateKey]!;
          final index = entries.indexWhere((doc) => doc.id == moodId);
          if (index != -1) {
            (entries[index].data() as Map<String, dynamic>)['isFavorite'] =
                !newValue;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении избранного: $e')),
      );
    }

    // Применяем фильтр если он активен
    if (_isFiltered) {
      _applyFilter();
    }
  }

  Widget _buildDayGroup(String dateKey, List<QueryDocumentSnapshot> entries) {
    final date = DateFormat('yyyy-M-d').parse(dateKey);
    final formattedDate = DateFormat('d MMMM yyyy').format(date);

    double averageRating =
        entries.fold<double>(0.0, (total, entry) {
          final data = entry.data() as Map<String, dynamic>;
          return total + (data['moodValue'] as num).toDouble();
        }) /
        entries.length;

    bool isExpanded = _expandedDays[dateKey] ?? true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedDays[dateKey] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Записей: ${entries.length} • Ср. оценка: ${averageRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final doc = entries[index];
                final data = doc.data() as Map<String, dynamic>;
                final moodValue = (data['moodValue'] as num).toDouble();
                final timestamp = (data['timestamp'] as Timestamp).toDate();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: _getMoodColor(moodValue),
                  child: ListTile(
                    leading: Text(
                      _getMoodEmoji(moodValue),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      DateFormat('HH:mm').format(timestamp),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          moodValue.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            (data['isFavorite'] as bool?) ?? false
                                ? Icons.star
                                : Icons.star_border,
                            color:
                                (data['isFavorite'] as bool?) ?? false
                                    ? Colors.amber
                                    : Colors.grey,
                          ),
                          onPressed: () {
                            final newValue =
                                !((data['isFavorite'] as bool?) ?? false);
                            _toggleFavorite(
                              doc.id,
                              dateKey,
                              newValue,
                              data as Map<String, dynamic>,
                            );
                          },
                        ),
                      ],
                    ),
                    onTap:
                        () => _showMoodDetails(context, data, doc.id, dateKey),
                  ),
                );
              },
            ),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  double _calculateAverageMoodForDay(List<QueryDocumentSnapshot> entries) {
    if (entries.isEmpty) return 0.0;
    double sum = entries.fold<double>(0.0, (total, entry) {
      final data = entry.data() as Map<String, dynamic>;
      return total + (data['moodValue'] as num).toDouble();
    });
    return sum / entries.length;
  }

  Widget _buildCalendar() {
    if (_entriesByDay == null) return const SizedBox();

    final displayedEntries =
        _isFiltered ? _filteredEntriesByDay ?? {} : _entriesByDay!;
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final now = DateTime.now();
                        final nextMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                          1,
                        );
                        if (nextMonth.isBefore(
                          DateTime(now.year, now.month + 1, 1),
                        )) {
                          setState(() {
                            _selectedMonth = nextMonth;
                          });
                        }
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showCalendar = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('Пн', style: TextStyle(color: Colors.grey)),
                Text('Вт', style: TextStyle(color: Colors.grey)),
                Text('Ср', style: TextStyle(color: Colors.grey)),
                Text('Чт', style: TextStyle(color: Colors.grey)),
                Text('Пт', style: TextStyle(color: Colors.grey)),
                Text('Сб', style: TextStyle(color: Colors.red)),
                Text('Вс', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 42, // 6 weeks * 7 days
              itemBuilder: (context, index) {
                final int day = index - firstWeekday + 2;
                if (day < 1 || day > daysInMonth) return const SizedBox();

                final dateKey = DateFormat('yyyy-M-d').format(
                  DateTime(_selectedMonth.year, _selectedMonth.month, day),
                );
                final entries = displayedEntries[dateKey] ?? [];
                final averageMood = _calculateAverageMoodForDay(entries);
                final isWeekend = (index % 7 == 5 || index % 7 == 6);

                // Проверяем, попадает ли дата в диапазон фильтра по датам
                final currentDate = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  day,
                );
                bool isInDateRange = true;
                if (_isFiltered) {
                  if (_filterOptions.startDate != null &&
                      currentDate.isBefore(_filterOptions.startDate!)) {
                    isInDateRange = false;
                  }
                  if (_filterOptions.endDate != null &&
                      currentDate.isAfter(
                        DateTime(
                          _filterOptions.endDate!.year,
                          _filterOptions.endDate!.month,
                          _filterOptions.endDate!.day,
                          23,
                          59,
                          59,
                        ),
                      )) {
                    isInDateRange = false;
                  }
                }

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color:
                        averageMood > 0 && isInDateRange
                            ? _getMoodColor(averageMood).withOpacity(0.3)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        !isInDateRange
                            ? Border.all(color: Colors.grey.withOpacity(0.2))
                            : null,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color:
                                  !isInDateRange
                                      ? Colors.grey.withOpacity(0.5)
                                      : isWeekend
                                      ? Colors.red
                                      : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (entries.isNotEmpty && isInDateRange)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  averageMood.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    entries.length > 3 ? 3 : entries.length,
                                    (i) {
                                      final moodValue =
                                          (entries[i].data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['moodValue']
                                              as num;
                                      return Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getMoodColor(
                                            moodValue.toDouble(),
                                          ).withOpacity(0.9),
                                          border: Border.all(
                                            color: _getMoodColor(
                                              moodValue.toDouble(),
                                            ),
                                            width: 1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _prepareChartData() {
    if (_entriesByDay == null) return [];

    final displayedEntries =
        _isFiltered ? _filteredEntriesByDay ?? {} : _entriesByDay!;
    List<FlSpot> spots = [];

    // Собираем средние значения по дням
    List<MapEntry<DateTime, double>> dailyAverages = [];
    for (var dayEntries in displayedEntries.entries) {
      // Вычисляем среднее значение за день
      double dayAverage =
          dayEntries.value.fold<double>(0.0, (sum, entry) {
            final data = entry.data() as Map<String, dynamic>;
            return sum + (data['moodValue'] as num).toDouble();
          }) /
          dayEntries.value.length;

      // Берем дату первой записи за день
      final timestamp =
          (dayEntries.value.first.data() as Map<String, dynamic>)['timestamp']
              as Timestamp;
      final date = DateTime(
        timestamp.toDate().year,
        timestamp.toDate().month,
        timestamp.toDate().day,
      );

      dailyAverages.add(MapEntry(date, dayAverage));
    }

    // Сортируем по дате
    dailyAverages.sort((a, b) => a.key.compareTo(b.key));

    // Конвертируем в точки для графика
    if (dailyAverages.isNotEmpty) {
      final firstDate = dailyAverages.first.key;
      for (var entry in dailyAverages) {
        final days = entry.key.difference(firstDate).inDays.toDouble();
        spots.add(FlSpot(days, entry.value));
      }
    }

    return spots;
  }

  Widget _buildChart() {
    final spots = _prepareChartData();
    if (spots.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    // Находим минимальную и максимальную даты
    final displayedEntries =
        _isFiltered ? _filteredEntriesByDay ?? {} : _entriesByDay!;
    DateTime? minDate;
    DateTime? maxDate;

    for (var dayEntries in displayedEntries.entries) {
      final timestamp =
          (dayEntries.value.first.data() as Map<String, dynamic>)['timestamp']
              as Timestamp;
      final date = DateTime(
        timestamp.toDate().year,
        timestamp.toDate().month,
        timestamp.toDate().day,
      );
      if (minDate == null || date.isBefore(minDate)) {
        minDate = date;
      }
      if (maxDate == null || date.isAfter(maxDate)) {
        maxDate = date;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'График настроения',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showChart = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(1));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (minDate == null) return const Text('');
                          final date = minDate!.add(
                            Duration(days: value.toInt()),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd.MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.last.x,
                  minY: 0,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Theme.of(context).primaryColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final date = minDate!.add(
                            Duration(days: touchedSpot.x.toInt()),
                          );
                          return LineTooltipItem(
                            '${DateFormat('dd.MM.yyyy').format(date)}\n',
                            const TextStyle(color: Colors.white, fontSize: 12),
                            children: [
                              TextSpan(
                                text:
                                    'Среднее: ${touchedSpot.y.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('\n=== BUILD METHOD ===');
    print('_isFiltered: $_isFiltered');
    print('_filteredEntriesByDay is null: ${_filteredEntriesByDay == null}');
    print('_filteredEntriesByDay is empty: ${_filteredEntriesByDay?.isEmpty}');

    if (_entriesByDay == null || _statistics == null) {
      print('Early return: loading state');
      return const Center(child: CircularProgressIndicator());
    }

    final displayedEntries = _isFiltered ? _filteredEntriesByDay ?? {} : _entriesByDay!;
    print('displayedEntries is empty: ${displayedEntries.isEmpty}');
    print('Will show empty state: ${displayedEntries.isEmpty}');
    print('=== END OF BUILD ===\n');

    if (displayedEntries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('История'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => setState(() => _showCalendar = !_showCalendar),
              tooltip: 'Календарь',
            ),
            IconButton(
              icon: const Icon(Icons.show_chart),
              onPressed: () => setState(() => _showChart = !_showChart),
              tooltip: 'График',
            ),
            if (_isFiltered)
              TextButton(
                onPressed: _resetFilter,
                child: const Text(
                  'Сброс',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Фильтр',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Записи не найдены'),
              if (_isFiltered)
                TextButton(
                  onPressed: _resetFilter,
                  child: const Text('Сбросить фильтр'),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
            tooltip: 'Календарь',
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => setState(() => _showChart = !_showChart),
            tooltip: 'График',
          ),
          if (_isFiltered)
            TextButton(
              onPressed: _resetFilter,
              child: const Text('Сброс', style: TextStyle(color: Colors.black)),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтр',
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          if (_showCalendar) _buildCalendar(),
          if (_showChart) _buildChart(),
          _buildStatisticsCard(_statistics!),
          ...displayedEntries.entries.map(
            (entry) => _buildDayGroup(entry.key, entry.value),
          ),
        ],
      ),
    );
  }
}
