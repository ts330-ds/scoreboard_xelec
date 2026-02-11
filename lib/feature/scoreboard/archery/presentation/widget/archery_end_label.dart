import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubit/controller/archery_controller_cubit.dart';

class ArcheryEndLabel extends StatelessWidget {
  const ArcheryEndLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryControllerCubit, ArcheryControllerState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue indicator dot
            Container(
              width: 16.w,
              height: 16.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 12.w),
            // Label text
            Text(
              '${state.phaseLabel} END ${state.currentEndNumber}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 1.sp,
              ),
            ),
          ],
        );
      },
    );
  }
}
