import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/models/activity_model.dart';

/// One row of the event schedule: an activity's title and start time, where it
/// happens, and a chevron into its detail page.
///
/// Text is read in the primary (Turkish) language, like the rest of the app —
/// swap the getters for their `…For(locale)` variants here once a language
/// switch lands. Location and location detail are optional on the model, so the
/// second line collapses entirely when neither is set.
class WgActivity extends StatelessWidget {
  const WgActivity({super.key, required this.activity, this.onTap});

  final ActivityModel activity;

  /// Called when the row is tapped — the calendar opens the activity's detail
  /// screen with it. Nothing happens when it is left off.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final location = activity.location;
    final locationDetail = activity.locationDetail;
    final startTime = DateFormat('HH:mm').format(activity.startDateTime);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: AppConfig.buttonPrimaryGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The time carries the emphasis; the title stays regular.
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: activity.title,
                          style: AppTextStyles.weGatherPrimaryTextStyle,
                        ),
                        const TextSpan(text: '  |  '),
                        TextSpan(
                          text: startTime,
                          style: AppTextStyles.weGatherSmallHeaderTextStyle
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: AppTextStyles.weGatherParagraphTextStyle,
                  ),
                  if (location.isNotEmpty || locationDetail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppConfig.mapPinIcon,
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 6),
                        if (location.isNotEmpty)
                          Flexible(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.weGatherSmallTextStyle,
                            ),
                          ),
                        if (locationDetail.isNotEmpty) ...[
                          if (location.isNotEmpty)
                            Text(
                              ' - ',
                              style: AppTextStyles.weGatherSmallTextStyle,
                            ),
                          Flexible(
                            child: Text(
                              locationDetail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.weGatherSmallTextStyle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // `Icon` only paints a flat colour, so the gradient is laid over a
            // white glyph and kept where the glyph itself is opaque.
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppConfig.buttonEmphasisGradient.createShader(bounds),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
