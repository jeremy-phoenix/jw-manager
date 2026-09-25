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
  final CheckboxThemeData? headingCheckboxTheme;
  final CheckboxThemeData? dataRowCheckboxTheme;
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
    this.headingCheckboxTheme,
    this.dataRowCheckboxTheme,
    this.minWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Inline cell editors stay borderless instead of taking the app's filled
    // field style; an underline marks the cell being edited.
    final cellTheme = theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = constraints.hasBoundedWidth
            ? math.max(constraints.maxWidth, minWidth)
            : minWidth;

        return Theme(
          data: cellTheme,
          child: DataTable2(
            fixedTopRows: 1,
            minWidth: tableMinWidth,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            showCheckboxColumn: showCheckboxColumn,
            columnSpacing: columnSpacing,
            horizontalMargin: horizontalMargin,
            checkboxHorizontalMargin: checkboxHorizontalMargin,
            headingCheckboxTheme: headingCheckboxTheme,
            datarowCheckboxTheme: dataRowCheckboxTheme,
            columns: columns,
            rows: rows,
          ),
        );
      },
    );
  }
}
