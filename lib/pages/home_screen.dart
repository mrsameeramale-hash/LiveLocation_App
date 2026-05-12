import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String deviceId = "Fetching...";
  String latitude = "-";
  String longitude = "-";
  String locationStatus = "Checking";
  bool isLoading = true;
  /// for widget  or a cards to highlight
  GlobalKey deviceKey = GlobalKey();
  GlobalKey latKey = GlobalKey();
  GlobalKey longKey = GlobalKey();
  GlobalKey statusKey = GlobalKey();

  TutorialCoachMark? tutorial;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await getDeviceId();
    await handleLocation();

    setState(() => isLoading = false);

    Future.delayed(const Duration(milliseconds: 500), checkAndShowTutorial);
  }

  Future<void> checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool("tutorial_seen") ?? false; ///for only 1time tutorial shows

    if (!seen) {
      showTutorial();
      await prefs.setBool("tutorial_seen", true);
    }
  }

  Future<void> onRefresh() async {
    setState(() => locationStatus = "Refreshing...");
    await getDeviceId();
    await handleLocation();
    setState(() {});
  }

  Future<void> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        deviceId = (await deviceInfo.androidInfo).id ?? "Unknown";
      } else {
        deviceId =
            (await deviceInfo.iosInfo).identifierForVendor ?? "Unknown";
      }
    } catch (e) {
      deviceId = "Error fetching ID";
    }
  }

  Future<void> handleLocation() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      await getLocation();
    } else {
      locationStatus = "Permission denied";
    }
  }

  Future<void> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();
      locationStatus = "Location fetched successfully";
    } catch (e) {
      locationStatus = "Failed to fetch location";
    }
  }

  void showTutorial() {
    tutorial = TutorialCoachMark(
      targets: createTargets(),
      colorShadow: Colors.transparent,
      paddingFocus: 0,
      pulseEnable: false,
      hideSkip: true,
    )..show(context: context);
  }

  List<TargetFocus> createTargets() {
    return [
      buildTarget(deviceKey, "This is your Device ID"),
      buildTarget(latKey, "This is your Latitude"),
      buildTarget(longKey, "This is your Longitude"),
      buildTarget(statusKey, "This is your Status"),
    ];
  }

  TargetFocus buildTarget(GlobalKey key, String text) {
    return TargetFocus(
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: 0,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return AnimatedTooltip(
              key: UniqueKey(), // 🔥 IMPORTANT FIX
              controller: controller,
              text: text,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? buildShimmer()
          : RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 40),

              buildCard(deviceKey, Icons.phone_android, "Device ID",
                  deviceId, Colors.blue),

              buildCard(latKey, Icons.location_on, "Latitude",
                  latitude, Colors.green),

              buildCard(longKey, Icons.explore, "Longitude",
                  longitude, Colors.orange),

              buildCard(
                statusKey,
                locationStatus == "Location fetched successfully"
                    ? Icons.check_circle
                    : Icons.error,
                "Status",
                locationStatus,
                locationStatus ==
                    "Location fetched successfully"
                    ? Colors.green
                    : Colors.red,
              ),

              const SizedBox(height: 100),

              Lottie.network(
                "https://assets2.lottiefiles.com/packages/lf20_tfb3estd.json",
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard(GlobalKey key, IconData icon, String title,
      String value, Color color) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.lightBlueAccent, blurRadius: 6)
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget buildShimmer() {
    return Column(
      children: List.generate(
        4,
            (_) => Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

///  FINAL TOOLTIP (FIXED FOR ALL CARDS)
class AnimatedTooltip extends StatefulWidget {
  final dynamic controller;
  final String text;

  const AnimatedTooltip({
    super.key,
    this.controller,
    required this.text,
  });

  @override
  State<AnimatedTooltip> createState() => _AnimatedTooltipState();
}

class _AnimatedTooltipState extends State<AnimatedTooltip> {
  Timer? timer;
  int timeLeft = 5;
  bool isDone = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();

    timeLeft = 5;
    isDone = false;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      setState(() {
        timeLeft--;

        if (timeLeft <= 0) {
          t.cancel();

          if (!isDone) {
            isDone = true;
            widget.controller.next();
          }
        }
      });
    });
  }

  void handleNext() {
    if (isDone) return;

    isDone = true;
    timer?.cancel();
    widget.controller.next();
  }

  void handleClose() {
    if (isDone) return;

    isDone = true;
    timer?.cancel();
    widget.controller.skip();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ///  TEXT + CLOSE BOX ICON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15
                  ),

                ),
              ),

              /// ❌ CLOSE ICON IN BOX
              GestureDetector(
                onTap: handleClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 👉 NEXT BUTTON WITH TIMER ONLY
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: handleNext,/// for use click any time
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.black
              ),
              child: Text(
                "Next $timeLeft s",

                style: const TextStyle(color: Colors.white),

              ),
            ),
          ),
        ],
      ),
    );
  }
}