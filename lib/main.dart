import 'dart:convert';
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
  const Region(
    'Southeast Asia',
    'https://southeastasia.tts.speech.microsoft.com/cognitiveservices/voices/list',
    'https://southeastasia.api.cognitive.microsoft.com/sts/v1.0/issueToken',
    'southeastasia'),
  const Region(
    'West US',
    'https://westus.tts.speech.microsoft.com/cognitiveservices/voices/list',
    'https://westus.api.cognitive.microsoft.com/sts/v1.0/issueToken',
    'westus'),
];

class Region {
  final String regionName;
  final String voiceListUrl;
  final String authUrl;
  final String region;

  const Region(this.regionName, this.voiceListUrl, this.authUrl, this.region);
}

class Voice {
  final String name;
  final String shortName;
  final String gender;
  final String locale;

  Voice(this.name, this.shortName, this.gender, this.locale);

  Voice.fromJson(Map<String, dynamic> json) :
    name = json['Name'],
    shortName = json['ShortName'],
    gender = json['Gender'],
    locale = json['Locale'];
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Available voices per region'),
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
  List<Voice> _voiceList = [];

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
          children: [
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
              child: ListView(
                shrinkWrap: true,
                children: _voiceList.map((voice) => Text(voice.name)).toList(),
              ),
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
      fetchKey(_selectedRegion.region).then((key) {
        fetchToken(key).then((token) {
          getVoiceList(token).then((voiceList) {
            _voiceList = voiceList;
          });
        });
      });
    });
  }

  Future<String> fetchKey(String region) async {
    // The key should be stored safely.
    // Suggest manage token getter on server.
    // This is just a demo and not recommended.
    String key = '';
    Response response = await dio.get<String>(
      'http://localhost:8000',
      options: Options(
        responseType: ResponseType.plain
      )
    );
    if (response.statusCode == 200) {
      key = response.data;
    }
    return key;
  }

  Future<String> fetchToken(String key) async {
    // The key should be stored safely.
    // Suggest manage token getter on server.
    // This is just a demo and not recommended.
    String token = '';
    Response response = await dio.post<String>(
      _selectedRegion.authUrl,
      options: Options(
        headers: {
          'Ocp-Apim-Subscription-Key':key,
        },
        responseType: ResponseType.plain
      )
    );
    if (response.statusCode == 200) {
      token = response.data;
    }
    return token;
  }

  Future<List<Voice>> getVoiceList(String token) async {
    List<Voice> voicesList = [];
    Response response = await dio.get<String>(_selectedRegion.voiceListUrl,
      options: Options(
        headers: {
          'Authorization':'Bearer '+token,
        }
      )
    );
    if (response.statusCode == 200) {
      List responseJson = json.decode(response.data);
      voicesList = responseJson.map((v) => new Voice.fromJson(v)).toList();
    }
    return voicesList;
  }
}
