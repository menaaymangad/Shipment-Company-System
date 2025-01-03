import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/agent_model.dart';
import 'agent_state.dart';

class AgentCubit extends Cubit<AgentState> {
  final AgentRepository repository;

  AgentCubit(this.repository) : super(AgentInitial());

  Future<void> loadAgents() async {
    try {
      emit(AgentLoading());
      final agents = await repository.getAllAgents();
      emit(AgentLoaded(agents));
    } catch (e) {
      emit(AgentError('Failed to load agents: ${e.toString()}'));
    }
  }

  Future<void> addAgent(Agent agent) async {
    try {
      emit(AgentLoading());
      await repository.insertAgent(agent);
      await loadAgents();
    } catch (e) {
      emit(AgentError('Failed to add agent: ${e.toString()}'));
    }
  }

  Future<void> updateAgent(Agent agent) async {
    try {
      emit(AgentLoading());
      await repository.updateAgent(agent);
      await loadAgents();
    } catch (e) {
      emit(AgentError('Failed to update agent: ${e.toString()}'));
    }
  }

  Future<void> deleteAgent(int id) async {
    try {
      emit(AgentLoading());
      await repository.deleteAgent(id);
      await loadAgents();
    } catch (e) {
      emit(AgentError('Failed to delete agent: ${e.toString()}'));
    }
  }

  Future<Agent?> getAgentById(int id) async {
    try {
      return await repository.getAgent(id);
    } catch (e) {
      emit(AgentError('Failed to get agent: ${e.toString()}'));
      return null;
    }
  }
}
