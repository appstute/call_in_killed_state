import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_voip_kit/call.dart';
import 'package:flutter_voip_kit/flutter_voip_kit.dart';

class BackgroundServicesUtility {
  static final service = FlutterBackgroundService();

  static CallState currentCallState = CallState.failed;
  // static Timer? geofenceTimer;
  // static late Timer _timerForSetLoc;

  static startBackgroundService() async {
    print("startBackgroundService");
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: onStartBackgroundService,

        // auto start service
        autoStart: false,
        isForegroundMode: true,
        // autoStartOnBoot: true,

        // notificationChannelId: 'amicane',
        // initialNotificationTitle: 'amicane service',
        // initialNotificationContent: 'Initializing',
        // foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,

        // this will be executed when app is in foreground in separated isolate
        onForeground: onStartBackgroundService,

        // you have to enable background fetch capability on xcode project
        // onBackground: onIosBackground,
      ),
    );
    service.startService();
  }

  @pragma('vm:entry-point')
  static onStartBackgroundService(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();
    FlutterVoipKit.init(
        callStateChangeHandler: myCallStateChangeHandler,
        callActionHandler: callActionHandler);

    // await HiveUtility.initHive();
    // await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform);

    // await location.enableBackgroundMode(enable: true);

    if (service is AndroidServiceInstance) {
      print("service is AndroidServiceInstance called");
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
        print("setAsForeground called");
        // FlutterBackgroundService().invoke("setAsForeground");
        // PhoneUtility.makeCall("9511299668");
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
        print("setAsBackground called");
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // bring to foreground
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          /// OPTIONAL for use custom notification
          /// the notification id must be equals with AndroidConfiguration when you call configure() method.
          service.setForegroundNotificationInfo(
            title: "Voip_call_kit",
            content: "Updated at ${DateTime.now()}",
          );
        }
      }

      /// you can see this log in logcat
      // print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

      service.invoke(
        'update',
        {
          "current_date": DateTime.now().toIso8601String(),
          // "device": device,
        },
      );
    });
    startBleAndLocationServices();
  }

  static startBleAndLocationServices() async {
    Timer.periodic(Duration(seconds: 30), (timer) {
      print("Calling 9511299668...currentCallState->$currentCallState");

      if (currentCallState != CallState.active) {
        FlutterVoipKit.startCall(
          "9511299668",
        ).then((value) {
          print("Call value->" + value.toString());
        });
      }
    });

    // Map amiCaneUserDetails = await HiveUtility.getAmiCaneUserDetails();
    // if (amiCaneUserDetails.isNotEmpty) {
    //   debugPrint("amiCaneUserDetails in killed state ->" +
    //       amiCaneUserDetails.toString());
    //   UpdatedUserData userData = UpdatedUserData?.fromJson(amiCaneUserDetails);
    //   if (userData.macId != null) {
    //     FlutterBlueUtility.startScan(macId: userData.macId!);
    //   }
    //   setAmicaneCurrentLocationInBg(userDetails: userData);
    //   createGeoFenceInBg(userData: userData);
    // }
  }

  static Future<bool> myCallStateChangeHandler(call) async {
    print("widget call state changed listener: $call");
    currentCallState = call.callState;

    switch (call.callState) {
      //handle every call state
      case CallState
          .connecting: //simulate connection time of 3 seconds for our VOIP service
        await Future.delayed(const Duration(seconds: 3));
        //MyVOIPService.connectCall(call.uuid)

        return true;
      case CallState
          .active: //here we would likely begin playing audio out of speakers
        return true;
      case CallState.ended: //likely end audio, disconnect
        return true;
      case CallState.failed: //likely cleanup
        return true;
      case CallState.held: //likely pause audio for specified call
        return true;
      default:
        return false;
        break;
    }
  }

  static Future<bool> callActionHandler(Call call, CallAction action) async {
    print("widget call action handler: $call");

    //it is important we perform logic and return true/false for every CallState possible
    switch (action) {
      case CallAction.muted:
        //EXAMPLE: here we would perform the logic on our end to mute the audio streams between the caller and reciever
        return true;
        break;
      default:
        return false;
    }
  }
}
