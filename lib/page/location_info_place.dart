// ignore_for_file: sized_box_for_whitespace

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kiteup/constants.dart';
import 'package:kiteup/dummy%20data/locations.dart';
import 'package:kiteup/dummy%20data/users.dart';
import 'package:kiteup/notifiers/notifier_kiteup_status.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifiers/notifier_selected_location.dart';
import '../widgets/modals/modal_session.dart';
import '../widgets/modals/modal_session_data.dart';

import 'package:kiteup/dummy%20data/events.dart';

class KiteupLocationPage extends StatefulWidget {
  KiteupLocationPage();

  @override
  _LocationInfoPageState createState() => _LocationInfoPageState();
}

class _LocationInfoPageState extends State<KiteupLocationPage> {
  TimeOfDay selectedTime = TimeOfDay.now();
  String goingText = " Going";
  List<Event> events = [];

  _LocationInfoPageState();

  setGoingText(String text) {
    setState(() {
      goingText = text;
    });
  }

  addEventItem(Event event){
    setState(() {
      allEvents.add(event);
    });
  }

  addEvents(List<Event> events){
    setState(() {
      this.events.clear();
      this.events.addAll(events);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _selectedLocationNotifier =
        Provider.of<SelectedLocationNotifier>(context);
        
    final _kiteupStatusNotifier =
        Provider.of<KiteupStatusNotifier>(context);

    List<Event> matchingEvents = fetchEvents(_selectedLocationNotifier.selectedLocation);
    addEvents(matchingEvents);
    
    return Scaffold(
        appBar: null,
        body: Scaffold(
          backgroundColor: DARK_BACKGROUND_PRIMARY,
          body: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (goingText == " Going")
                  BackButton(
                      color: Colors.white,
                      onPressed: () => {Navigator.pop(context)})
                else
                  Container(),
                Text(_selectedLocationNotifier.selectedLocation.locationName,
                    style: Theme.of(context).textTheme.headlineLarge),
                Container(
                  margin: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.favorite,
                    size: 30.0,
                    color: Colors.blueGrey,
                    semanticLabel: 'Click to add to favorites',
                  ),
                ),
              ],
            ),
            Image.asset('assets/graph.png'),
            Align(
                alignment: Alignment.centerLeft,
                child: Container(
                    margin: const EdgeInsetsDirectional.fromSTEB(15, 30, 0, 0),
                    child: Text("Activity",
                      style: Theme.of(context).textTheme.titleLarge))),
            Expanded(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  itemBuilder: (context, position) {
                    Event event = events[position];
                    return Container(
                      height: 25,
                      child: Center(child: Row(
                        children: [
                          Text(event.createdAt.hour.toString() + ":" + event.createdAt.minute.toString(),
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(width: 20),
                          Text(event.user.name + " will arive at " + (event.datetime!.hour.toString() + ":" + event.datetime!.minute.toString()),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      )),
                    );
                  },
                  padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 0, 0),
                  itemCount: events.length,
                )
              )
            ),
            Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Spacer(flex: 3),
          ElevatedButton.icon(
            onPressed: (){_selectTime(context, _kiteupStatusNotifier, _selectedLocationNotifier);},
            label: Text(
              goingText,
              style: TextStyle(color: BUTTON_PRIMARY_TEXT, fontSize: 20),
            ),
            icon: SvgPicture.asset(
              "assets/status_car.svg",
              width: 20,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.only(left: 30, top: 20, bottom: 20, right: 30),
                primary: BUTTON_PRIMARY,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(180))),
          ),
      Spacer(flex: 1),
            ElevatedButton.icon(
              onPressed: ()async {
                var sessionData = await showDialog(
                    context: context,
                    builder: (context) {
                      return ModalSession();
                    });

                if (sessionData[0] != null &&
                    sessionData[1] != null &&
                    sessionData[2] != null) {
                  var endDateTime =
                  DateTime.now().add(Duration(seconds: sessionData[2]));
                  var storage = await SharedPreferences.getInstance();
                  await storage.setString('kiteup-status', 'Gear-Up');
                  await storage.setString(
                      'kiteup-preparation-time', endDateTime.toString());
                  await storage.setString(
                      'kiteup-board-data',
                      boardSizes[sessionData[0]] +
                          ', ' +
                          boardTypes[sessionData[1]]);
                  Navigator.pushNamed(context, 'kiteup_status_page');
                }
              },
              label: Text(
                "Kite-up",
                style: TextStyle(color: BUTTON_PRIMARY_TEXT, fontSize: 20),
              ),
              icon: Icon(
                Icons.check,
                color: BUTTON_PRIMARY_TEXT,
              ),
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.only(left: 30, top: 20, bottom: 20, right: 30),
                  primary: BUTTON_PRIMARY,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(180))),
            ),
      Spacer(flex: 3),
      ],
    ),
          ]),
        ));
  }

  fetchEvents(Location location){
    return allEvents.where((event) => event.location == location && event.datetime != null && event.type == EventType.GOING).toList();
  }
  
  _selectTime(BuildContext context, _kiteupStatusNotifier, _selectedLocationNotifier) async {          
      final TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        initialEntryMode: TimePickerEntryMode.dial,
      );

      if(timeOfDay != null && timeOfDay != selectedTime)
        {
          final now = DateTime.now();
          final newDateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
          final diff = newDateTime.difference(now);

          // Add new event to the list of events
          Event event = Event(
            location: _selectedLocationNotifier.selectedLocation,
            user: allUsers[0],
            createdAt: DateTime.now(),
            type: EventType.GOING,
            datetime: DateTime.now().add(diff),
          );

          setGoingText(" " + timeOfDay.format(context));
          _kiteupStatusNotifier.updateStatus("Traveling");
          
          addEventItem(event);
        } else {
          setGoingText(" Going");
          _kiteupStatusNotifier.updateStatus("");
        }
  }
}
