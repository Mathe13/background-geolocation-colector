///
/// NOTE:  There's nothing particularly interesting in this class for BackgroundGeolocation.
/// This is just a bootstrap app for selecting app to run (Hello World App, Advanced App).
///
/// Go look at the source for those apps instead.
///

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import 'hello_world/app.dart';
import 'advanced/app.dart';
import 'package:flutter_background_geolocation_example/advanced/util/dialog.dart'
    as util;

const TRACKER_HOST = 'http://tracker.transistorsoft.com/locations/';

class HomeApp extends StatefulWidget {
  @override
  _HomeAppState createState() => new _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        theme: Theme.of(context).copyWith(
            accentColor: Colors.black,
            primaryTextTheme: Theme.of(context).primaryTextTheme.apply(
                  bodyColor: Colors.black,
                )),
        home: new _HomeView());
  }
}

class _HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => new _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  static const USERNAME_REGEXP = r"^[a-zA-Z0-9_-]*$";

  String _usernameRaw;
  String _username;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  @override
  void initState() {
    super.initState();
    _usernameRaw = '';
    _username = '';
    _initPlatformState();
  }

  void _initPlatformState() async {
    // Reset selected app.
    final SharedPreferences prefs = await _prefs;
    prefs.setString("app", "");

    // Set username.
    String username = prefs.getString("username");
    if (_usernameIsValid(username)) {
      setState(() {
        _username = username;
      });
    }
  }

  void _showDialog() {
    TextEditingController controller =
        new TextEditingController(text: _username);
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            height: 200.0,
            child: Column(children: <Widget>[
              new Text(
                  'Please enter a unique identifier so that BackgroundGeolocation can post locations to the demo server:'),
              new Text('tracker.transistorsoft.com'),
              new Row(
                children: <Widget>[
                  Expanded(
                    child: new TextField(
                      controller: controller,
                      onChanged: (String value) {
                        setState(() {
                          _usernameRaw = value;
                        });
                      },
                      autofocus: true,
                      decoration: new InputDecoration(
                          labelText: 'Username',
                          hintText: 'eg. Github username'),
                    ),
                  )
                ],
              ),
            ]),
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('Save'), onPressed: _onSelectUsername)
          ],
        );
      },
    );
  }

  _onSelectUsername() async {
    if (_usernameIsValid(_usernameRaw)) {
      setState(() {
        _username = _usernameRaw;
      });
      final SharedPreferences prefs = await _prefs;
      prefs.setString("username", _username);

      Navigator.pop(context);
    }
  }

  bool _usernameIsValid(String username) {
    return (username != null) &&
        new RegExp(USERNAME_REGEXP).hasMatch(username) &&
        (username.length > 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('MDM Coletor'),
          backgroundColor: Color(0xFF4caf50),
        ),
        body: Container(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10),
              ),
              Image(
                image: NetworkImage(
                    'https://www.uergs.edu.br/upload/arquivos/201611/23155140-uergs-logotipo-horizontal-verde.png'),
              ),
              Padding(
                padding: EdgeInsets.all(20),
              ),
              Center(
                child: Text(
                  'Este aplicativo é um protótipo\nseu uso pode apresentar bugs e erros inesperados.\n Sinta-se livre pra reportar erros no email\n matheus-lima@uergs.edu.br',
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
              ),
              Container(
                // width: double.infinity,
                decoration: BoxDecoration(
                    color: Color(0xFF4caf50),
                    borderRadius: BorderRadius.all(Radius.circular(40))),
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: FlatButton(
                  padding: EdgeInsets.symmetric(vertical: 13.0),
                  child: Text(
                    "Coletor",
                  ),
                  onPressed: () => {navigate('advanced')},
                ),
              )
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  FlatButton(
                      onPressed: () {
                        _showDialog();
                      },
                      child: Text('Edit Username'),
                      color: Colors.redAccent,
                      textColor: Colors.white),
                  FlatButton(
                      onPressed: () {},
                      child: Text('View Tracking'),
                      color: Colors.blue,
                      textColor: Colors.white),
                ])));
  }

  MaterialButton _buildApplicationButton(String text, {onPressed: Function}) {
    return MaterialButton(
        onPressed: onPressed,
        child: Text(text, style: TextStyle(fontSize: 18.0)),
        // color: Colors.amber,
        height: 50.0);
  }

  void navigate(String appName) async {
    if (!_usernameIsValid(_username)) {
      _showDialog();
      return;
    }
    // Apply tracker url with username & device params for recognition by tracker server.
    Map<String, dynamic> deviceParams = await bg.Config.deviceParams;
    bg.BackgroundGeolocation.setConfig(
        bg.Config(url: TRACKER_HOST + _username, params: deviceParams));

    final SharedPreferences prefs = await _prefs;
    prefs.setString("app", appName);

    Widget app;
    switch (appName) {
      case HelloWorldApp.NAME:
        app = new HelloWorldApp();
        break;
      case AdvancedApp.NAME:
        app = new AdvancedApp();
        break;
      default:
        return;
        break;
    }
    bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId("OPEN"));
    runApp(app);
  }
}
