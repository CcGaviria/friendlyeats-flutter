// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:friendlyeats/src/screens/home_page.dart';

import 'restaurant_page.dart';
import '../model/data.dart' as data;
import '../model/filter.dart';
import '../model/restaurant.dart';
import '../widgets/empty_list.dart';
import '../widgets/filter_bar.dart';
import '../widgets/grid.dart';
import '../widgets/dialogs/filter_select.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "package:http/http.dart" as http;

class LoginPage extends StatefulWidget {
  static const route = '/';

  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {

  bool _isLoading = true;
  bool asAnon = false;
  GoogleSignInAccount _currentUser;
  String _contactText;

  _LoginPageState() {
    FirebaseAuth.instance
        .signInAnonymously()
        .then((UserCredential userCredential) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
        _contactText = _currentUser.displayName;
      });
      print(["->", _currentUser]);
    });
    _googleSignIn.signInSilently();
  }


  @override
  Widget build(BuildContext context) {
    return
      asAnon ? HomePage() :
      _currentUser != null ?
      HomePage(currentUser: _currentUser.displayName,) :
      Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.restaurant),
          title: Text('FriendlyEats'),
        ),
        body: Center(
          child: Container(
              constraints: BoxConstraints(maxWidth: 1280),
              child: _isLoading
                  ? CircularProgressIndicator()
                  : SectionLoginMethods()
          ),
        ),
      );
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Widget SectionLoginMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Image.network(
                  "https://static.gav1r1a.com/goole-g-suit-icon.png",
                  width: 80.0,),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Login with google", style: TextStyle(fontSize: 17.0),)
                )
              ],
            ),
          ),
          onTap: _handleSignIn,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child:
          InkWell(
            child: Text("Continue without login"),
            onTap: () {
              setState(() {
                asAnon = true;
              });
            },
          ),
        ),
      ],
    );
  }
}
