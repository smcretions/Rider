import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/data/repo/home/home_repo.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/dashboard/dashboard_background.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_app_bar.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_body.dart';
import 'widgets/location_pickup_widget.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? dashBoardScaffoldKey;

  const HomeScreen({super.key, this.dashBoardScaffoldKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double appBarSize = 90.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ScrollController _scrollController;
  bool _isFabVisible = true;

  @override
  void initState() {
    Get.put(HomeRepo(apiClient: Get.find()));
    Get.put(AppLocationController());
    final controller = Get.put(
      HomeController(homeRepo: Get.find(), appLocationController: Get.find()),
    );
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!mounted) return;
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData(shouldLoad: true);
    });
  }

  void openDrawer() {
    if (widget.dashBoardScaffoldKey != null) {
      widget.dashBoardScaffoldKey?.currentState?.openEndDrawer();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return DashboardBackground(
          child: Scaffold(
            extendBody: true,
            backgroundColor: MyColor.transparentColor,
            extendBodyBehindAppBar: false,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(appBarSize),
              child: HomeScreenAppBar(
                controller: controller,
                openDrawer: openDrawer,
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: controller.runningRide.id != null && controller.runningRide.id != "-1" && controller.runningRide.id != ""
                ? AnimatedOpacity(
                    opacity: _isFabVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.space100),
                        child: GestureDetector(
                          onTap: () {
                            Get.toNamed(
                              RouteHelper.rideDetailsScreen,
                              arguments: controller.runningRide.id,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [MyColor.primaryColor, MyColor.primaryColor.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: MyColor.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_car_filled_rounded, color: MyColor.colorWhite, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  MyStrings.tripInStatus.tr,
                                  style: boldDefault.copyWith(color: MyColor.colorWhite, letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.arrow_forward_ios_rounded, color: MyColor.colorWhite, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            body: RefreshIndicator(
              color: MyColor.primaryColor,
              backgroundColor: MyColor.colorWhite,
              onRefresh: () async {
                controller.initialData(shouldLoad: true);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.space16),
                physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                child: Column(
                  children: [
                    LocationPickUpHomeWidget(controller: controller),
                    spaceDown(Dimensions.space20),
                    HomeBody(controller: controller),
                    spaceDown(Dimensions.space100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
