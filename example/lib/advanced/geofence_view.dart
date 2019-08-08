import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_background_geolocation_example/advanced/util/dialog.dart' as util;

class GeofenceView extends StatefulWidget {
  LatLng center;
  GeofenceView(this.center);
  @override
  State createState() => _GeofenceViewState(this.center);
}

class _GeofenceViewState extends State<GeofenceView> {
  LatLng center;
  String _identifier;
  double _radius = 200.0;
  bool _notifyOnEntry = true;
  bool _notifyOnExit = true;
  bool _notifyOnDwell = false;

  int _loiteringDelay = 10000;

  _GeofenceViewState(this.center);
  void _onClickClose() {
    bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId("CLOSE"));

    //bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId("CLOSE"));
    Navigator.of(context).pop();
  }
  void _onClickAdd() {
    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: _identifier,
        radius: _radius,
        latitude: center.latitude,
        longitude: center.longitude,
        notifyOnEntry: _notifyOnEntry,
        notifyOnExit: _notifyOnExit,
        notifyOnDwell: _notifyOnDwell,
        loiteringDelay: _loiteringDelay,
        extras: {'radius': _radius, 'center': {'latitude': center.latitude, 'longitude': center.longitude}} // meta-data for tracker.transistorsoft.com
    )).then((bool success) {
      bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId('ADD_GEOFENCE'));
    }).catchError((error) {
      print('[addGeofence] ERROR: $error');
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(color: Colors.blue, fontSize: 16.0);

    return new Scaffold(
      appBar: new AppBar(
        brightness: Brightness.light,
        leading: IconButton(onPressed: _onClickClose, icon: Icon(Icons.close), color: Colors.black),
        title: const Text('Add Geofence'),
        backgroundColor: Theme.of(context).bottomAppBarColor,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          MaterialButton(child: Text('Add'), onPressed: _onClickAdd)
        ]
      ),
      body: Container(
        padding: EdgeInsets.only(left: 10.0),
        child: ListView(
          children: <Widget>[
            TextField(
                onChanged: (String value) {_identifier = value;},
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Unique geofence identifier',
                  labelText: "identifier",
                  labelStyle: labelStyle
                )
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Radius',
                    labelStyle: labelStyle
                  ),
                  child: new DropdownButtonHideUnderline(
                    child: new DropdownButton(
                      value: '200',
                      isDense: true,
                      onChanged: (String value) {_radius = double.parse(value);},
                      items: [
                        DropdownMenuItem(value: '150', child: new Text('150')),
                        DropdownMenuItem(value: '200', child: new Text('200')),
                        DropdownMenuItem(value: '500', child: new Text('500')),
                        DropdownMenuItem(value: '1000', child: new Text('1000')),
                        DropdownMenuItem(value: '5000', child: new Text('5000'))
                      ]
                    ),
                  ),
                );
              },
            ),
            FormField(
              builder: (FormFieldState state) {
                return InputDecorator(
                    decoration: InputDecoration(
                      labelStyle: labelStyle,
                      labelText: 'Geofence Transistions'
                      //labelText: name
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(flex: 3, child: Text('notifyOnEntry', style: labelStyle)),
                            Expanded(
                                flex: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Switch(value: _notifyOnEntry, onChanged: (bool value) {
                                        setState(() {
                                          _notifyOnEntry = value;
                                        });
                                      })
                                    ]
                                )
                            )
                          ]
                        ),
                        Row(
                            children: <Widget>[
                              Expanded(flex: 3, child: Text('notifyOnExit', style: labelStyle)),
                              Expanded(
                                  flex: 1,
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Switch(value: _notifyOnExit, onChanged: (bool value) {
                                          setState(() {
                                            _notifyOnExit = value;
                                          });
                                        })
                                      ]
                                  )
                              )
                            ]
                        ),
                        Row(
                            children: <Widget>[
                              Expanded(flex: 3, child: Text('notifyOnDwell', style: TextStyle(color: Colors.blue, fontSize: 15.0))),
                              Expanded(
                                  flex: 1,
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Switch(value: _notifyOnDwell, onChanged: (bool value) {
                                          setState(() {
                                            _notifyOnDwell = value;
                                          });
                                        })
                                      ]
                                  )
                              )
                            ]
                        ),
                        TextField(
                          onChanged: (String value) { _loiteringDelay = int.parse(value); },
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: 'Delay in ms before DWELL transition fires',
                              labelText: "loiteringDelay (milliseconds)",
                              labelStyle: labelStyle,
                              border: InputBorder.none,
                          )
                        ),
                      ]
                    )
                );
              }
            )

          ]
        )
      )
    );
  }
}