
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionStore {
  static final ValueNotifier<List<Map<String, dynamic>>> transactions =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _subscription;

  static CollectionReference<Map<String, dynamic>> get _collection {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  // MENGHUBUNGKAN TRANSAKSI DENGAN FIRESTORE
  static Future<void> initialize() async {
    await _subscription?.cancel();
    _subscription = null;

    transactions.value = [];

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final collection = _collection;

    _subscription = collection
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final dataList = snapshot.docs.map((doc) {
          final data = doc.data();

          final dateValue = data['date'];
          DateTime date;

          if (dateValue is Timestamp) {
            date = dateValue.toDate();
          } else if (dateValue is DateTime) {
            date = dateValue;
          } else {
            date = DateTime.now();
          }

          final iconValue = data['icon'];

          final iconCode = iconValue is num
              ? iconValue.toInt()
              : Icons.category_rounded.codePoint;

          return {
            ...data,
            'id': doc.id,
            'date': date,
            'icon': IconData(
              iconCode,
              fontFamily: 'MaterialIcons',
            ),
          };
        }).toList();

        transactions.value = dataList;
      },
      onError: (error) {
        debugPrint('Firestore error: $error');
      },
    );
  }

  // MENAMBAH TRANSAKSI
  static Future<void> addTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final data = _prepareData(transaction);

    await _collection.add(data);
  }

  // MENGEDIT TRANSAKSI
  static Future<void> updateTransaction(
    Map<String, dynamic> oldTransaction,
    Map<String, dynamic> newTransaction,
  ) async {
    final id = oldTransaction['id'];

    if (id == null) {
      throw Exception('ID transaksi tidak ditemukan');
    }

    final data = _prepareData(newTransaction);

    await _collection.doc(id.toString()).update(data);
  }

  // MENGHAPUS TRANSAKSI
  static Future<void> deleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final id = transaction['id'];

    if (id == null) {
      throw Exception('ID transaksi tidak ditemukan');
    }

    await _collection.doc(id.toString()).delete();
  }

  // MENGHAPUS SEMUA TRANSAKSI
  static Future<void> clearTransactions() async {
    final snapshot = await _collection.get();

    for (var i = 0; i < snapshot.docs.length; i += 500) {
      final batch = _firestore.batch();

      final end = (i + 500 < snapshot.docs.length)
          ? i + 500
          : snapshot.docs.length;

      for (var j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].reference);
      }

      await batch.commit();
    }
  }

  // MENYIAPKAN DATA UNTUK FIRESTORE
  static Map<String, dynamic> _prepareData(
    Map<String, dynamic> transaction,
  ) {
    final data = Map<String, dynamic>.from(transaction);

    data.remove('id');

    final icon = data['icon'];

    if (icon is IconData) {
      data['icon'] = icon.codePoint;
    }

    final date = data['date'];

    if (date is DateTime) {
      data['date'] = Timestamp.fromDate(date);
    }

    return data;
  }

  // MEMUTUSKAN LISTENER
  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;

    transactions.value = [];
  }
}
