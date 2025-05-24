import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add or update user mood
  Future<void> updateUserMood(String userId, double moodValue, String? comment, DateTime dateTime) async {
    await _firestore.collection('user_moods').doc(userId).set({
      'moodValue': moodValue,
      'comment': comment ?? '',
      'timestamp': dateTime,
    }, SetOptions(merge: true));
  }

  // Get user mood history as a real-time stream
  Stream<QuerySnapshot> getUserMoodHistory(String userId) {
    return _firestore
        .collection('user_moods')
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get current user mood
  Future<DocumentSnapshot> getCurrentUserMood(String userId) {
    return _firestore.collection('user_moods').doc(userId).get();
  }

  // Add mood to history
  Future<void> addMoodToHistory(String userId, double moodValue, String? comment, DateTime dateTime) async {
    await _firestore
        .collection('user_moods')
        .doc(userId)
        .collection('history')
        .add({
      'moodValue': moodValue,
      'comment': comment ?? '',
      'timestamp': dateTime,
      'isFavorite': false,
    });
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String userId, String moodId, bool isFavorite) async {
    await _firestore
        .collection('user_moods')
        .doc(userId)
        .collection('history')
        .doc(moodId)
        .update({'isFavorite': isFavorite});
  }

  // Delete mood entry
  Future<void> deleteMoodEntry(String userId, String moodId) async {
    await _firestore
        .collection('user_moods')
        .doc(userId)
        .collection('history')
        .doc(moodId)
        .delete();
  }

  // Get mood statistics
  Future<Map<String, dynamic>> getMoodStatistics(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('user_moods')
        .doc(userId)
        .collection('history')
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'totalEntries': 0,
        'averageRating': 0.0,
        'mostFrequentRating': 0.0,
      };
    }

    int totalEntries = snapshot.docs.length;
    double sum = 0;
    Map<double, int> ratingFrequency = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      double moodValue = (data['moodValue'] as num).toDouble();
      sum += moodValue;
      ratingFrequency[moodValue] = (ratingFrequency[moodValue] ?? 0) + 1;
    }

    double averageRating = sum / totalEntries;
    double mostFrequentRating = ratingFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'totalEntries': totalEntries,
      'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      'mostFrequentRating': mostFrequentRating,
    };
  }

  // Get mood entries grouped by day
  Future<Map<String, List<QueryDocumentSnapshot>>> getMoodEntriesByDay(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('user_moods')
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();

    Map<String, List<QueryDocumentSnapshot>> entriesByDay = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
      
      if (!entriesByDay.containsKey(dateKey)) {
        entriesByDay[dateKey] = [];
      }
      entriesByDay[dateKey]!.add(doc);
    }

    return entriesByDay;
  }
} 