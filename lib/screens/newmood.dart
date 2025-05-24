import 'package:flutter/material.dart';

class MoodTrackerScreen extends StatefulWidget {
  final Function(double, String, DateTime) onSave;

  const MoodTrackerScreen({super.key, required this.onSave});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  double _moodValue = 2.5;
  final TextEditingController _commentController = TextEditingController();
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      cancelText: 'Отмена',
      confirmText: 'Готово',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      if (!context.mounted) return;
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _saveEntry() {
    widget.onSave(_moodValue, _commentController.text, _selectedDateTime);
    _commentController.clear();

    setState(() {
      _moodValue = 2.5;
      _selectedDateTime = DateTime.now();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настроение сохранено!')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Как вы себя чувствуете?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оцените ваше настроение от 0 до 5',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildMoodSlider(),
          const SizedBox(height: 24),
          _buildDateTimeSelector(),
          const SizedBox(height: 40),
          _buildCommentField(),
          const SizedBox(height: 40),
          Center(child: _buildSaveButton()),
        ],
      ),
    );
  }

  Widget _buildMoodSlider() {
    final sliderColor = _getMoodColor(_moodValue);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _moodValue.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: sliderColor,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: sliderColor,
              inactiveTrackColor: sliderColor.withAlpha(51),
              thumbColor: sliderColor,
              overlayColor: sliderColor.withAlpha(26),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: _moodValue,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (value) => setState(() => _moodValue = value),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  children: [
                    Text('Ужасно', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('😭', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Плохо', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('😞', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Нормально', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('😐', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Хорошо', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('🙂', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Отлично', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('😊', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    Text('Супер', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('🤩', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(double value) {
    if (value < 1.0) return const Color(0xFFE53935);
    if (value < 2.0) return const Color(0xFFFB8C00);
    if (value < 3.0) return const Color(0xFFFDD835);
    if (value < 4.0) return const Color(0xFF7CB342);
    if (value < 5.0) return const Color(0xFF43A047);
    return const Color(0xFF2E7D32);
  }

  Widget _buildDateTimeSelector() {
    return InkWell(
      onTap: () => _selectDateTime(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedDateTime.day.toString().padLeft(2, '0')}.'
              '${_selectedDateTime.month.toString().padLeft(2, '0')}.'
              '${_selectedDateTime.year} '
              '${_selectedDateTime.hour.toString().padLeft(2, '0')}:'
              '${_selectedDateTime.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Icon(Icons.edit_calendar, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Комментарий (необязательно)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            hintText: 'Что повлияло на ваше настроение?',
          ),
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveEntry,
      child: const Text(
        'Сохранить',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
