import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DataGridColumn<T> {
  final String header;
  final String Function(T item) getValue;
  final int flex;

  const DataGridColumn({
    required this.header,
    required this.getValue,
    this.flex = 1,
  });
}

class GenericDataGrid<T> extends StatelessWidget {
  final List<T> items;
  final List<DataGridColumn<T>> columns;
  final Function(T)? onItemSelected;
  final String searchQuery;
  final bool Function(T item, String query)? searchPredicate;
  final double? rowHeight;
  final TextStyle? cellTextStyle;
  final EdgeInsetsGeometry cellPadding;

  // Cached styles for better performance
  final TextStyle _headerStyle;
  final List<T> _filteredItems;

  GenericDataGrid({
    super.key,
    required this.items,
    required this.columns,
    this.onItemSelected,
    this.searchQuery = '',
    this.searchPredicate,
    this.rowHeight,
    this.cellTextStyle,
    this.cellPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  })  : _headerStyle = TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24.sp,
        ),
        // Pre-calculate filtered items
        _filteredItems = searchQuery.isEmpty || searchPredicate == null
            ? items
            : items
                .where((item) => searchPredicate(item, searchQuery))
                .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DataGridHeader(
          columns: columns,
          headerStyle: _headerStyle,
        ),
        Expanded(
          child: _DataGridList(
            items: _filteredItems,
            columns: columns,
            onItemSelected: onItemSelected,
            rowHeight: rowHeight,
            cellTextStyle: cellTextStyle,
            cellPadding: cellPadding,
          ),
        ),
      ],
    );
  }
}

// Separated header widget for better performance
class _DataGridHeader<T> extends StatelessWidget {
  final List<DataGridColumn<T>> columns;
  final TextStyle headerStyle;

  const _DataGridHeader({
    required this.columns,
    required this.headerStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
      child: Row(
        children: List.generate(
          columns.length,
          (index) => Expanded(
            flex: columns[index].flex,
            child: Text(
              columns[index].header,
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// Separated list widget with const constructor
class _DataGridList<T> extends StatelessWidget {
  final List<T> items;
  final List<DataGridColumn<T>> columns;
  final Function(T)? onItemSelected;
  final double? rowHeight;
  final TextStyle? cellTextStyle;
  final EdgeInsetsGeometry cellPadding;

  const _DataGridList({
    required this.items,
    required this.columns,
    this.onItemSelected,
    this.rowHeight,
    this.cellTextStyle,
    required this.cellPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _DataGridRow(
          item: item,
          columns: columns,
          onTap: onItemSelected != null ? () => onItemSelected!(item) : null,
          rowHeight: rowHeight,
          cellTextStyle: cellTextStyle,
          cellPadding: cellPadding,
        );
      },
    );
  }
}

// Separated row widget with const constructor
class _DataGridRow<T> extends StatelessWidget {
  final T item;
  final List<DataGridColumn<T>> columns;
  final VoidCallback? onTap;
  final double? rowHeight;
  final TextStyle? cellTextStyle;
  final EdgeInsetsGeometry cellPadding;

  const _DataGridRow({
    required this.item,
    required this.columns,
    this.onTap,
    this.rowHeight,
    this.cellTextStyle,
    required this.cellPadding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: rowHeight,
        padding: cellPadding,
        child: Row(
          children: List.generate(
            columns.length,
            (index) => Expanded(
              flex: columns[index].flex,
              child: Text(
                columns[index].getValue(item),
                style: cellTextStyle ??
                    TextStyle(
                      fontSize: 34.sp,
                      color: Colors.black87,
                    ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
