import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart'; // For loading certificates

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // status bar on the top color
    statusBarIconBrightness:
        Brightness.dark, // darkness of the default icon on the device
  ));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AWS IoT MQTT Demo',
      home: MqttPage(),
    );
  }
}

class MqttPage extends StatefulWidget {
  @override
  _MqttPageState createState() => _MqttPageState();
}

class _MqttPageState extends State<MqttPage> {
  late MqttServerClient client;
  String jsonMessage = "";
  Timer? _timer;
  bool loading = false;
  late int t1;
  late int t2;

  void startTimer()async {

    await Future.delayed(Duration(seconds: 2)).then((value){

      print("idhar aa gaye");
      print(messageList);
      print(t1);

      print(findFirstTWithI(messageList, t1));
      t2 = findFirstTWithI(messageList, t1)?["t"];
      print(t2);




    });

  }

  double reportDeflection(double distance , double x2 , double x1){

    double deflection = 0;

    double calculation = distance/(x2 - x1) ;

    deflection = 90 - (atan(calculation) * (180 / 3.141592653589793)) ;

    if(deflection.abs() > 90){
      deflection = 90 - deflection;
    }




    setState(() {
      if(deflection.abs() < 12){
        deflection = 0;
      }
      double something = (deflection*100).roundToDouble()/100;
      angle = something;


    });

    return deflection;
  }

  Map<String, dynamic>? findFirstTWithI(List<Map<String, dynamic>> dataList, int startT) {

    bool startSearching = false;

    for (int i = 0; i < dataList.length; i++) {


      var item = dataList[i];


      // Start adding items to filteredDataList once startSearching is true
      if (startSearching) {

        filteredDataList.add(item);
      }

      // Find the startT and reset filteredDataList


      if (item['t'] == startT) {

        startSearching = true;
        filteredDataList = [];
        filteredDataList.add(item);
      }

      // If in search mode and find "i" in the message
      if (startSearching && item['message']!.contains('i')) {

        // Add 5 more items to filteredDataList after the found item, if available
        // Add the next 6 items after the found one

        //filteredDataList.add(item);

        for (int j = i + 1; j < dataList.length && j <= i + 6; j++) {
          filteredDataList.add(dataList[j]);
        }
        calculateSpeed(startT, item["t"], 11);

        return item; // Return the found item
      }
    }

    // Return null if no matching item is found
    return null;
  }

  void stopTimer() {
    clearData();
    _timer?.cancel();
  }

  // Function to filter data and find the least distance for i and u
  Map<String, dynamic> filterData(List<Map<String, dynamic>> messages) {
    // Variables to track the least distances and their full maps
    Map<String, dynamic>? minIMessage;
    Map<String, dynamic>? minUMessage;

    // Loop through the list and find the least distance for each type
    for (var message in messages) {
      // Split the message to get type and distance
      var parts = message['message'].split(',');
      var type = parts[0];
      var distance = int.parse(parts[1]);

      if (type == 'i') {
        if (minIMessage == null || distance < int.parse(minIMessage['message'].split(',')[1])) {
          minIMessage = message;
        }
      } else if (type == 'u') {
        if (minUMessage == null || distance < int.parse(minUMessage['message'].split(',')[1])) {
          minUMessage = message;
        }
      }
    }
    


    // Return the full maps for the least distance i and u in a map
    return {
      'i': [if (minIMessage != null) minIMessage['message'].split(",")[1]],
      'u': [if (minUMessage != null) minUMessage['message'].split(",")[1]],
    };
  }

  void checkMessages() {
    if (messageList.length >= 5) {
      // Check if the last 5 messages contain "u" in the "message" field
      List<Map<String, dynamic>> lastFiveMessages =
      messageList.sublist(messageList.length - 5);

      bool containsU = lastFiveMessages.any((message) =>
          message['message'].toString().contains('u'));

      // If any message contains "u", proceed to check the last 8 messages
      if (containsU) {
        // Create a sublist for the last 8 messages
        List<Map<String, dynamic>> lastEightMessages =
        messageList.sublist(messageList.length - 8);

        // Check if the last 8 messages contain "i" in the "message" field
        bool containsI = lastEightMessages.any((message) =>
            message['message'].toString().contains('i'));

        // Clear the filteredDataList and set the appropriate range
        filteredDataList = [];
        setState(() {
          if (containsI) {
            // If last 8 messages contain "i", add the last 8 messages
            filteredDataList.addAll(lastEightMessages);
          } else if (messageList.length >= 13) {
            // If last 8 messages do not contain "i", add the last 13 messages
            filteredDataList.addAll(
                messageList.sublist(messageList.length - 13, messageList.length));
          }
        });

        clearData();
      }
    }

  }



  @override
  void initState() {
    String message = 'temperature: 26.5, humidity: 55.2';
    Map<String, dynamic> messageMap = {
      'temperature': double.parse(message.split(',')[0].split(':')[1].trim()),
      'humidity': double.parse(message.split(',')[1].split(':')[1].trim())
    };

    jsonMessage = jsonEncode(messageMap);
    super.initState();
    setupMqtt();
  }
  List<Map<String,dynamic>> messageList = [];

  // Fill these variables with your AWS IoT details
  final String broker =
      'aft7269xoiyyr-ats.iot.ap-south-1.amazonaws.com'; // Your AWS IoT endpoint
  final String clientId = 'flutter_client'; // Your client ID
  bool t1Set = false;
  double speed = 0;
  double angle = 0;
  final String topic =
      'iotfrontier/pub'; // The topic you want to subscribe/publish to
  final int port = 8883; // AWS IoT uses 8883 for secure connections
   // To track the time of the last message
  Timer? inactivityTimer; // Timer to track inactivity
  int? lastMessageTime; // To track the time of the last message
  List<Map<String, dynamic>> lastMessages = []; // List to track the last 10 messages
  List<Map<String, dynamic>> filteredDataList = [];

  Future<void> setupMqtt() async {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 20;
    client.logging(on: true);
    client.secure = true; // Use secure connection

    // Load the certificates from assets
    final rootCA = await loadCertificate('assets/pems.pem');
    final clientCert = await loadCertificate('assets/crts.crt');
    final privateKey = await loadCertificate('assets/keys.key');

    // Set the security context for SSL/TLS
    client.securityContext = SecurityContext.defaultContext;
    client.securityContext!
        .setTrustedCertificatesBytes(rootCA.codeUnits); // Root CA
    client.securityContext!
        .useCertificateChainBytes(clientCert.codeUnits); // Client certificate
    client.securityContext!
        .usePrivateKeyBytes(privateKey.codeUnits); // Private key

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillTopic('willTopic')
        .withWillMessage('Disconnected')
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;

    try {
      await client.connect();
      subscribeToTopic(client, topic);
    } catch (e) {
      print('Connection failed: $e');
      client.disconnect();
    }
  }

  Future<String> loadCertificate(String path) async {
    return await rootBundle.loadString(path);
  }

  void onConnected() {
    print('Connected to AWS IoT');
  }

  void onDisconnected() {
    print('Disconnected from AWS IoT');
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void subscribeToTopic(MqttServerClient client, String topic) async {
    await loadMessages(); // Load stored messages

    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) async {
      final recMess = c[0].payload as MqttPublishMessage;
      final message =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('Received message: $message from topic: ${c[0].topic}');



      final Map<String, dynamic> jsonMessage = jsonDecode(message);





      if(jsonMessage["message"].contains("u") && t1Set == false){

        t1 = (jsonMessage["t"]);
        setState(() {
          t1Set = true;
        });
        startTimer();
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;


      setState(() {

        messageList.add(jsonMessage); // Add the message to the list
        //trackLastMessages(jsonMessage); // Track last 10 messages
      });

      await saveMessages(); // Save the updated list
    });
  }

  // Timer logic to clear messages after 20 seconds of inactivity
  void resetInactivityTimer() {
    inactivityTimer?.cancel(); // Cancel previous timer if active

    inactivityTimer = Timer(Duration(seconds: 20), () {
      // Check if all last messages contain "i" or if there are no new messages
      bool allLastMessagesContainI = lastMessages.every((msg) {
        String messageContent = msg['message'].split(',')[0];
        return messageContent == 'i';
      });

      // Clear messages if all last 10 contain "i" or no new messages in 20 seconds
      if (allLastMessagesContainI) {
        clearData(); // Clear the list
      }
    });
  }

  // Track the last 10 messages
  void trackLastMessages(Map<String, dynamic> newMessage) {
    lastMessages.add(newMessage); // Add new message
    if (lastMessages.length > 10) {
      lastMessages.removeAt(0); // Keep only the last 10 messages
    }
  }

  // Function to clear stored data
  void clearData() async {
    print('Clearing all data due to repeated message.');
    setState(() {
      messageList.clear(); // Clear the list
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('mqttMessages'); // Clear data in local storage
  }

  // Save messages to local storage
  Future<void> saveMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert list of maps (JSON) to a list of strings
    List<String> jsonStringList = messageList.map((msg) => jsonEncode(msg)).toList();

    // Store the list of JSON strings
    prefs.setStringList('mqttMessages', jsonStringList);
  }

  double calculateSpeed(int t1 , int t2, double distanceInCm) {
    // Convert distance from centimeters to inches
    double distanceInInches = distanceInCm / 2.54; // Convert cm to inches

    // Get the timestamps for i and u
    int startTime = t1;
    int endTime = t2;

    // Calculate the time taken (in seconds)

    double timeTakenInSeconds = (endTime - startTime) / 1000000; // Convert milliseconds to seconds

    if (timeTakenInSeconds > 0) {
      // Speed = Distance / Time
      setState(() {
        double something = distanceInInches / timeTakenInSeconds;
        speed = (something * 100).roundToDouble() / 100;
      });
      Map<String,dynamic> filters = filterData(filteredDataList);
      print(reportDeflection(15, double.parse(filters["u"][0]), double.parse(filters["i"][0])));
      return distanceInInches / timeTakenInSeconds; // speed in inches per second
    }

    return 0.0; // If no valid time, return 0
  }

/// Load messages from local storage
  Future<void> loadMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the list of JSON strings from storage
    List<String>? jsonStringList = prefs.getStringList('mqttMessages');

    // If messages are found, decode them and populate messageList
    if (jsonStringList != null) {
      messageList = jsonStringList.map<Map<String, dynamic>>((msg) => jsonDecode(msg) as Map<String, dynamic>).toList();

    }
  }

  void publishMessage(String status, int temperature) {
    final builder = MqttClientPayloadBuilder();

    // Constructing a JSON payload
    Map<String, dynamic> jsonPayload = {
      'message': status,
      'temperature': temperature
    };

    // Convert JSON map to a string
    String payloadString = jsonEncode(jsonPayload);

    // Add the JSON string to the payload
    builder.addString(payloadString);

    // Publish the message
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    print('Published JSON payload: $payloadString');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        backgroundColor: const Color(0xFF1BB00E),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'lib/resources/grass.jpg'), // Path to your grass texture
              fit: BoxFit
                  .cover, // Ensures the texture covers the entire container
            ),
          ),
        ),


        // body: Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       ElevatedButton(
        //         onPressed: () => publishMessage('active', 25), // Example JSON payload
        //         child: Text('Send JSON Message'),
        //
        //       ),
        //     ],
        //   ),
        // ),
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: -300,
                  duration: const Duration(milliseconds: 675),
                  child: FadeInAnimation(child: widget)),
              children: <Widget>[
                Stack(
                  children: [Container(
                    height: 700,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(70)),
                        color: Colors.yellow.shade700),
                  ),
                  Positioned(bottom: 20,child: SizedBox(
                    width: 400,
                    child: Center(
                      child: Text(
                        'Start ....',
                        style:GoogleFonts.lato(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color : Colors.white,
                        ),
                      ),
                    ),
                  ),)
                  ]
                ),
              ],
            ),
          ),
        ),
      ),
      //Container(height: 740,width: double.infinity,decoration: BoxDecoration(borderRadius: BorderRadius.only(bottomLeft:Radius.circular(70)),color: Colors.black.withOpacity(0.8)),),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: -200,
                  duration: const Duration(milliseconds: 575),
                  child: FadeInAnimation(child: widget)),
              children: <Widget>[
                Stack(
                  children: [
                    Container(
                      height: 600,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // Shadow color
                            spreadRadius: 2, // Spread radius
                            blurRadius: 10, // Blur radius
                            offset: Offset(0, 5), // Shadow offset
                          ),
                        ],
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(70)),
                        color: Colors.green,
                      ),
                    ),
                    // Positioned(
                    //   right: 30,
                    //   bottom: 70,
                    //   child: SizedBox(
                    //     width: 60,
                    //     height: 60,
                    //     child: Image.asset(
                    //       "lib/resources/cali.png",
                    //       color: Colors.black.withOpacity(0.3),
                    //     ),
                    //   ),
                    // ),
                    Positioned(
                      left: 30, // Adjust the left position as needed
                      bottom: 30, // Adjust the bottom position for spacing
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the start
                        children: [
                          Text(
                            'Test No',
                            style:GoogleFonts.lato(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color : Colors.white
                            ),
                          ),
                          SizedBox(height: 20), // Space between the title and the speed section
                          Container(
                            width: 300,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [Text(
                                '$speed inch/sec',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,

                                  color: Colors.black,
                                ),
                              ),
                                // Space between speed and deflection
                                Text(
                                  angle > 0 ? "$angle° Right" : angle == 0 ? "Angle" :"${angle.abs()}° Left",
                                  style: GoogleFonts.nunito(
                                    fontSize: 25,
                                    color: Colors.black,
                                  ),
                                ),


                              ]
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: -100,
                  duration: const Duration(milliseconds: 475),
                  child: FadeInAnimation(child: widget)),
              children: <Widget>[
                Stack(children: [
                  Container(
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.2), // Shadow color
                            spreadRadius: 2, // Spread radius
                            blurRadius: 10, // Blur radius
                            offset: Offset(0, 5), // Shadow offset
                          ),
                        ],
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(70)),
                        color: Colors.deepPurpleAccent),
                  ),
                  Positioned(right: 30,bottom: 70,child: SizedBox(width: 60,height: 60,child: Image.asset("lib/resources/cali.png",color: Colors.black.withOpacity(0.3),))),
                  Positioned(
                    left: 30,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the end
                      children: [
                        Text(
                          'Calibration',
                          style: GoogleFonts.lato(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color : Colors.white
                          ),
                        ),
                        SizedBox(height: 10), // Adds space between the text and the boxes
                        Container(
                          width: 150, // Width of the calibration box
                          height: 40, // Height of the calibration box
                          decoration: BoxDecoration(
                            color: Colors.white, // Background color
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                            border: Border.all(color: Colors.blueGrey), // Border color
                          ),
                          child: Center(
                            child: Text(
                              'Box Calibration',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10), // Space between boxes
                        Container(
                          width: 250, // Width of the reference path calibration box
                          height: 40, // Height of the reference path calibration box
                          decoration: BoxDecoration(
                            color: Colors.white, // Background color
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                            border: Border.all(color: Colors.blueGrey), // Border color
                          ),
                          child: Center(
                            child: Text(
                              'Reference Path Calibration',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],






















                ),
              ],
            ),
          ),
        ),
      ),

      Scaffold(
        floatingActionButton: FloatingActionButton(backgroundColor: Colors.white,onPressed: (){
          setState(() {
            loading = true;
          });
        },child: const  Icon(Icons.settings),),
        backgroundColor: Colors.transparent,
        body: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: -50,
                duration: const Duration(milliseconds: 375),
                child: FadeInAnimation(child: widget),
              ),
              children: <Widget>[
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.2), // Shadow color
                            spreadRadius: 2, // Spread radius
                            blurRadius: 10, // Blur radius
                            offset: Offset(0, 5), // Shadow offset
                          ),
                        ],
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(70)),
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 30,
                      bottom: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ZoomTapAnimation(
                            onTap: (){
                              
                              print(t1);
                              print(t2);


                              print(filteredDataList);
                              Map<String,dynamic> filters = filterData(filteredDataList);
                              print(reportDeflection(15, double.parse(filters["u"][0]), double.parse(filters["i"][0])));
                              print(filters);



                              print(calculateSpeed(t1, t2, 11));

                            },
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircleAvatar(
                                backgroundColor: Colors.black,
                                child: Icon(Icons.person,
                                    size: 55, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Aligns text to the start
                            children: [
                              ZoomTapAnimation(
                                onTap: (){

                                  setState(() {
                                    loading = true;
                                  });

                                  clearData();
                                  setState(() {
                                    t1Set = false;
                                    loading = false;
                                  });
                                },
                                child: Text(
                                  'Refresh',
                                  style: GoogleFonts.roboto(fontSize: 30),
                                ),
                              ),
                              SizedBox(
                                  height:
                                      5), // Adds space between the two texts
                              ZoomTapAnimation(
                                onTap: (){
                                  clearData();

                                },
                                child: Text(
                                  'Ready to swing into action?', // Your tagline
                                  style: GoogleFonts.dancingScript(
                                      fontSize: 20,
                                      fontWeight : FontWeight.bold,
                                      color: Colors.grey[
                                          700]), // Adjust size and color as needed
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      if(loading)
        ZoomTapAnimation(onTap: (){
          setState(() {
            loading = false;
          });
        },child: Container(color: Colors.black.withOpacity(0.7),child: Center(child: SizedBox(width: 130,height: 130,child: LottieBuilder.asset("assets/data.json"),),),)),



    ]);
  }
}
