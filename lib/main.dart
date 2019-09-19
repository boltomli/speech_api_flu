import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  runApp(new MyApp());
}

const regions = const [
  const Region('West US', 'https://westus.tts.speech.microsoft.com/cognitiveservices/voices/list'),
  const Region('Southeast Asia', 'https://southeastasia.tts.speech.microsoft.com/cognitiveservices/voices/list'),
];

class Region {
  final String regionName;
  final String voiceListUrl;

  const Region(this.regionName, this.voiceListUrl);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Region selectedRegion = regions.first;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<Region>(
            tooltip: 'Select region by name\nhttps://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-text-to-speech#get-a-list-of-voices',
            onSelected: _selectRegionHandler,
            itemBuilder: (BuildContext context) => _buildRegionsWidgets,
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget> [
              Text(
                'Selected region:',
              ),
              Text(
                '${selectedRegion.regionName}\n',
              ),
              Text(
                'URL for list of available voices:',
              ),
              Text(
                '${selectedRegion.voiceListUrl}\n',
              ),
              Text(
                'Available voices:',
              ),
              Text(
                'TODO\n',
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<CheckedPopupMenuItem<Region>> get _buildRegionsWidgets => regions
    .map((r) => CheckedPopupMenuItem<Region>(
      value: r,
      checked: selectedRegion == r,
      child: Text(r.regionName),
    ))
    .toList();

  void _selectRegionHandler(Region region) {
    setState(() {
      selectedRegion = region;
    });
  }
}
