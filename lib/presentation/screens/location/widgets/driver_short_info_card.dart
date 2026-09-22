import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/model/global/user/global_driver_model.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';

class DriverShortInfoCard extends StatelessWidget {
  final GlobalDriverInfo? driver;
  final String driverImage;
  final String totalCompletedRide;

  const DriverShortInfoCard({
    super.key,
    this.driver,
    required this.driverImage,
    required this.totalCompletedRide,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(Dimensions.space20, Dimensions.space60, Dimensions.space20, Dimensions.space20),
            decoration: BoxDecoration(
              color: MyColor.colorWhite,
              borderRadius: BorderRadius.circular(Dimensions.moreRadius),
              boxShadow: [
                BoxShadow(
                  color: MyColor.colorBlack.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spaceDown(Dimensions.space15),
                  // Driver Name and Rating
                  Column(
                    children: [
                      HeaderText(
                        text: driver?.getFullName() ?? driver?.username ?? "",
                        style: boldLarge.copyWith(
                          color: MyColor.getTextColor(),
                          fontSize: Dimensions.fontOverLarge,
                          letterSpacing: 0.5,
                        ),
                      ),
                      spaceDown(Dimensions.space5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MyColor.colorOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: MyColor.colorOrange, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  driver?.avgRating == '0.00' ? MyStrings.nA.tr : (driver?.avgRating ?? ''),
                                  style: boldDefault.copyWith(color: MyColor.colorOrange, fontSize: Dimensions.fontSmall),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(${driver?.totalReviews ?? '0'} ${MyStrings.reviews.tr})",
                            style: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                          ),
                        ],
                      ),
                    ],
                  ),
                  spaceDown(Dimensions.space25),

                  // Stats row with cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          MyStrings.rides.tr,
                          totalCompletedRide,
                          Icons.directions_car_filled_rounded,
                          MyColor.primaryColor,
                        ),
                      ),
                      const SizedBox(width: Dimensions.space15),
                      Expanded(
                        child: _buildStatCard(
                          MyStrings.experience.tr,
                          _getExperience(driver?.createdAt),
                          Icons.verified_user_rounded,
                          Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  spaceDown(Dimensions.space25),

                  // Vehicle Section
                  if (driver?.vehicleData != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Dimensions.space15),
                      decoration: BoxDecoration(
                        color: MyColor.neutral50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                        border: Border.all(color: MyColor.neutral200.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                MyStrings.vehicleDetails.tr,
                                style: boldDefault.copyWith(color: MyColor.getTextColor(), fontSize: Dimensions.fontDefault + 1),
                              ),
                              Icon(Icons.info_outline_rounded, color: MyColor.getBodyTextColor(), size: 18),
                            ],
                          ),
                          spaceDown(Dimensions.space15),
                          if ((driver?.vehicleData?.imageSrc ?? "").isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                              child: MyImageWidget(
                                imageUrl: driver?.vehicleData?.imageSrc ?? "",
                                height: 120,
                                width: double.infinity,
                                radius: Dimensions.defaultRadius,
                                boxFit: BoxFit.contain,
                              ),
                            ),
                            spaceDown(Dimensions.space15),
                          ],
                          _buildSpecRow(MyStrings.brand.tr, driver?.vehicleData?.brand?.name ?? MyStrings.nA.tr),
                          _buildSpecRow(MyStrings.model.tr, [driver?.vehicleData?.model?.name, driver?.vehicleData?.year?.name].where((e) => e != null).join(' ')),
                          _buildSpecRow(MyStrings.numberPlate.tr, driver?.vehicleData?.vehicleNumber ?? MyStrings.nA.tr, isHighlight: true),
                        ],
                      ),
                    ),
                  ],
                  spaceDown(Dimensions.space20),

                  // Verifications
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildModernChip(MyStrings.email.tr, driver?.ev == "1"),
                        const SizedBox(width: 8),
                        _buildModernChip(MyStrings.phone.tr, driver?.sv == "1"),
                        const SizedBox(width: 8),
                        _buildModernChip(MyStrings.driver.tr, driver?.dv == "1"),
                        const SizedBox(width: 8),
                        _buildModernChip(MyStrings.vehicle.tr, driver?.vv == "1"),
                      ],
                    ),
                  ),
                  spaceDown(Dimensions.space25),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Get.back();
                              Get.toNamed(
                                RouteHelper.driverReviewScreen,
                                arguments: driver?.id,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: MyColor.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                              ),
                            ),
                            child: FittedBox(
                              child: Text(
                                MyStrings.reviews.tr,
                                style: boldLarge.copyWith(color: MyColor.primaryColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.space12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColor.primaryColor,
                              foregroundColor: MyColor.colorWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                              ),
                            ),
                            child: FittedBox(
                              child: Text(
                                MyStrings.close.tr,
                                style: boldLarge.copyWith(color: MyColor.colorWhite),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Floating Profile Image
          Positioned(
            top: -45,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: MyColor.colorWhite,
                  shape: BoxShape.circle,
                ),
                child: MyImageWidget(
                  imageUrl: driverImage,
                  height: 90,
                  width: 90,
                  radius: 45,
                  boxFit: BoxFit.cover,
                  isProfile: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    value,
                    style: boldDefault.copyWith(color: MyColor.getTextColor(), fontSize: Dimensions.fontDefault),
                  ),
                ),
                Text(
                  label,
                  style: regularExtraSmall.copyWith(color: MyColor.getBodyTextColor(), fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isHighlight = false}) {
    if (value.isEmpty || value == MyStrings.nA.tr) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: regularDefault.copyWith(color: MyColor.getBodyTextColor(), fontSize: Dimensions.fontSmall)),
          Flexible(
            child: Text(
              value,
              style: isHighlight ? boldDefault.copyWith(color: MyColor.primaryColor, fontSize: Dimensions.fontDefault) : mediumDefault.copyWith(color: MyColor.getTextColor(), fontSize: Dimensions.fontSmall + 1),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChip(String text, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isVerified ? MyColor.greenSuccessColor.withValues(alpha: 0.1) : MyColor.neutral100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
            size: 14,
            color: isVerified ? MyColor.greenSuccessColor : MyColor.getBodyTextColor(),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: boldDefault.copyWith(
              color: isVerified ? MyColor.greenSuccessColor : MyColor.getBodyTextColor(),
              fontSize: Dimensions.fontExtraSmall + 1,
            ),
          ),
        ],
      ),
    );
  }

  String _getExperience(String? createdAt) {
    if (createdAt == null) return "N/A";
    try {
      final createdDate = DateTime.parse(createdAt);
      final difference = DateTime.now().difference(createdDate);
      if (difference.inDays > 365) {
        return "${(difference.inDays / 365).floor()} ${MyStrings.year.tr}+";
      } else if (difference.inDays > 30) {
        return "${(difference.inDays / 30).floor()} ${MyStrings.month.tr}+";
      } else {
        return "${difference.inDays} ${MyStrings.days.tr}";
      }
    } catch (e) {
      return "N/A";
    }
  }
}
