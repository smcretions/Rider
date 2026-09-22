import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/theme/light/light.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import '../../../../../core/utils/dimensions.dart';
import '../../../../../core/utils/helper.dart';
import '../../../../../core/utils/my_color.dart';
import '../../../../../core/utils/my_strings.dart';
import '../../../../../data/controller/location/select_location_controller.dart';

class EditLocationPickerScreen extends StatefulWidget {
  const EditLocationPickerScreen({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  State<EditLocationPickerScreen> createState() => _EditLocationPickerScreenState();
}

class _EditLocationPickerScreenState extends State<EditLocationPickerScreen> {
  bool isLoading = true;
  Uint8List? pickUpIcon;
  Uint8List? destinationIcon;
  LatLng? _currentCameraPosition;
  double currentZoom = Environment.mapDefaultZoom;
  double? _previousZoom;
  bool _isZooming = false;
  bool isDragging = false;
  bool showMarker = true;
  int selectedIndex = 0;
  @override
  void initState() {
    selectedIndex = Get.arguments ?? widget.selectedIndex;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //Widget Height

      Get.find<SelectLocationController>().changeIndex(selectedIndex);
      await loadMarker();
    });
  }

  Future<void> loadMarker() async {
    pickUpIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 150);
    destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<SelectLocationController>(builder: (controller) {
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: MyColor.screenBgColor,
          resizeToAvoidBottomInset: true,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!isLoading && controller.isLoading == true && controller.isLoadingFirstTime == true)
                const SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                )
              else ...[
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            style: googleMapLightStyleJson,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            initialCameraPosition: CameraPosition(
                              target: controller.getInitialTargetLocationForMap(pickupLocationForIndex: selectedIndex),
                              zoom: currentZoom,
                            ),
                            markers: const <Marker>{}, // Uber-style: No markers on map, just the fixed center pin
                            onMapCreated: (googleMapController) {
                              controller.editMapController = googleMapController;
                            },
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            onCameraMove: (CameraPosition position) {
                              if (_previousZoom != null && position.zoom != _previousZoom) {
                                if (!_isZooming) {
                                  setState(() => _isZooming = true);
                                }
                              }
                              _previousZoom = position.zoom;

                              if (!isDragging) {
                                setState(() => isDragging = true);
                                // Store the center at the start of the movement
                                _currentCameraPosition = position.target;
                              }
                              _currentCameraPosition = position.target;
                            },
                            onCameraIdle: () async {
                              try {
                                if (isDragging && _currentCameraPosition != null) {
                                  // Calculate distance from the original selection (or selection at start)
                                  double latDiff = (_currentCameraPosition!.latitude - (controller.selectedLatitude)).abs();
                                  double lngDiff = (_currentCameraPosition!.longitude - (controller.selectedLongitude)).abs();

                                  // If it was a zoom gesture and the drift is very small (e.g., < 0.0001 deg), snap back
                                  // This prevents accidental selection changes during off-center pinch zoom
                                  if (_isZooming && latDiff < 0.0001 && lngDiff < 0.0001) {
                                    controller.editMapController?.animateCamera(
                                      CameraUpdate.newLatLng(
                                        LatLng(controller.selectedLatitude, controller.selectedLongitude),
                                      ),
                                    );
                                  } else {
                                    // Significant movement or pure pan: update the location
                                    controller.changeCurrentLatLongBasedOnCameraMove(
                                      _currentCameraPosition!.latitude,
                                      _currentCameraPosition!.longitude,
                                    );
                                    await controller.pickLocation();
                                  }
                                }
                              } catch (e) {
                                debugPrint("Error on map move: $e");
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isDragging = false;
                                    _isZooming = false;
                                  });
                                }
                              }
                            },
                          ),
                          // Fixed Center Pin Overlay
                          IgnorePointer(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 45),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: isDragging ? Curves.easeOutCubic : Curves.bounceOut,
                                  margin: EdgeInsets.only(bottom: isDragging ? 25 : 0),
                                  child: (selectedIndex == 0 ? pickUpIcon : destinationIcon) != null
                                      ? Image.memory(
                                          selectedIndex == 0 ? pickUpIcon! : destinationIcon!,
                                          width: 45,
                                          height: 45,
                                        )
                                      : Icon(
                                          Icons.location_on,
                                          size: 45,
                                          color: selectedIndex == 0 ? MyColor.greenSuccessColor : MyColor.getPrimaryColor(),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          // Target Dot & Dynamic Shadow
                          IgnorePointer(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // The actual "selection point" dot
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: controller.isLoading ? 12 : 6,
                                    height: controller.isLoading ? 12 : 6,
                                    decoration: BoxDecoration(
                                      color: controller.isLoading ? MyColor.getPrimaryColor().withValues(alpha: 0.3) : Colors.black,
                                      shape: BoxShape.circle,
                                      border: controller.isLoading ? Border.all(color: MyColor.getPrimaryColor(), width: 1) : null,
                                    ),
                                    child: controller.isLoading
                                        ? const Center(
                                            child: SizedBox(
                                              width: 8,
                                              height: 8,
                                              child: CircularProgressIndicator(strokeWidth: 1, color: Colors.black),
                                            ),
                                          )
                                        : null,
                                  ),
                                  // The scaling shadow
                                  AnimatedOpacity(
                                    opacity: isDragging ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(top: 2),
                                      width: isDragging ? 10 : 16, // Shadow shrinks as pin lifts
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        borderRadius: const BorderRadius.all(Radius.elliptical(16, 4)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    buildConfirmDestination()
                  ],
                ),
              ],
              Align(
                alignment: Alignment.center,
                child: controller.isLoading
                    ? CircularProgressIndicator(
                        color: MyColor.getPrimaryColor(),
                      )
                    : const SizedBox.shrink(),
              ),
              Positioned(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space12,
                    ),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: MyColor.colorWhite,
                      ),
                      color: MyColor.colorBlack,
                      onPressed: () {
                        Get.back(result: true);
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                ),
              ),
              //Current location picker
              PositionedDirectional(
                top: 0,
                end: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space12,
                    ),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: MyColor.colorWhite,
                      ),
                      color: MyColor.colorBlack,
                      onPressed: () async {
                        await controller.getCurrentPosition(pickupLocationForIndex: -1, isFromEdit: true);
                      },
                      icon: const Icon(Icons.location_searching),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildConfirmDestination() {
    return GetBuilder<SelectLocationController>(
      builder: (controller) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.space16,
            horizontal: Dimensions.space16,
          ),
          decoration: BoxDecoration(
            color: MyColor.colorWhite,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: Dimensions.space20),
                Text(
                  MyStrings.setYourLocationPerfectly.tr,
                  style: boldDefault.copyWith(fontSize: 20),
                ),
                Text(
                  MyStrings.zoomInToSetExactLocation.tr,
                  style: lightDefault.copyWith(color: MyColor.bodyTextColor),
                ),
                if (controller.estimatedTime.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.space5),
                  Text(
                    "${MyStrings.estimatedTime.tr}: ${controller.estimatedTime}",
                    style: boldDefault.copyWith(color: MyColor.getPrimaryColor(), fontSize: Dimensions.fontLarge),
                  ),
                ],
                SizedBox(height: Dimensions.space30),
                InnerShadowContainer(
                  width: double.infinity,
                  backgroundColor: MyColor.neutral50,
                  borderRadius: Dimensions.largeRadius,
                  blur: 6,
                  offset: Offset(3, 3),
                  shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                  isShadowTopLeft: true,
                  isShadowBottomRight: true,
                  padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomSvgPicture(
                        image: selectedIndex == 0 ? MyIcons.currentLocation : MyIcons.location,
                        color: MyColor.primaryColor,
                      ),
                      spaceSide(Dimensions.space10),
                      Expanded(
                        child: Text(
                          controller.currentAddress.value.isNotEmpty
                              ? controller.currentAddress.value
                              : controller.homeController
                                      .getSelectedLocationInfoAtIndex(
                                        controller.selectedLocationIndex,
                                      )
                                      ?.fullAddress ??
                                  "",
                          style: regularDefault.copyWith(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Dimensions.space20),
                //Confirm
                RoundedButton(
                  text: MyStrings.confirm,
                  press: () {
                    Get.back();
                  },
                  isOutlined: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
