// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../utils/utils.dart';
//
//
// class LikeService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String collectionName = "videosLikeCounter"; // Updated collection name
//
//   Future<void> toggleLike(String title, bool isLiked) async {
//     DocumentReference videoRef = _firestore.collection(collectionName).doc(title);
//
//     await videoRef.update(
//         {
//       'likeCount': FieldValue.increment(isLiked ? -1 : 1),
//     }
//     ).catchError((error) async {
//       // If the document doesn't exist, create it
//       if (error.code == 'not-found') {
//         await videoRef.set({'likeCount': 1});
//       }
//       showLog("ERROR : $error");
//     });
//   }
//
//   Stream<int> getLikeCount(String title) {
//     return _firestore.collection(collectionName).doc(title).snapshots().map((doc) {
//       return (doc.data()?['likeCount'] ?? 0) as int;
//     });
//   }
// }
