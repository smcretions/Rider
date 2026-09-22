import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:lottie/lottie.dart';

import 'package:ovorideuser/core/utils/my_color.dart';

import 'package:ovorideuser/core/utils/my_images.dart';

import 'package:ovorideuser/core/utils/my_strings.dart';

import 'package:ovorideuser/core/utils/style.dart';

import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'image/custom_svg_picture.dart';

class NoDataOrInternetScreen extends StatefulWidget {
  final String message;

  final double paddingTop;

  final double imageHeight;

  final bool fromReview;

  final bool isNoInternet;

  final VoidCallback? onChanged;

  final String message2;

  final String image;

  const NoDataOrInternetScreen({
    super.key,
    this.message = MyStrings.noData,
    this.paddingTop = 6,
    this.imageHeight = .5,
    this.fromReview = false,
    this.isNoInternet = false,
    this.onChanged,
    this.message2 = MyStrings.noDataToShow,
    this.image = MyImages.noDataImage,
  });

  @override
  State<NoDataOrInternetScreen> createState() => _NoDataOrInternetScreenState();
}

class _NoDataOrInternetScreenState extends State<NoDataOrInternetScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      decoration: widget.isNoInternet
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MyColor.primaryColor,
                  MyColor.primaryColor.withValues(alpha: 0.9),
                ],
              ),
            )
          : BoxDecoration(color: MyColor.getScreenBgColor()),
      child: Stack(
        children: [
          if (widget.isNoInternet)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  MyImages.backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.space20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation/Image Section
                Center(
                  child: widget.isNoInternet
                      ? Lottie.asset(
                          MyImages.noInternet,
                          height: MediaQuery.of(context).size.height * (widget.imageHeight > 0.4 ? 0.35 : widget.imageHeight),
                          width: MediaQuery.of(context).size.width * 0.7,
                        )
                      : CustomSvgPicture(
                          image: widget.image,
                          height: 120,
                          width: 120,
                          color: MyColor.primaryColor.withValues(alpha: 0.3),
                        ),
                ).animate().fade(duration: 500.ms).scale(delay: 100.ms, curve: Curves.easeOutBack),

                SizedBox(height: Dimensions.space30),

                // Title
                Text(
                  widget.isNoInternet ? MyStrings.noInternet.tr : widget.message.tr,
                  textAlign: TextAlign.center,
                  style: boldExtraLarge.copyWith(
                    color: widget.isNoInternet ? MyColor.colorWhite : MyColor.getTextColor(),
                    fontSize: Dimensions.fontOverLarge,
                  ),
                ).animate().slideY(begin: 0.2, duration: 400.ms).fade(),

                SizedBox(height: Dimensions.space10),

                // Subtitle
                Text(
                  widget.isNoInternet ? MyStrings.noInternetSubTitle.tr : widget.message2.tr,
                  style: regularDefault.copyWith(
                    color: widget.isNoInternet ? MyColor.colorWhite.withValues(alpha: 0.8) : MyColor.getContentTextColor(),
                    fontSize: Dimensions.fontLarge,
                  ),
                  textAlign: TextAlign.center,
                ).animate().slideY(begin: 0.2, delay: 100.ms, duration: 400.ms).fade(),

                if (widget.isNoInternet) ...[
                  SizedBox(height: Dimensions.space40),
                  // Retry Button
                  InkWell(
                    onTap: () async {
                      final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
                      if (!connectivityResult.contains(ConnectivityResult.none)) {
                        widget.onChanged?.call();
                      }
                    },
                    borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.space40,
                        vertical: Dimensions.space15,
                      ),
                      decoration: BoxDecoration(
                        color: MyColor.colorWhite,
                        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                        boxShadow: [
                          BoxShadow(
                            color: MyColor.colorBlack.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        MyStrings.retry.tr,
                        style: boldDefault.copyWith(
                          color: MyColor.primaryColor,
                          fontSize: Dimensions.fontLarge,
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
