import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import '../feature/scoreboard/basketball/data/modal/quarter_ui_data.dart';

class QuarterGridDots<C extends StateStreamable<S>, S>
    extends StatelessWidget {

  /// Extract quarter from state
  final int Function(S state) quarterSelector;

  /// Extract timer status from state
  final bool Function(S state) isTimerFinishedSelector;

  /// Total quarters (fixed = 4)
  final int totalQuarter;

  const QuarterGridDots({
    super.key,
    required this.quarterSelector,
    required this.isTimerFinishedSelector,
    this.totalQuarter = 4,
  }) : assert(totalQuarter > 0 && totalQuarter <= 4);

  Color _getColor({
    required int quarter,
    required int runningQuarter,
    required bool isTimerFinished,
  }) {
    if (quarter < runningQuarter) {
      return Colors.red; // finished
    }

    if (quarter == runningQuarter) {
      return isTimerFinished ? Colors.red : Colors.green;
    }

    return Colors.grey; // not started
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<C, S, QuarterUiData>(
      selector: (state) => QuarterUiData(
        quarter: quarterSelector(state),
        isFinished: isTimerFinishedSelector(state),
      ),
      builder: (context, data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive spacing and radius based on parent constraints
            final double spacing = constraints.maxWidth * 0.08;
            final double dotRadius = (constraints.maxWidth - spacing) / 4;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 1.0,
              ),
              itemCount: totalQuarter,
              itemBuilder: (context, index) {
                final quarter = index + 1;

                return CircleAvatar(
                  radius: dotRadius,
                  backgroundColor: _getColor(
                    quarter: quarter,
                    runningQuarter: data.quarter,
                    isTimerFinished: data.isFinished,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$quarter',
                        style: context.text.titleSmall!
                            .copyWith(color: context.colors.surface, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }
}
