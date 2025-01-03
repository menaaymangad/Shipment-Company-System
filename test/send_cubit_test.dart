// import 'package:bloc_test/bloc_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:sqflite_common/sqlite_api.dart';
// import 'package:test/test.dart';
// import 'package:app/cubits/send_cubit/send_cubit.dart';
// import 'package:app/cubits/send_cubit/send_state.dart';
// import 'package:app/models/send_model.dart';
// import 'package:app/helper/send_db_helper.dart';

// class MockSendRecordDatabaseHelper extends Mock
//     implements SendRecordDatabaseHelper {
//   @override
//   // TODO: implement database
//   Future<Database> get database => throw UnimplementedError();

//   @override
//   Future<int> deleteSendRecord(int id) {
//     // TODO: implement deleteSendRecord
//     throw UnimplementedError();
//   }

//   @override
//   Future<List<SendRecord>> getAllSendRecords() {
//     // TODO: implement getAllSendRecords
//     throw UnimplementedError();
//   }

//   @override
//   Future<SendRecord?> getSendRecordById(int id) {
//     // TODO: implement getSendRecordById
//     throw UnimplementedError();
//   }

//   @override
//   Future<int> insertSendRecord(SendRecord record) {
//     // TODO: implement insertSendRecord
//     throw UnimplementedError();
//   }

//   @override
//   Future<int> updateSendRecord(SendRecord record) {
//     // TODO: implement updateSendRecord
//     throw UnimplementedError();
//   }}

// void main() {
//   late SendRecordCubit sendRecordCubit;
//   late MockSendRecordDatabaseHelper mockDatabaseHelper;

//   setUp(() {
//     mockDatabaseHelper = MockSendRecordDatabaseHelper();
//     sendRecordCubit = SendRecordCubit(mockDatabaseHelper);
//   });

//   tearDown(() {
//     sendRecordCubit.close();
//   });

//   blocTest<SendRecordCubit, SendRecordState>(
//     'emits [SendRecordLoading, SendRecordLoaded] when createSendRecord succeeds',
//     build: () {
//       when(mockDatabaseHelper.insertSendRecord(any)).thenAnswer((_) async => 1);
//       return sendRecordCubit;
//     },
//     act: (cubit) => cubit.createSendRecord(SendRecord()),
//     expect: () => [
//       SendRecordLoading(),
//       SendRecordLoaded(SendRecord(id: 1)),
//     ],
//   );
// }
