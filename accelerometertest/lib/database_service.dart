import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // CREATE: เพิ่มข้อมูลผู้ใช้
  Future<DocumentReference> addUser(String name, int age) async {
    return await users.add({
      'name': name,
      'age': age,
    });
  }

  // READ: ดึงข้อมูลทั้งหมด
  Stream<QuerySnapshot> getUsers() {
    return users.snapshots();
  }

  // UPDATE: อัปเดตข้อมูล
  Future<void> updateUser(String id, String newName, int newAge) async {
    return await users.doc(id).update({
      'name': newName,
      'age': newAge,
    });
  }

  // DELETE: ลบข้อมูล
  Future<void> deleteUser(String id) async {
    return await users.doc(id).delete();
  }
}
