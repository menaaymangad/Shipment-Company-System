// ignore_for_file: must_be_immutable

import 'package:app/models/send_model.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class SendRecordState {
  const SendRecordState();
}


@immutable
class SendRecordInitial extends SendRecordState {
  List<Object?> get props => [];
}

@immutable
class SendRecordLoading extends SendRecordState {
  List<Object?> get props => [];
}


class SendRecordCreated extends SendRecordState {
  final SendRecord sendRecord;
  const SendRecordCreated(this.sendRecord);

  List<Object?> get props => [sendRecord];
}

class SendRecordUpdated extends SendRecordState {
  final SendRecord sendRecord;
  const SendRecordUpdated(this.sendRecord);

  List<Object?> get props => [sendRecord];
}
class SendRecordLoaded extends SendRecordState {
  final SendRecord sendRecord;
   const SendRecordLoaded(this.sendRecord);

  List<Object?> get props => [sendRecord];
}

class SendRecordError extends SendRecordState {
  final String message;
   const SendRecordError(this.message,);

  
  List<Object?> get props => [message];
}

class SendRecordListLoaded extends SendRecordState {
  final List<SendRecord> sendRecords;
   const SendRecordListLoaded(this.sendRecords,);


  List<Object?> get props => [sendRecords];
}
class SendFormDataSaved extends SendRecordState {
  final Map<String, dynamic> formData;

  const SendFormDataSaved(this.formData);
}

class SendFormDataCleared extends SendRecordState {}
