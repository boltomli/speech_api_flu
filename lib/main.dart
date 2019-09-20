import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'http.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  runApp(new MyApp());
}

const regions = const [
  const Region('Southeast Asia', 'https://southeastasia.tts.speech.microsoft.com/cognitiveservices/voices/list', 'https://southeastasia.api.cognitive.microsoft.com/sts/v1.0/issueToken'),
  const Region('West US', 'https://westus.tts.speech.microsoft.com/cognitiveservices/voices/list', 'https://westus.api.cognitive.microsoft.com/sts/v1.0/issueToken'),
];

class Region {
  final String regionName;
  final String voiceListUrl;
  final String authUrl;

  const Region(this.regionName, this.voiceListUrl, this.authUrl);
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
  Region _selectedRegion = regions.first;
  String _text = "";

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget> [
            Text(
              'Selected region:',
            ),
            Text(
              '${_selectedRegion.regionName}\n',
            ),
            Text(
              'URL for list of available voices:',
            ),
            Text(
              '${_selectedRegion.voiceListUrl}\n',
            ),
            Text(
              'Available voices:',
            ),
            Expanded(
              child: Text(_text),
            ),
          ],
        ),
      ),
    );
  }

  List<CheckedPopupMenuItem<Region>> get _buildRegionsWidgets => regions
    .map((r) => CheckedPopupMenuItem<Region>(
      value: r,
      checked: _selectedRegion == r,
      child: Text(r.regionName),
    ))
    .toList();

  void _selectRegionHandler(Region region) {
    setState(() {
      _selectedRegion = region;
      String token = '';
      dio.post<String>(_selectedRegion.authUrl,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key':'my key (actually this should be different per region)',
          },
          responseType: ResponseType.plain
        )).then((r) {
          token = r.data;
          dio.get<String>(_selectedRegion.voiceListUrl,
            options: Options(
              headers: {
                'Authorization':'Bearer '+token,
              }
            )).then((r) {
              _text = r.data;
          }).catchError(print);
        }).catchError(print);
    });
  }
}
