/// VIT-AP Sports — FormStrip widget.
///
/// Component specification:
/// Form strip: the last 5 results as W / D / L chips (24x24, radius 8, container tints).
library;

import 'package:flutter/material.dart';

import 'app_chip.dart';

class FormStrip extends StatelessWidget {
  const FormStrip({
    super.key,
    required this.results,
    this.maxResults = 5,
  });

  /// List of results, e.g. ['W', 'W', 'L', 'D', 'W']
  final List<String> results;
  final int maxResults;

  @override
  Widget build(BuildContext context) {
    final displayList = results.take(maxResults).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < displayList.length; i++) ...[
          ResultChip(result: displayList[i]),
          if (i < displayList.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
