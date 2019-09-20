import 'dart:convert';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:json_table/json_table.dart';
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

  Map<String, dynamic> toJson() =>
    <String, dynamic>{
      'Name': name,
      'ShortName': shortName,
      'Gender': gender,
      'Locale': locale,
    };
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
  String _voiceListJson = '[{"Name":"Full name of the voice", "ShortName":"Short name of the voice", "Gender":"Female or Male", "Locale":"Two letter language and region code"}]';
  List<dynamic> _voiceList = [];

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
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selected region: ${_selectedRegion.regionName}',
            ),
            Text(
              'URL for list of available voices: ${_selectedRegion.voiceListUrl}',
            ),
            Text(
              'Available voices:',
            ),
            Expanded(
              child: JsonTable(
                jsonDecode(_voiceListJson),
                tableHeaderBuilder: (String header) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                        border: Border.all(width: 0.5),
                        color: Colors.grey[300]),
                    child: Text(
                      header,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.display1.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0,
                          color: Colors.black87),
                    ),
                  );
                },
                tableCellBuilder: (value) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 0.5,
                            color: Colors.grey.withOpacity(0.5))),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.display1.copyWith(
                          fontSize: 14.0, color: Colors.grey[900]),
                    ),
                  );
                },
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
          getVoiceListJson(token).then((voiceListJson) {
            _voiceListJson = voiceListJson;
            _voiceList = jsonDecode(voiceListJson).map((v) => new Voice.fromJson(v)).toList();
          });
        });
      });
    });
  }

  Future<String> fetchKey(String region) async {
    // The key should be stored safely.
    // Suggest manage token (but not key) getter on server.
    // This is just a demo and not recommended.
    // Also, key may be related to region.
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

  Future<String> getVoiceListJson(String token) async {
    String voiceListJson = '';
    Response response = await dio.get<String>(_selectedRegion.voiceListUrl,
      options: Options(
        headers: {
          'Authorization':'Bearer '+token,
        }
      )
    );
    if (response.statusCode == 200) {
      voiceListJson = response.data;
    }
    return voiceListJson;
  }
}
