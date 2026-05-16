import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class StickyDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showCheckboxColumn;
  final double? columnSpacing;
  final double? horizontalMargin;
  final double? checkboxHorizontalMargin;
  final double minWidth;

  const StickyDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.showCheckboxColumn = true,
    this.columnSpacing,
    this.horizontalMargin,
    this.checkboxHorizontalMargin,
    this.minWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = constraints.hasBoundedWidth
            ? math.max(constraints.maxWidth, minWidth)
            : minWidth;

        return DataTable2(
          fixedTopRows: 1,
          minWidth: tableMinWidth,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          showCheckboxColumn: showCheckboxColumn,
          columnSpacing: columnSpacing,
          horizontalMargin: horizontalMargin,
          checkboxHorizontalMargin: checkboxHorizontalMargin,
          columns: columns,
          rows: rows,
        );
      },
    );
  }
}
