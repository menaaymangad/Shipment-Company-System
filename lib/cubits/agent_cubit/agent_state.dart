// agent_state.dart
import 'package:app/helper/Agent_db_helper.dart';
import 'package:equatable/equatable.dart';

import '../../helper/sql_helper.dart';
import '../../models/agent_model.dart';

abstract class AgentState extends Equatable {
  const AgentState();
  
  @override
  List<Object?> get props => [];
}

class AgentInitial extends AgentState {}

class AgentLoading extends AgentState {}

class AgentLoaded extends AgentState {
  final List<Agent> agents;
  
  const AgentLoaded(this.agents);
  
  @override
  List<Object?> get props => [agents];
}

class AgentError extends AgentState {
  final String message;
  
  const AgentError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// agent_repository.dart


class AgentRepository {
  final DatabaseHelper databaseHelper;

  AgentRepository(this.databaseHelper);

  Future<int> insertAgent(Agent agent) async {
    return await databaseHelper.insertAgent(agent);
  }

  Future<List<Agent>> getAllAgents() async {
    return await databaseHelper.getAllAgents();
  }

  Future<Agent?> getAgent(int id) async {
    return await databaseHelper.getAgent(id);
  }

  Future<int> updateAgent(Agent agent) async {
    return await databaseHelper.updateAgent(agent);
  }

  Future<int> deleteAgent(int id) async {
    return await databaseHelper.deleteAgent(id);
  }
}