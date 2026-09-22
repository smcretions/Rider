import 'package:custom_marker_builder/custom_marker_builder.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/theme/light/light.dart';
import 'package:ovorideuser/core/utils/debouncer.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/repo/polyline/polyline_repo.dart';
import 'package:ovorideuser/environment.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/text-form-field/location_pick_text_field.dart';
import 'package:ovorideuser/presentation/components/text/label_text.dart';
import '../../../../../core/utils/dimensions.dart';
import '../../../../../core/utils/helper.dart';
import '../../../../../core/utils/my_color.dart';
import '../../../../../core/utils/my_strings.dart';
import '../../../../../data/controller/location/select_location_controller.dart';
import '../../../../../data/repo/location/location_search_repo.dart';
import '../../../../components/shimmer/map_shimmer.dart';

class LocationPickerScreen extends StatefulWidget {
  final int pickupLocationForIndex;
  const LocationPickerScreen({super.key, required this.pickupLocationForIndex});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  TextEditingController searchLocationController = TextEditingController(text: '');
  int index = 0;
  Uint8List? pickUpIcon;
  Uint8List? destinationIcon;
  bool isSearching = false;
  bool isFirsTime = true;

  Marker? pickupInfoMarker;
  Marker? destinationInfoMarker;
  final DraggableScrollableController sheetController = DraggableScrollableController();

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    printD(index);
    super.initState();
    Get.put(LocationSearchRepo(apiClient: Get.find()));

    if (!Get.isRegistered<PolylineRepo>()) {
      Get.put(PolylineRepo(apiClient: Get.find()));
    }

    var controller = Get.put(
      SelectLocationController(locationSearchRepo: Get.find(), polylineRepo: Get.find(), selectedLocationIndex: index),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadMarker();
      controller.initialize();
    });
  }

  Future<void> _loadWidgetMarker(SelectLocationController controller) async {
    if (controller.mapController == null) return;
    try {
      bool isPickupSet = controller.homeController.selectedLocations.isNotEmpty && (controller.homeController.selectedLocations[0].latitude ?? 0) != 0;
      bool isDestinationSet = controller.homeController.selectedLocations.length >= 2 && (controller.homeController.selectedLocations[1].latitude ?? 0) != 0;

      String? estimatedTime = controller.estimatedTime;
      if (estimatedTime.isEmpty) estimatedTime = null;

      // Pickup Marker logic
      if (isPickupSet) {
        String pickupAddress = controller.pickUpController.text;
        if (pickupAddress.isEmpty) {
          pickupAddress = controller.homeController.selectedLocations[0].fullAddress ?? "";
        }

        final pickUpBitMap = await CustomMapMarkerBuilder.fromWidget(
          context: context,
          marker: _buildInfoWidget(MyStrings.pickup, pickupAddress.isEmpty ? MyStrings.loading.tr : pickupAddress, time: null),
        );

        pickupInfoMarker = Marker(
          markerId: const MarkerId("pickup_location_pill"),
          position: controller.pickupLatlong,
          icon: pickUpBitMap,
          anchor: const Offset(0.5, 1.1),
          onTap: () => Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0),
        );
      } else {
        pickupInfoMarker = null;
      }

      // Destination Marker logic
      if (isDestinationSet) {
        String destAddress = controller.destinationController.text;
        if (destAddress.isEmpty) {
          destAddress = controller.homeController.selectedLocations[1].fullAddress ?? "";
        }

        final destinationBitMap = await CustomMapMarkerBuilder.fromWidget(
          context: context,
          marker: _buildInfoWidget(MyStrings.destination, destAddress.isEmpty ? MyStrings.loading.tr : destAddress, time: estimatedTime),
        );

        destinationInfoMarker = Marker(
          markerId: const MarkerId("destination_location_pill"),
          position: controller.destinationLatlong,
          icon: destinationBitMap,
          anchor: const Offset(0.5, 1.1),
          onTap: () => Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1),
        );
      } else {
        destinationInfoMarker = null;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Marker Load Error: $e");
    }
  }

  Future<void> loadMarker() async {
    searchLocationController.text = '';
    pickUpIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 150);
    destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
    setState(() {});
  }

  void changeIndex(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) => Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: MyColor.screenBgColor,
          resizeToAvoidBottomInset: true,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              if (controller.isLoading && controller.isLoadingFirstTime)
                const MapShimmer()
              else
                Stack(
                  children: [
                    Positioned.fill(
                      child: GoogleMap(
                        zoomGesturesEnabled: true,
                        trafficEnabled: false,
                        indoorViewEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: false,
                        compassEnabled: false,
                        mapType: MapType.normal,
                        minMaxZoomPreference: const MinMaxZoomPreference(0, 100),
                        markers: {
                          Marker(
                            markerId: const MarkerId("pickup_location"),
                            position: controller.pickupLatlong,
                            icon: pickUpIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.bytes(pickUpIcon!, height: 45, width: 47),
                            onTap: () => Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0),
                          ),
                          Marker(
                            markerId: const MarkerId("destination_location"),
                            position: controller.destinationLatlong,
                            icon: destinationIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.bytes(destinationIcon!, height: 45, width: 45),
                            onTap: () => Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1),
                          ),
                          if (pickupInfoMarker != null && destinationInfoMarker != null) ...[
                            pickupInfoMarker!,
                            destinationInfoMarker!,
                          ]
                        },
                        initialCameraPosition: CameraPosition(
                          target: controller.getInitialTargetLocationForMap(pickupLocationForIndex: widget.pickupLocationForIndex),
                          zoom: Environment.mapDefaultZoom,
                          bearing: 20,
                          tilt: 0,
                        ),
                        onMapCreated: (googleMapController) {
                          controller.mapController = googleMapController;
                          _loadWidgetMarker(controller);
                        },
                        onCameraMove: (cameraPosition) {
                          controller.changeCurrentLatLongBasedOnCameraMove(
                            cameraPosition.target.latitude,
                            cameraPosition.target.longitude,
                          );
                        },
                        onCameraIdle: () => _loadWidgetMarker(controller),
                        polylines: Set<Polyline>.of(controller.polylines.values),
                        style: googleMapLightStyleJson,
                      ),
                    ),
                    if (controller.isLoading && !controller.isLoadingFirstTime && controller.selectedPredictionId == null) const Center(child: CustomLoader()),
                  ],
                ),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12),
                    child: IconButton(
                      style: IconButton.styleFrom(backgroundColor: MyColor.colorWhite),
                      color: MyColor.colorBlack,
                      onPressed: () => Get.back(result: true),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: sheetController,
                initialChildSize: 0.45,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                snap: true,
                snapSizes: const [0.30, 0.45, 0.90],
                builder: (context, scrollController) {
                  return GestureDetector(
                    onTap: () {
                      MyUtils.closeKeyboard();
                    },
                    child: buildConfirmDestination(
                      pickupLocationForIndex: widget.pickupLocationForIndex,
                      scrollController: scrollController,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoWidget(String title, String address, {String? time}) {
    String timeValue = "";
    String timeUnit = "";

    if (time != null) {
      if (time.contains('h')) {
        timeValue = time.split('h')[0].trim();
        timeUnit = 'hr';
      } else {
        timeValue = time.replaceAll(RegExp(r'[^0-9]'), '');
        timeUnit = 'min';
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(maxWidth: 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (time != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeValue,
                      style: boldDefault.copyWith(color: Colors.white, fontSize: 9, height: 1.0),
                    ),
                    Text(
                      timeUnit,
                      style: regularDefault.copyWith(color: Colors.white, fontSize: 6, height: 1.0),
                    ),
                  ],
                ),
              ),
            ],
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: title == MyStrings.pickup ? MyColor.greenSuccessColor : MyColor.getPrimaryColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        title == MyStrings.pickup ? Icons.my_location : Icons.location_on,
                        size: 6,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.tr.toUpperCase(),
                            style: boldDefault.copyWith(
                              fontSize: 5,
                              color: title == MyStrings.pickup ? MyColor.greenSuccessColor : MyColor.getPrimaryColor(),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            address.isEmpty ? MyStrings.noData.tr : address,
                            style: regularDefault.copyWith(fontSize: 8),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildConfirmDestination({required int pickupLocationForIndex, ScrollController? scrollController}) {
    final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

    return GetBuilder<SelectLocationController>(
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            color: MyColor.getCardBgColor(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.space30),
              topRight: Radius.circular(Dimensions.space30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                spaceDown(Dimensions.space10),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: Dimensions.space5,
                    width: Dimensions.space50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radius25),
                      color: MyColor.colorGrey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                spaceDown(Dimensions.space10),
                // Padding for the content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.space16),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsetsDirectional.symmetric(vertical: Dimensions.space3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            Dimensions.mediumRadius,
                          ),
                        ),
                        child: GetBuilder<HomeController>(
                          builder: (homeController) {
                            return Container(
                              color: Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabelText(text: MyStrings.pickUpLocation),
                                  spaceDown(Dimensions.space5),
                                  LocationPickTextField(
                                    fillColor: controller.selectedLocationIndex == 0 ? MyColor.colorWhite : MyColor.textFieldBgColor,
                                    shadowColor: controller.selectedLocationIndex == 0 ? MyColor.primaryColor.withValues(alpha: 0.2) : MyColor.colorGrey.withValues(alpha: 0.1),
                                    labelText: MyStrings.pickUpLocation,
                                    controller: controller.pickUpController,
                                    onTap: () {
                                      controller.changeIndex(0);
                                    },
                                    prefixIcon: Padding(
                                      padding: EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                                      child: CustomSvgPicture(
                                        image: MyIcons.currentLocation,
                                        color: MyColor.primaryColor,
                                        height: Dimensions.space35,
                                      ),
                                    ),
                                    onSubmit: () {},
                                    onChanged: (text) {
                                      if (isFirsTime == true) {
                                        isFirsTime = false;
                                        setState(() {});
                                      }
                                      myDeBouncer.run(() {
                                        controller.searchYourAddress(
                                          locationName: text,
                                          onSuccessCallback: () {
                                            if (controller.allPredictions.isNotEmpty) {
                                              sheetController.animateTo(
                                                0.9,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                        );
                                      });
                                    },
                                    hintText: MyStrings.pickUpLocation.tr,
                                    radius: Dimensions.moreRadius,
                                    inputAction: TextInputAction.done,
                                    suffixIcon: Padding(
                                      padding: EdgeInsetsDirectional.only(end: Dimensions.space5),
                                      child: IconButton(
                                        onPressed: () async {
                                          controller.clearTextFiled(0);
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: Dimensions.space20,
                                          color: MyColor.bodyTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  spaceDown(Dimensions.space15),
                                  LabelText(text: MyStrings.destination),
                                  spaceDown(Dimensions.space5),
                                  LocationPickTextField(
                                    fillColor: controller.selectedLocationIndex == 1 ? MyColor.colorWhite : MyColor.textFieldBgColor,
                                    shadowColor: controller.selectedLocationIndex == 1 ? MyColor.primaryColor.withValues(alpha: 0.2) : MyColor.colorGrey.withValues(alpha: 0.1),
                                    inputAction: TextInputAction.done,
                                    labelText: MyStrings.whereToGo,
                                    controller: controller.destinationController,
                                    onTap: () {
                                      controller.changeIndex(1);
                                    },
                                    onChanged: (text) {
                                      if (isFirsTime == true) {
                                        isFirsTime = false;
                                        setState(() {});
                                      }
                                      myDeBouncer.run(() {
                                        controller.searchYourAddress(
                                          locationName: text,
                                          onSuccessCallback: () {
                                            if (controller.allPredictions.isNotEmpty) {
                                              sheetController.animateTo(
                                                0.9,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                        );
                                      });
                                    },
                                    hintText: MyStrings.dropOffLocation.tr,
                                    radius: Dimensions.mediumRadius,
                                    prefixIcon: Padding(
                                      padding: EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                                      child: CustomSvgPicture(
                                        image: MyIcons.location,
                                        color: MyColor.primaryColor,
                                        height: Dimensions.space35,
                                      ),
                                    ),
                                    suffixIcon: Padding(
                                      padding: EdgeInsetsDirectional.only(end: Dimensions.space5),
                                      child: IconButton(
                                        onPressed: () async {
                                          controller.clearTextFiled(1);
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: Dimensions.space20,
                                          color: MyColor.bodyTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      //show search results
                      controller.isSearched && controller.allPredictions.isEmpty
                          ? CustomLoader(isPagination: true)
                          : GestureDetector(
                              onTap: () {},
                              child: SizedBox(
                                height: controller.allPredictions.isNotEmpty ? context.height * .3 : 0,
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(vertical: Dimensions.space20),
                                  itemCount: controller.allPredictions.length,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    var item = controller.allPredictions[index];
                                    return InkWell(
                                      radius: Dimensions.defaultRadius,
                                      onTap: () async {
                                        await controller.getLangAndLatFromMap(item).whenComplete(() {
                                          controller.pickLocation();
                                          controller.updateSelectedAddressFromSearch(
                                            item.description ?? '',
                                          );
                                          controller.animateMapCameraPosition();

                                          // Animate sheet back to mini size
                                          if (sheetController.isAttached) {
                                            sheetController.animateTo(
                                              0.45,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                          MyUtils.closeKeyboard();
                                        });

                                        MyUtils.closeKeyboard();
                                      },
                                      child: Container(
                                        width: MediaQuery.of(context).size.width,
                                        padding: const EdgeInsetsDirectional.symmetric(
                                          vertical: Dimensions.space15,
                                          horizontal: Dimensions.space8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            Dimensions.mediumRadius,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              size: Dimensions.space20,
                                              color: MyColor.bodyTextColor,
                                            ),
                                            spaceSide(Dimensions.space10),
                                            Expanded(
                                              child: Text(
                                                "${item.description}",
                                                style: regularDefault.copyWith(
                                                  color: MyColor.colorBlack,
                                                ),
                                              ),
                                            ),
                                            if (controller.isLoading && controller.selectedPredictionId == item.placeId) ...[
                                              spaceSide(Dimensions.space10),
                                              SizedBox(
                                                height: Dimensions.space15,
                                                width: Dimensions.space15,
                                                child: CircularProgressIndicator(
                                                  color: MyColor.primaryColor,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                spaceDown(Dimensions.space15),
                //Confirm
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.space16),
                  child: RoundedButton(
                    text: MyStrings.confirmLocation,
                    press: () {
                      Get.back(result: 'true');
                    },
                    isOutlined: false,
                  ),
                ),
                spaceDown(Dimensions.space20),
              ],
            ),
          ),
        );
      },
    );
  }
}
