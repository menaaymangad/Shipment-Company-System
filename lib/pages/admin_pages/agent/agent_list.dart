import 'package:app/models/agent_model.dart';
import 'package:app/widgets/data_grid_list.dart';
import 'package:flutter/material.dart';

class AgentDataGrid extends StatelessWidget {
  final List<Agent> agents;
  final Function(Agent) onAgentSelected;
  final String searchQuery;

  const AgentDataGrid({
    super.key,
    required this.agents,
    required this.onAgentSelected,
    this.searchQuery = '',
  });

    static final List<DataGridColumn<Agent>> _columns = [
    DataGridColumn<Agent>(
      header: 'ID',
      getValue: (agent) => '${agent.id ?? ''}',
      flex: 1,
    ),
    DataGridColumn<Agent>(
      header: 'Agent Name',
      getValue: (agent) => agent.agentName,
      flex: 2,
    ),
    DataGridColumn<Agent>(
      header: 'Country',
      getValue: (agent) => agent.countryName,
      flex: 2,
    ),
    DataGridColumn<Agent>(
      header: 'Contact Person',
      getValue: (agent) => agent.contactPersonName,
      flex: 2,
    ),
    DataGridColumn<Agent>(
      header: 'Company',
      getValue: (agent) => agent.companyName,
      flex: 2,
    ),
    DataGridColumn<Agent>(
      header: 'Currency',
      getValue: (agent) => 'USD',
      flex: 1,
    ),
    DataGridColumn<Agent>(
      header: 'City',
      getValue: (agent) => agent.cityName,
      flex: 2,
    ),
  
  ];

 

  @override
  Widget build(BuildContext context) {
    return GenericDataGrid<Agent>(
      items: agents,
      columns: _columns,
      onItemSelected: onAgentSelected,
      searchQuery: searchQuery,
      searchPredicate: _searchAgent,
    );
  }
    // Separated search logic for better maintainability
  static bool _searchAgent(Agent agent, String query) {
    final lowercaseQuery = query.toLowerCase();
    return agent.agentName.toLowerCase().contains(lowercaseQuery) ||
        agent.companyName.toLowerCase().contains(lowercaseQuery) ||
        agent.contactPersonName.toLowerCase().contains(lowercaseQuery);
  }
}
