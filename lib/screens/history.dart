import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import 'dart:math' as math;

class MoodHistoryScreen extends StatefulWidget {
  final List<MoodEntry> history;

  const MoodHistoryScreen({super.key, required this.history});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final Map<String, bool> _expandedMonths = {};
  final Map<String, bool> _expandedDays = {};
  
  double? _minMoodFilter;
  double? _maxMoodFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  bool _showFilters = false;
  bool _hasCommentFilter = false;
  bool _showFavoritesOnly = false;
  bool _showGraph = false;
  bool _showCalendar = false;
  Offset? _hoveredPoint;
  final bool _showAverageLine = true;
  final String _selectedPeriod = 'all';
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    final months = _getMonths(widget.history);
    for (final month in months) {
      _expandedMonths[month] = false;
    }
    final days = _getDays(widget.history);
    for (final day in days) {
      _expandedDays[_getDayKey(day)] = true;  // Делаем все дни развернутыми
    }
  }

  List<MoodEntry> _getFilteredHistory(List<MoodEntry> entries) {
    return entries.where((entry) {
      // Apply mood value filters
      if (_minMoodFilter != null && entry.value < _minMoodFilter!) return false;
      if (_maxMoodFilter != null && entry.value > _maxMoodFilter!) return false;
      
      // Apply date filters
      if (_startDateFilter != null && entry.date.isBefore(_startDateFilter!)) return false;
      if (_endDateFilter != null && entry.date.isAfter(_endDateFilter!)) return false;
      
      // Apply comment filter
      if (_hasCommentFilter && entry.comment.isEmpty) return false;
      
      // Apply favorite filter
      if (_showFavoritesOnly && !entry.isFavorite) return false;
      
      return true;
    }).toList();
  }

  List<MoodEntry> _getFilteredByPeriod(List<MoodEntry> entries) {
    if (_selectedPeriod == 'all') return entries;
    
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        return entries;
    }
    
    return entries.where((e) => e.date.isAfter(startDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sortedHistory = List<MoodEntry>.from(widget.history)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final filteredHistory = _getFilteredHistory(sortedHistory);
    final periodFilteredHistory = _getFilteredByPeriod(filteredHistory);

    if (sortedHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilterHeader(),
        if (_showFilters) _buildFilterControls(),
        _buildStatsHeader(context, filteredHistory),
        Expanded(
          child: _showCalendar 
            ? _buildCalendarView(filteredHistory)
            : _showGraph 
              ? _buildGraphView(periodFilteredHistory)
              : _buildGroupedHistory(filteredHistory),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Нет сохранённых записей',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    final hasActiveFilters = _minMoodFilter != null || 
                           _maxMoodFilter != null || 
                           _startDateFilter != null || 
                           _endDateFilter != null ||
                           _hasCommentFilter ||
                           _showFavoritesOnly;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'История',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 16),
              _buildToggleButton(
                icon: Icons.list,
                isSelected: !_showGraph && !_showCalendar,
                onTap: () {
                  setState(() {
                    _showGraph = false;
                    _showCalendar = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                icon: Icons.show_chart,
                isSelected: _showGraph,
                onTap: () {
                  setState(() {
                    _showGraph = true;
                    _showCalendar = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                icon: Icons.calendar_month,
                isSelected: _showCalendar,
                onTap: () {
                  setState(() {
                    _showGraph = false;
                    _showCalendar = true;
                    _selectedMonth = DateTime.now();
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _minMoodFilter = null;
                      _maxMoodFilter = null;
                      _startDateFilter = null;
                      _endDateFilter = null;
                      _hasCommentFilter = false;
                      _showFavoritesOnly = false;
                    });
                  },
                  icon: Icon(
                    Icons.clear_all,
                    size: 20,
                    color: hasActiveFilters ? Theme.of(context).primaryColor : Colors.grey[600],
                  ),
                  label: Text(
                    'Сбросить',
                    style: TextStyle(
                      color: hasActiveFilters ? Theme.of(context).primaryColor : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: hasActiveFilters ? Theme.of(context).primaryColor.withAlpha(26) : null,
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: hasActiveFilters ? Theme.of(context).primaryColor.withAlpha(26) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                    color: hasActiveFilters ? Theme.of(context).primaryColor : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? 340 : 0,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Фильтры',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Период',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            label: 'Начальная дата',
                            date: _startDateFilter,
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDateFilter ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDateFilter = date;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateButton(
                            label: 'Конечная дата',
                            date: _endDateFilter,
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDateFilter ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDateFilter = date;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Настроение',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMoodSlider(
                            label: 'Мин. настроение',
                            value: _minMoodFilter ?? 0.0,
                            onChanged: (value) {
                              setState(() {
                                _minMoodFilter = value;
                                if (_maxMoodFilter != null && value > _maxMoodFilter!) {
                                  _maxMoodFilter = value;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMoodSlider(
                            label: 'Макс. настроение',
                            value: _maxMoodFilter ?? 5.0,
                            onChanged: (value) {
                              setState(() {
                                _maxMoodFilter = value;
                                if (_minMoodFilter != null && value < _minMoodFilter!) {
                                  _minMoodFilter = value;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _hasCommentFilter 
                                  ? Theme.of(context).primaryColor.withAlpha(26)
                                  : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.comment,
                                size: 20,
                                color: _hasCommentFilter 
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Только с комментариями',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _hasCommentFilter,
                          onChanged: (value) {
                            setState(() {
                              _hasCommentFilter = value;
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _showFavoritesOnly 
                                  ? Colors.amber.withAlpha(26)
                                  : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star,
                                size: 20,
                                color: _showFavoritesOnly 
                                  ? Colors.amber
                                  : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Только избранные',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _showFavoritesOnly,
                          onChanged: (value) {
                            setState(() {
                              _showFavoritesOnly = value;
                            });
                          },
                          activeColor: Colors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    String formatDate(DateTime date) {
      final months = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.calendar_today,
          size: 20,
          color: date == null ? Colors.grey[400] : Theme.of(context).primaryColor,
        ),
        label: Text(
          date == null ? label : formatDate(date),
          style: TextStyle(
            color: date == null ? Colors.grey[400] : Colors.grey[800],
            fontWeight: date == null ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    String getMoodEmoji(double value) {
      if (value < 1.0) return '😭';
      if (value < 2.0) return '😞';
      if (value < 3.0) return '😐';
      if (value < 4.0) return '🙂';
      if (value < 5.0) return '😊';
      return '🤩';
    }

    Color getMoodColor(double value) {
      if (value < 1.0) return const Color(0xFFE53935);
      if (value < 2.0) return const Color(0xFFFB8C00);
      if (value < 3.0) return const Color(0xFFFDD835);
      if (value < 4.0) return const Color(0xFF7CB342);
      if (value < 5.0) return const Color(0xFF43A047);
      return const Color(0xFF2E7D32);
    }

    String getMoodText(double value) {
      if (value < 1.0) return 'Ужасно';
      if (value < 2.0) return 'Плохо';
      if (value < 3.0) return 'Нормально';
      if (value < 4.0) return 'Хорошо';
      if (value < 5.0) return 'Отлично';
      return 'Супер';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              getMoodEmoji(value),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              getMoodText(value),
              style: TextStyle(
                color: getMoodColor(value),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: getMoodColor(value),
            inactiveTrackColor: getMoodColor(value).withAlpha(51),
            thumbColor: getMoodColor(value),
            overlayColor: getMoodColor(value).withAlpha(26),
            valueIndicatorColor: getMoodColor(value),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text('5.0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context, List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final averageMood = entries.map((e) => e.value).reduce((a, b) => a + b) / entries.length;
    
    String mostFrequentMood = 'Нет данных';
    final moodCounts = <double, int>{};
    for (var entry in entries) {
      moodCounts[entry.value] = (moodCounts[entry.value] ?? 0) + 1;
    }
    
    double mostFrequentValue = 2.5;
    int maxCount = 0;
    
    moodCounts.forEach((value, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentValue = value;
      }
    });
    
    mostFrequentMood = MoodDescriptions.getMoodText(mostFrequentValue);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Всего', entries.length.toString(), Icons.list),
              _buildStatItem('Среднее', averageMood.toStringAsFixed(1), Icons.bar_chart),
              _buildStatItem('Частое', mostFrequentMood, Icons.favorite),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: averageMood / 5,
              backgroundColor: Colors.grey[200],
              color: _getMoodColor(averageMood),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withAlpha(26) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildGraphView(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    // Сортируем записи по дате для корректного отображения графика
    final sortedEntries = List<MoodEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      padding: const EdgeInsets.all(20),
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            _hoveredPoint = event.localPosition;
          });
        },
        onExit: (event) {
          setState(() {
            _hoveredPoint = null;
          });
        },
        child: CustomPaint(
          painter: MoodGraphPainter(
            entries: sortedEntries,
            minMood: 0.0, // Фиксированное минимальное значение
            maxMood: 5.0, // Фиксированное максимальное значение
            themeColor: Theme.of(context).primaryColor,
            hoveredPoint: _hoveredPoint,
            showAverageLine: _showAverageLine,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildGroupedHistory(List<MoodEntry> entries) {
    final months = _getMonths(entries);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: months.length,
      itemBuilder: (context, monthIndex) {
        final month = months[monthIndex];
        final monthEntries = entries.where((e) => _getMonthKey(e.date) == month).toList();
        final isExpanded = _expandedMonths[month] ?? false;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  _formatMonth(month),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
                onTap: () {
                  setState(() {
                    _expandedMonths[month] = !isExpanded;
                  });
                },
              ),
              if (isExpanded) 
                _buildMonthDays(monthEntries),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthDays(List<MoodEntry> monthEntries) {
    if (monthEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final days = _getDays(monthEntries);
    
    return Column(
      children: days.map((day) {
        final dayKey = _getDayKey(day);
        final isDayExpanded = _expandedDays[dayKey] ?? true;
        final dayEntries = monthEntries.where((e) => _isSameDay(e.date, day)).toList();
        
        if (dayEntries.isEmpty) {
          return const SizedBox.shrink();
        }

        final averageMood = dayEntries.map((e) => e.value).reduce((a, b) => a + b) / dayEntries.length;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[100]!),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(_formatDay(day)),
                  subtitle: Text('${dayEntries.length} записей, среднее: ${averageMood.toStringAsFixed(1)}'),
                  trailing: Icon(
                    isDayExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedDays[dayKey] = !isDayExpanded;
                    });
                  },
                ),
                if (isDayExpanded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: dayEntries.map((entry) => _buildMoodItem(entry)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodItem(MoodEntry entry) {
    if (entry.value < 0 || entry.value > 5) {
      return const SizedBox.shrink(); // Пропускаем некорректные значения
    }

    final moodColor = _getMoodColor(entry.value);
    final moodText = '${MoodDescriptions.getMoodText(entry.value)} (${entry.value.toStringAsFixed(1)})';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: moodColor.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: moodColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showMoodDetails(context, entry),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildMoodEmoji(entry.value),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            moodText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: moodColor,
                            ),
                          ),
                        ],
                      ),
                      if (entry.comment.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.comment,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    entry.isFavorite ? Icons.star : Icons.star_border,
                    color: entry.isFavorite ? Colors.amber : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      entry.isFavorite = !entry.isFavorite;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoodDetails(BuildContext context, MoodEntry entry) {
    final moodColor = _getMoodColor(entry.value);
    final moodText = MoodDescriptions.getMoodText(entry.value);
    final dateFormat = '${entry.date.day}.${entry.date.month}.${entry.date.year}';
    final timeFormat = '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _buildMoodEmoji(entry.value),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moodText,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: moodColor,
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)} из 5.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          entry.isFavorite ? Icons.star : Icons.star_border,
                          color: entry.isFavorite ? Colors.amber : Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            entry.isFavorite = !entry.isFavorite;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(context, entry);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (entry.comment.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Комментарий',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    entry.comment,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MoodEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text('Удалить запись?'),
          ],
        ),
        content: Text(
          'Вы уверены, что хотите удалить запись от ${entry.date.day}.${entry.date.month}.${entry.date.year} ${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}?',
          style: TextStyle(color: Colors.grey[800]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.history.remove(entry);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Запись удалена'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  List<String> _getMonths(List<MoodEntry> entries) {
    final months = <String>{};
    for (final entry in entries) {
      months.add(_getMonthKey(entry.date));
    }
    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  List<DateTime> _getDays(List<MoodEntry> entries) {
    final days = <DateTime>{};
    for (final entry in entries) {
      days.add(DateTime(entry.date.year, entry.date.month, entry.date.day));
    }
    return days.toList()..sort((a, b) => b.compareTo(a));
  }

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    
    return '${monthNames[month - 1]} $year';
  }

  String _formatDay(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Сегодня';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Вчера';
    } else {
      final months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _buildMoodEmoji(double value) {
    if (value < 1.0) {
      return '😭';
    } else if (value < 2.0) {
      return '😞';
    } else if (value < 3.0) {
      return '😐';
    } else if (value < 4.0) {
      return '🙂';
    } else if (value < 5.0) {
      return '😊';
    } else {
      return '🤩';
    }
  }

  Color _getMoodColor(double value) {
    if (value < 1.0) return const Color(0xFFE53935);
    if (value < 2.0) return const Color(0xFFFB8C00);
    if (value < 3.0) return const Color(0xFFFDD835);
    if (value < 4.0) return const Color(0xFF7CB342);
    if (value < 5.0) return const Color(0xFF43A047);
    return const Color(0xFF2E7D32);
  }

  Widget _buildCalendarView(List<MoodEntry> entries) {
    // Group entries by day
    final Map<String, List<MoodEntry>> entriesByDay = {};
    for (var entry in entries) {
      final dayKey = _getDayKey(entry.date);
      entriesByDay[dayKey] ??= [];
      entriesByDay[dayKey]!.add(entry);
    }

    // Calculate average mood for each day
    final Map<String, double> averageMoodByDay = {};
    entriesByDay.forEach((dayKey, dayEntries) {
      final sum = dayEntries.fold<double>(0, (sum, entry) => sum + entry.value);
      averageMoodByDay[dayKey] = sum / dayEntries.length;
    });

    return Column(
      children: [
        _buildCalendarHeader(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day) => 
              SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: day == 'Сб' || day == 'Вс' ? Colors.red[400] : Colors.grey[600],
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: GridView.builder(
              key: ValueKey(_selectedMonth),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _getDaysInMonth(_selectedMonth) + _getFirstWeekday(_selectedMonth),
              itemBuilder: (context, index) {
                if (index < _getFirstWeekday(_selectedMonth)) {
                  return const SizedBox.shrink();
                }

                final day = index - _getFirstWeekday(_selectedMonth) + 1;
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                final dayKey = _getDayKey(date);
                final averageMood = averageMoodByDay[dayKey];

                return _buildCalendarDay(date, averageMood);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];

    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isCurrentMonth ? null : () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
            color: isCurrentMonth ? Colors.grey[400] : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, double? averageMood) {
    final isToday = _isSameDay(date, DateTime.now());
    final isSelectedMonth = date.month == _selectedMonth.month;
    final isWeekend = date.weekday == 6 || date.weekday == 7;
    final dayEntries = widget.history.where((entry) => _isSameDay(entry.date, date)).toList();

    Color borderColor;
    if (averageMood != null) {
      if (averageMood == 5.0) {
        borderColor = Colors.green;
      } else if (averageMood == 0.0) {
        borderColor = Colors.red;
      } else {
        borderColor = isToday ? Theme.of(context).primaryColor : Colors.grey[200]!;
      }
    } else {
      borderColor = isToday ? Theme.of(context).primaryColor : Colors.grey[200]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: averageMood != null ? _getMoodColor(averageMood).withAlpha(51) : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            if (averageMood != null) {
              _showDayDetails(date, averageMood);
            }
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelectedMonth 
                      ? (isWeekend ? Colors.red[400] : Colors.black)
                      : Colors.grey,
                  ),
                ),
                if (averageMood != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    averageMood.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getMoodColor(averageMood),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (dayEntries.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: dayEntries.map((entry) => Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _getMoodColor(entry.value),
                        shape: BoxShape.circle,
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDayDetails(DateTime date, double averageMood) {
    final dayEntries = widget.history.where((entry) => _isSameDay(entry.date, date)).toList();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDay(date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getMoodColor(averageMood).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _buildMoodEmoji(averageMood),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Среднее настроение',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${averageMood.toStringAsFixed(1)} - ${MoodDescriptions.getMoodText(averageMood)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getMoodColor(averageMood),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Записи за день (${dayEntries.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (dayEntries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Нет записей за этот день',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: dayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = dayEntries[index];
                    return _buildMoodItem(entry);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday - 1;
  }
}

class MoodGraphPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double minMood;
  final double maxMood;
  final Color themeColor;
  final Offset? hoveredPoint;
  final bool showAverageLine;

  MoodGraphPainter({
    required this.entries,
    required this.minMood,
    required this.maxMood,
    required this.themeColor,
    this.hoveredPoint,
    this.showAverageLine = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // Вычисляем масштаб для осей
    final xScale = size.width / (entries.length - 1);
    final yScale = size.height / (maxMood - minMood);

    // Рисуем фон с градиентом
    _drawBackground(canvas, size);

    // Рисуем сетку и подписи
    _drawGrid(canvas, size);

    // Создаем точки для графика
    final points = List<Offset>.generate(
      entries.length,
      (i) => Offset(
        i * xScale,
        size.height - (entries[i].value - minMood) * yScale,
      ),
    );

    // Рисуем линии графика
    if (points.isNotEmpty) {
      // Рисуем область под графиком
      _drawAreaUnderGraph(canvas, points, size);

      // Рисуем линии для каждого диапазона настроения
      _drawMoodRange(canvas, points, 0.0, 1.0, const Color(0xFFE53935).withAlpha(13), size);
      _drawMoodRange(canvas, points, 1.0, 2.0, const Color(0xFFFB8C00).withAlpha(13), size);
      _drawMoodRange(canvas, points, 2.0, 3.0, const Color(0xFFFDD835).withAlpha(13), size);
      _drawMoodRange(canvas, points, 3.0, 4.0, const Color(0xFF7CB342).withAlpha(13), size);
      _drawMoodRange(canvas, points, 4.0, 5.0, const Color(0xFF43A047).withAlpha(13), size);

      // Рисуем точки
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final entry = entries[i];
        final isHovered = hoveredPoint != null && 
            (hoveredPoint! - point).distance < 10;

        _drawPoint(canvas, point, isHovered, entry.value);

        if (isHovered) {
          _drawTooltip(canvas, point, entry, size);
        }
      }

      if (showAverageLine) {
        _drawAverageLine(canvas, points, size);
      }
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Рисуем основной фон
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.grey[50]!,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Рисуем цветные зоны для разных уровней настроения
    final zoneHeight = size.height / 5;
    _drawMoodZone(canvas, 0, zoneHeight * 4, zoneHeight, const Color(0xFFE53935).withAlpha(13));
    _drawMoodZone(canvas, 0, zoneHeight * 3, zoneHeight, const Color(0xFFFB8C00).withAlpha(13));
    _drawMoodZone(canvas, 0, zoneHeight * 2, zoneHeight, const Color(0xFFFDD835).withAlpha(13));
    _drawMoodZone(canvas, 0, zoneHeight, zoneHeight, const Color(0xFF7CB342).withAlpha(13));
    _drawMoodZone(canvas, 0, 0, zoneHeight, const Color(0xFF43A047).withAlpha(13));
  }

  void _drawMoodZone(Canvas canvas, double x, double y, double height, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, canvas.getLocalClipBounds().width, height), paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Горизонтальные линии сетки (фиксированные значения от 0 до 5)
    for (var i = 0; i <= 5; i++) {
      final y = size.height - (i - minMood) * (size.height / (maxMood - minMood));
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );

      // Подписи значений на оси Y
      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));

      // Добавляем подписи настроения
      final moodTextPainter = TextPainter(
        text: TextSpan(
          text: _getMoodLabel(i.toDouble()),
          style: TextStyle(
            color: _getMoodColor(i.toDouble()).withAlpha(179),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      moodTextPainter.layout();
      moodTextPainter.paint(canvas, Offset(30, y - moodTextPainter.height / 2));
    }

    // Вертикальные линии сетки (каждые 7 дней или меньше, если записей мало)
    final daysCount = entries.length;
    final gridStep = math.min(7, daysCount - 1);
    for (var i = 0; i < daysCount; i += gridStep) {
      final x = i * (size.width / (daysCount - 1));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      // Подписи дат на оси X
      if (i < entries.length) {
        final date = entries[i].date;
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${date.day}.${date.month}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 5));
      }
    }
  }

  void _drawAreaUnderGraph(Canvas canvas, List<Offset> points, Size size) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points[0].dx, size.height);
    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withAlpha(26),
          themeColor.withAlpha(13),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  void _drawPoint(Canvas canvas, Offset point, bool isHovered, double value) {
    final color = _getMoodColor(value);
    
    // Рисуем внешний круг
    canvas.drawCircle(
      point,
      isHovered ? 8 : 6,
      Paint()
        ..color = color.withAlpha(51)
        ..style = PaintingStyle.fill,
    );

    // Рисуем внутренний круг
    canvas.drawCircle(
      point,
      isHovered ? 6 : 4,
      Paint()
        ..color = Colors.white.withAlpha(230)
        ..style = PaintingStyle.fill,
    );

    // Рисуем обводку
    canvas.drawCircle(
      point,
      isHovered ? 6 : 4,
      Paint()
        ..color = color.withAlpha(51)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3 : 2,
    );
  }

  void _drawAverageLine(Canvas canvas, List<Offset> points, Size size) {
    if (points.isEmpty) return;

    // Вычисляем среднее значение
    double sum = 0;
    for (var entry in entries) {
      sum += entry.value;
    }
    final averageValue = sum / entries.length;
    final averageY = size.height - (averageValue - minMood) * (size.height / (maxMood - minMood));

    // Рисуем пунктирную линию среднего значения
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    var startX = 0.0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, averageY),
        Offset(startX + dashWidth, averageY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Подписываем среднее значение
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Среднее: ${averageValue.toStringAsFixed(1)}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 5, averageY - textPainter.height - 5));
  }

  void _drawTooltip(Canvas canvas, Offset point, MoodEntry entry, Size size) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final dateTimeText = '${entry.date.day}.${entry.date.month}.${entry.date.year} ${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}';
    final moodText = '${entry.value.toStringAsFixed(1)} - ${MoodDescriptions.getMoodText(entry.value)}';
    final commentText = entry.comment.isNotEmpty ? entry.comment : 'Нет комментария';
    
    final dateTimePainter = TextPainter(
      text: TextSpan(text: dateTimeText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    final moodPainter = TextPainter(
      text: TextSpan(text: moodText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    final commentPainter = TextPainter(
      text: TextSpan(
        text: commentText,
        style: textStyle.copyWith(
          fontSize: 11,
          color: Colors.white.withAlpha(230),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    dateTimePainter.layout();
    moodPainter.layout();
    commentPainter.layout();

    final tooltipWidth = math.max(
      dateTimePainter.width,
      math.max(moodPainter.width, commentPainter.width),
    ) + 16;
    final tooltipHeight = dateTimePainter.height + moodPainter.height + 
        commentPainter.height + 24;

    // Позиционируем подсказку
    var tooltipX = point.dx + 10;
    var tooltipY = point.dy - tooltipHeight - 10;

    // Проверяем, не выходит ли подсказка за границы
    if (tooltipX + tooltipWidth > size.width) {
      tooltipX = point.dx - tooltipWidth - 10;
    }
    if (tooltipY < 0) {
      tooltipY = point.dy + 10;
    }

    // Рисуем фон подсказки
    final tooltipRect = Rect.fromLTWH(
      tooltipX,
      tooltipY,
      tooltipWidth,
      tooltipHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        tooltipRect,
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black.withAlpha(230)
        ..style = PaintingStyle.fill,
    );

    // Рисуем текст подсказки
    var currentY = tooltipY + 8;
    dateTimePainter.paint(canvas, Offset(tooltipX + 8, currentY));
    currentY += dateTimePainter.height + 4;
    moodPainter.paint(canvas, Offset(tooltipX + 8, currentY));
    currentY += moodPainter.height + 4;
    commentPainter.paint(canvas, Offset(tooltipX + 8, currentY));
  }

  String _getMoodLabel(double value) {
    if (value < 1.0) return 'Ужасно';
    if (value < 2.0) return 'Плохо';
    if (value < 3.0) return 'Нормально';
    if (value < 4.0) return 'Хорошо';
    if (value < 5.0) return 'Отлично';
    return 'Супер';
  }

  Color _getMoodColor(double value) {
    if (value < 1.0) return const Color(0xFFE53935);
    if (value < 2.0) return const Color(0xFFFB8C00);
    if (value < 3.0) return const Color(0xFFFDD835);
    if (value < 4.0) return const Color(0xFF7CB342);
    if (value < 5.0) return const Color(0xFF43A047);
    return const Color(0xFF2E7D32);
  }

  void _drawMoodRange(Canvas canvas, List<Offset> points, double min, double max, Color color, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Рисуем линии между точками
    for (var i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];
      final currentValue = entries[i].value;
      final nextValue = entries[i + 1].value;
      
      if ((currentValue >= min && currentValue < max) || 
          (nextValue >= min && nextValue < max)) {
        paint.color = _getMoodColor(nextValue);
        canvas.drawLine(currentPoint, nextPoint, paint);
      }
    }

    // Рисуем точки для каждого диапазона настроения
    for (var i = 0; i < points.length; i++) {
      final entry = entries[i];
      if (entry.value >= min && entry.value < max) {
        final point = points[i];
        final isHovered = hoveredPoint != null && 
            (hoveredPoint! - point).distance < 10;

        _drawPoint(canvas, point, isHovered, entry.value);

        if (isHovered) {
          _drawTooltip(canvas, point, entry, size);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
