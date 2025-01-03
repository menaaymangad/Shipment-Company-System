import '../models/agent_model.dart';
import 'sql_helper.dart';

extension AgentDatabaseHelper on DatabaseHelper {
  
  // CRUD Operations for Agents
  Future<int> insertAgent(Agent agent) async {
    final db = await database;
    return await db.insert('agents', agent.toMap());
  }

  Future<List<Agent>> getAllAgents() async {
    final db = await database;
    final result = await db.query('agents');
    return result.map((map) => Agent.fromMap(map)).toList();
  }

  Future<Agent?> getAgent(int id) async {
    final db = await database;
    final result = await db.query('agents', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Agent.fromMap(result.first);
  }

  Future<int> updateAgent(Agent agent) async {
    final db = await database;
    return await db.update('agents', agent.toMap(),
        where: 'id = ?', whereArgs: [agent.id]);
  }

  Future<int> deleteAgent(int id) async {
    final db = await database;
    return await db.delete('agents', where: 'id = ?', whereArgs: [id]);
  }

}