import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async{
  HttpOverrides.global =  MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  late Box box;
  List data=[];

  Future openBox()async{

    box=await Hive.openBox('testData');
    return;
  }


 Future<bool> getData() async {
    await openBox();
    final String url =
        "https://raw.githubusercontent.com/shashiben/Flutter_cache_with_hive/master/csvjson.json";
    final headers = {"Accept": "application/json"};
    try{
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw "Error While Retrieving Data from Firebase";
      }

      JsonDecoder _decoder = new JsonDecoder();
      // print( _decoder.convert(response.body));
      await putData(_decoder.convert(response.body));


    }on SocketException{
      print("no internent");
    }


    //get the data from local db
    var myMap=box.toMap().values.toList();
    if(myMap.isEmpty){
      data.add('empty');
    }else{
      data=myMap;
    }
    // print(myMap);

   return Future.value(true);
  }


  Future putData(data)async{
    await box.clear();
    for(var d in data){
      box.add(d);
    }
  }

  Future<void> updateData()async{
    final String url =
        "https://raw.githubusercontent.com/shashiben/Flutter_cache_with_hive/master/csvjson.json";
    final headers = {"Accept": "application/json"};
    try{
      final response = await http.get(Uri.parse(url), headers: headers);



      JsonDecoder _decoder = new JsonDecoder();
      print( _decoder.convert(response.body));
      await putData(_decoder.convert(response.body));
  setState(() {

  });

    }on SocketException{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You have no internent"),
        duration: Duration(milliseconds: 300),
      ));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: OfflineBuilder(
        connectivityBuilder: (
            BuildContext context,
            ConnectivityResult connectivity,
            Widget child,
            ) {
          final bool connected = connectivity != ConnectivityResult.none;
          return  Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                height: 24.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  color: connected ? Color(0xFF00EE44) : Color(0xFFEE4400),
                  child: Center(
                    child: Text("${connected ? 'ONLINE' : 'OFFLINE'}"),
                  ),
                ),
              ),

              Center(
                child: FutureBuilder(
                    future: getData(),
                    builder:(context, snapshot) {
                      if(snapshot.hasData){
                        if(data.contains("empty")){
                          return Center(child: Text("this is empty"));
                        }else{
                          return RefreshIndicator(
                            onRefresh: updateData,
                            child: ListView.builder(
                                itemCount: data.length,
                                itemBuilder:(context, index){
                                  return Container(
                                      margin: EdgeInsets.all(10),
                                      child: Text(data[index]["Title"]??""));
                                }
                            ),
                          );
                        }
                      }else{
                        return Center(child: CircularProgressIndicator(),);
                      }
                    }) ,
              )


            ],
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
             Text(
              'There are no bottons to push :)',
            ),
             Text(
              'Just turn off your internet.',
            ),
          ],
        ),
      ),
      );
      // This trailing comma makes auto-formatting nicer for build methods
  }
}
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context) {

    return super.createHttpClient(context) ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}