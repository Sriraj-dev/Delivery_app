import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:connectivity/connectivity.dart';
import 'package:delivery_app/Screens/Body.dart';
import 'package:delivery_app/Screens/LoginPage.dart';
import 'package:delivery_app/Screens/NetworkError.dart';
import 'package:delivery_app/Screens/homePage.dart';
import 'package:delivery_app/Screens/maintenance.dart';
import 'package:delivery_app/Screens/pageManager.dart';
import 'package:delivery_app/Screens/updateScreen.dart';
import 'package:delivery_app/Services/DBoperations.dart';
import 'package:delivery_app/Services/apiservices.dart';
import 'package:delivery_app/Services/authentication.dart';
import 'package:delivery_app/Services/locationServices.dart';
import 'package:delivery_app/Services/storageServices.dart';
import 'package:delivery_app/constants.dart';
import 'package:delivery_app/restaurantModel.dart';
import 'package:delivery_app/userModel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:progress_indicators/progress_indicators.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Phoenix(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyText1: TextStyle(color: ksecondaryColor),
          bodyText2: TextStyle(color: ksecondaryColor),
        ),
      ),
      home: LaunchScreen(),
    ),
  ));
}

class LaunchScreen extends StatefulWidget {
  //const LaunchScreen({Key? key}) : super(key: key);
  @override
  _LaunchScreenState createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  late Future<int> route;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    route = loadApp();
  }

  var loadingValue = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<int>(
        future: route,
        builder: (context,AsyncSnapshot<int> snapshot){
          if(snapshot.hasData){
            switch(snapshot.data){
              case 0:
                return PageManager();
              case 1:
                return LoginPage();
              case 2:
                return UpdateScreen();
              case 3:
                return MaintenanceScreen();
              case 4:
                return NetworkError();
              default:
                return LoginPage();
            }
          }else if(snapshot.hasError){
            return Center(
              child: Text('An Error Occured! ${snapshot.error}'),
            );
          }else{
            //------------------------This is the SplashScreen-------------------->
            return splashScreen(context);
          }
        },
      ),
    );

  }

  splashScreen(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Image.asset(
            'assets/images/title_image.png',
          ),
        ),
        Image.asset(
          'assets/images/splash_img.png',
          width: MediaQuery.of(context).size.width,
        ),
        Expanded(
          child: Container(
            width: MediaQuery.of(context).copyWith().size.width,
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: LiquidLinearProgressIndicator(
                    value: loadingValue, // Defaults to 0.5.
                    valueColor: AlwaysStoppedAnimation(
                        kPrimaryColor), // Defaults to the current Theme's accentColor.
                    backgroundColor: Colors
                        .white, // Defaults to the current Theme's backgroundColor.
                    borderColor: ksecondaryColor,
                    borderWidth: 5.0,
                    borderRadius: 12.0,
                    direction: Axis
                        .horizontal, // The direction the liquid moves (Axis.vertical = bottom to top, Axis.horizontal = left to right). Defaults to Axis.horizontal.
                    center: Text("Loading..."),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<int> loadApp() async {
    //check the internet availability-->
    final network = await checkNetwork();
    if (network) {
      setState(() {
        loadingValue = 0.15;
      });
      bool isLogin = false;
      final value = await Storage().getData();
      print('value is - $value');
      if (value[0] != null) {
        isLogin = true;
      } else {
        isLogin = false;
      }
      underMaintenance = await ApiServices().checkMaintenance();
      if (!underMaintenance) {
        setState(() {
          loadingValue = 0.35;
        });
        print('App is not under maintenance = $underMaintenance');
        updateAvailable = await ApiServices().checkUpdates();
        if (!updateAvailable) {
          setState(() {
            loadingValue = 0.5;
          });
          // initialise the items of restaurant -->
          print('App does not have any updates = $updateAvailable');
          print('getting items from restaurant');
          items = await ApiServices().getItems();
          print('got items from restaurant');
          setState(() {
            loadingValue = 0.75;
          });
          await getUserLocation();
          //homeAddress = await DbOperations().getHomeAddress();
          await getHomeAddress();
          print('home address is - $homeAddress');
          if ((homeAddress == null || homeAddress == '') &&
              userAddress != 'Not Set') {
            print('Yes im showing awesome dialogue');
            await AwesomeDialog(
                context: context,
                dismissOnTouchOutside: false,
                dismissOnBackKeyPress: false,
                dialogType: DialogType.QUESTION,
                title:
                    'Do you want to set your current location as Home Location?',
                btnOkOnPress: () {
                  DbOperations().saveHomeAddress(userAddress);
                  homeAddress = userAddress;
                  homeLocation = userLocation;
                  homeLatitude = userLocation.latitude;
                  homeLongitude = userLocation.longitude;
                },
                btnCancelOnPress: () {})
              ..show();
          } else {
            if (homeAddress != '') setHomeLocation(homeAddress);
          }
          initialiseCategories();
          initialiseCategoryItems();
          initialiseMenu();
          await getAllBranches();
          if(isLogin){

            //if the user is already logged in -->
            var isLogin = await Authentication()
                .login(value[0] ?? '', value[1] ?? '', true);
            if (isLogin == 'true') {
              getUserInfo();
              await getUserFav();
              await getUserCart();
              setState(() {
                loadingValue = 1;
              });
              return 0;
            } else {
              setState(() {
                loadingValue = 1;
              });
              showSnackBar('An error Occured!', context);
              return 5;
            }
          } else {
            //if the user need to login-->
            //return LoginPage();
            setState(() {
              loadingValue = 1;
            });
            return 1;
          }
        } else {
          //if the app has updates available-->
          //return UpdateScreen();
          setState(() {
            loadingValue = 1;
          });
          return 2;
        }
      } else {
        //if the app is under maintenance-->
        //return MaintenanceScreen();
        setState(() {
          loadingValue = 1;
        });
        return 3;
      }
    } else {
      setState(() {
        loadingValue = 1;
      });
      return 4;
    }
  }

  void showSnackBar(String isLogin, BuildContext context) {
    // isLogin == usernmae is incorrect or password is incorect;
    final snackBar = SnackBar(
      content: Text(isLogin),
      backgroundColor: Colors.red,
      padding: EdgeInsets.only(left: 15, right: 15, bottom: 20),
      behavior: SnackBarBehavior.floating,
    );
    //Scaffold.of(context).showSnackBar(snackBar)
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> checkNetwork() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none)
      return false;
    else
      return true;
  }
}

//TODO : payment gateway
//TODO : offers
//TODO : review and ratings
