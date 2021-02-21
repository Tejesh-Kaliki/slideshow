import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arrange_slides.dart';
import 'slides.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Slide Show"),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        padding: EdgeInsets.all(10),
        childAspectRatio: 1,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateSlideShowPage(),
                ),
              );
            },
            child: Container(
              color: Colors.red[300],
              child: Center(
                child: Text("Create slides"),
              ), 
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ArrangeSlidesPage(),
                ),
              );
            },
            child: Container(
              color: Colors.blue[300],
              child: Center(
                child: Text("Arranging slides"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
