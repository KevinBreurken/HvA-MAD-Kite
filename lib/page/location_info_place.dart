// ignore_for_file: sized_box_for_whitespace

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kiteup/constants.dart';
import 'package:kiteup/dummy%20data/locations.dart';
import 'package:kiteup/dummy%20data/users.dart';
import 'package:kiteup/main.dart';
import 'package:kiteup/notifiers/notifier_kiteup_status.dart';
import 'package:kiteup/notifiers/notifier_planned_location.dart';
import 'package:kiteup/page/location_state_manager.dart';
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
  Location? location;

  List<Event> events = [];

  _LocationInfoPageState();

  setGoingText(String text) {
    setState(() {
      goingText = text;
    });
  }

  addEventItem(Event event) {
    setState(() {
      allEvents.add(event);
    });
  }

  addEvents(List<Event> events) {
    setState(() {
      this.events.clear();
      this.events.addAll(events);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _selectedLocationNotifier =
        Provider.of<SelectedLocationNotifier>(context);
    location = _selectedLocationNotifier.selectedLocation;

    final _kiteupStatusNotifier = Provider.of<KiteupStatusNotifier>(context);
    final _plannedLocationNotifier =
        Provider.of<PlannedLocationNotifier>(context);

    if (location != null) {
      List<Event> matchingEvents =
          fetchEvents(_selectedLocationNotifier.selectedLocation!);
      addEvents(matchingEvents);
    }

    if (_plannedLocationNotifier.plannedLocation != null) {
      if (location!.locationName ==
          _plannedLocationNotifier.plannedLocation!.locationName) {
        goingText = _plannedLocationNotifier.plannedLocation!.arrivalTime!
            .format(context);
      }
    }

    return Scaffold(
        appBar: null,
        body: Scaffold(
          backgroundColor: DARK_BACKGROUND_PRIMARY,
          body: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BackButton(
                    color: Colors.white,
                    onPressed: () => {
                          LocationStateManager.navigator.currentState!
                              .pushNamed('location_list')
                        }),
                Text(_selectedLocationNotifier.selectedLocation!.locationName,
                    style: TextStyle(
                        color: DARK_PRIMARY_TEXT,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
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
                    child: const Text("Activity",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        )))),
            Expanded(
                child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemBuilder: (context, position) {
                        Event event = events[position];
                        return Container(
                          height: 25,
                          child: Center(
                              child: Row(
                            children: [
                              Text(
                                  event.createdAt.hour.toString() +
                                      ":" +
                                      event.createdAt.minute.toString(),
                                  style: const TextStyle(color: Colors.white)),
                              const SizedBox(width: 20),
                              Text(
                                  event.user.name +
                                      " will arive at " +
                                      (event.datetime!.hour.toString() +
                                          ":" +
                                          event.datetime!.minute.toString()),
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          )),
                        );
                      },
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(15, 5, 0, 0),
                      itemCount: events.length,
                    ))),
            ButtonBar(
              mainAxisSize: MainAxisSize.min,
              buttonHeight: 10,
              children: [
                GestureDetector(
                  onTap: () {
                    _selectTime(context, _kiteupStatusNotifier,
                        _plannedLocationNotifier);
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.green.shade600, spreadRadius: 3),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/status_car.svg",
                          width: 20,
                          color: Colors.white,
                        ),
                        Text(goingText,
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
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

                      await storage.remove('planned-location');
                      _plannedLocationNotifier.clearLocation();
                      Navigator.pushNamed(context, 'kiteup_status_page');
                    }
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.green.shade600, spreadRadius: 3),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: const [
                        Icon(Icons.check, color: Colors.white),
                        Text("Kite-up", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                )
              ],
            )
          ]),
        ));
  }

  fetchEvents(Location location) {
    return allEvents
        .where((event) =>
            event.location == location &&
            event.datetime != null &&
            event.type == EventType.GOING)
        .toList();
  }

  _selectTime(BuildContext context, _kiteupStatusNotifier,
      PlannedLocationNotifier _plannedLocationNotifier) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.green,
            secondaryHeaderColor: Colors.green,
          ),
          child: child!,
        );
      },
    );

    if (timeOfDay != null && timeOfDay != selectedTime) {
      final now = DateTime.now();
      final newDateTime = DateTime(
          now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
      final diff = newDateTime.difference(now);

      location!.arrivalTime = timeOfDay;
      _plannedLocationNotifier.updateLocation(location!);
      SharedPreferences storage = await SharedPreferences.getInstance();
      storage.setString('planned-location', jsonEncode(location));

      // Add new event to the list of events
      Event event = Event(
        location: location!,
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
