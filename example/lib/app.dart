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

const TRACKER_HOST = 'http://192.168.1.3:3000/locations';

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
                  'Entre com uma indenticação para que possamos salvar seus dados de forma individual'),
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
                          labelText: 'Indentificação',
                          hintText: 'ex. nome do Github'),
                    ),
                  )
                ],
              ),
            ]),
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('Salvar'), onPressed: _onSelectUsername)
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
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black54, spreadRadius: 2, blurRadius: 3)
                    ],
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
              ),
              Padding(
                padding: EdgeInsets.all(10),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: <Widget>[
                    Center(
                      child: Text(
                        'Este Aplicativo enviara dados para o nosso servidor, voce pode visualizar eles acessando o site:',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center(
                      child: Text(
                        'http://192.168.1.3:3000/$_username',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black54,
                                spreadRadius: 1,
                                blurRadius: 2)
                          ]),
                      margin: EdgeInsets.only(top: 10.0, left: 10.0),
                      child: new ListTile(
                          leading: const Icon(Icons.account_box),
                          title: const Text('Indenticação'),
                          subtitle: Text("$_username"))))
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
                      child: Text('Editar Indentificação'),
                      color: Colors.redAccent,
                      textColor: Colors.white),
                  FlatButton(
                      onPressed: () {},
                      child: Text('Acessar site'),
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
