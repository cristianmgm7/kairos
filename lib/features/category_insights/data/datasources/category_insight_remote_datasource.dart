import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kairos/features/category_insights/data/models/category_insight_model.dart';

abstract class CategoryInsightRemoteDataSource {
  Stream<List<CategoryInsightModel>> watchAllInsights(String userId);
  Future<void> generateInsight(String category, {bool forceRefresh});
}

class CategoryInsightRemoteDataSourceImpl implements CategoryInsightRemoteDataSource {
  CategoryInsightRemoteDataSourceImpl(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CategoryInsightModel>> watchAllInsights(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('kairos_insights')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryInsightModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> generateInsight(String category, {bool forceRefresh = true}) async {
    final callable = _functions.httpsCallable('generateCategoryInsight');
    await callable<dynamic>({
      'category': category,
      'forceRefresh': forceRefresh,
    });
  }
}

