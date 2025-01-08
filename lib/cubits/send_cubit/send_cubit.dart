import 'package:app/cubits/send_cubit/send_state.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/models/send_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class SendRecordCubit extends Cubit<SendRecordState> {
  final SendRecordDatabaseHelper databaseHelper;
  SendRecordCubit(this.databaseHelper) : super(SendRecordInitial());

 Future<void> createSendRecord(SendRecord record) async {
    try {
      emit(SendRecordLoading());
      final id = await databaseHelper.insertSendRecord(record);
      record.id = id;
      emit(SendRecordCreated(record));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create send record: $e');
      }
      emit(const SendRecordError(
          'An error occurred while saving the record. Please try again.'));
    }
  }

  Future<void> updateSendRecord(SendRecord record) async {
    try {
      emit(SendRecordLoading());
      await databaseHelper.updateSendRecord(record);
      emit(SendRecordUpdated(record));
    } catch (e) {
     if (kDebugMode) {
       print('Failed to update send record: $e');
     }
      emit(const SendRecordError(
          'An error occurred while updating the record. Please try again.'));
    }
  }

  Future<void> fetchSendRecord(int id) async {
    try {
      emit(SendRecordLoading());
      final record = await databaseHelper.getSendRecordById(id);
      if (record != null) {
        emit(SendRecordLoaded(record));
      } else {
        emit(const SendRecordError('Record not found'));
      }
    } catch (e) {
      emit(SendRecordError('Failed to fetch send record: ${e.toString()}'));
    }
  }

  Future<List<SendRecord>> fetchAllSendRecords() async {
    try {
      emit(SendRecordLoading());
      final records = await databaseHelper.getAllSendRecords();
      emit(SendRecordListLoaded(records));
      return records;
    } catch (e) {
      emit(SendRecordError('Failed to fetch send records: ${e.toString()}'));
      return [];
    }
  }

  // Future<void> updateSendRecord(SendRecord record) async {
  //   try {
  //     emit(SendRecordLoading());
  //     await databaseHelper.updateSendRecord(record);
  //     emit(SendRecordLoaded(record));
  //   } catch (e) {
  //     emit(SendRecordError('Failed to update send record: ${e.toString()}'));
  //   }
  // }

 Future<void> deleteSendRecord(int id, String codeNumber) async {
    try {
      emit(SendRecordLoading());
      await databaseHelper.updateSendRecordFields(id, codeNumber);
      emit(SendRecordInitial());
    } catch (e) {
      emit(SendRecordError('Failed to delete send record: ${e.toString()}'));
    }
  }
  // Add a map to store form data
  Map<String, dynamic> _formData = {};

  // Save form data
  void saveFormData(Map<String, dynamic> formData) {
    _formData = formData;
    emit(SendFormDataSaved(formData));
  }

  // Clear form data
  void clearFormData() {
    _formData = {};
    emit(SendFormDataCleared());
  }

  // Get form data
  Map<String, dynamic> getFormData() {
    return _formData;
  }
}
