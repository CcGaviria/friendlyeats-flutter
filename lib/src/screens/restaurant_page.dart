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
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sliver_fab/sliver_fab.dart';

import '../widgets/empty_list.dart';
import '../model/data.dart' as data;
import '../model/restaurant.dart';
import '../model/review.dart';
import '../widgets/app_bar.dart';
import '../widgets/review.dart';
import '../widgets/dialogs/review_create.dart';

class RestaurantPage extends StatefulWidget {
  static const route = '/restaurant';

  final String _restaurantId;
  final String currentUser;

  RestaurantPage({Key key, @required String restaurantId, @required String currentUser})
      : _restaurantId = restaurantId, currentUser = currentUser,
        super(key: key);

  @override
  _RestaurantPageState createState() =>
      _RestaurantPageState(restaurantId: _restaurantId);
}

class _RestaurantPageState extends State<RestaurantPage> {
  StreamSubscription<DocumentSnapshot> _currentSubscription;
  _RestaurantPageState({@required String restaurantId}) {
    FirebaseAuth.instance
        .signInAnonymously()
        .then((UserCredential userCredential) {
          setState(() {
            if (widget.currentUser == null) {
              _userName = 'Anonymous (${kIsWeb ? "Web" : "Mobile"})';
            } else {
              _userName = widget.currentUser;
            }
            _userId = userCredential.user.uid;}
          );
          _currentSubscription?.cancel();
          _currentSubscription = data.loadRestaurant(restaurantId).listen(_updateRestaurant);
    });
  }

  void _updateRestaurant (DocumentSnapshot snapshot) async {
    Restaurant rest;
    rest = await data.getRestaurantFromQuery(snapshot);
    setState(() {
      _restaurant = rest;
    });

    _currentReviewSubscription?.cancel();
    _currentReviewSubscription = _restaurant.reference
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(_updateReviews);
  }

  void _updateReviews (QuerySnapshot reviewSnap) {
    setState(() {
      _isLoading = false;
      _reviews = reviewSnap.docs.map((DocumentSnapshot doc) {
        return Review.fromSnapshot(doc);
      }).toList();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isLoading = true;
  StreamSubscription<QuerySnapshot> _currentReviewSubscription;

  Restaurant _restaurant;
  String _userId;
  String _userName;
  List<Review> _reviews = <Review>[];

  void _onCreateReviewPressed(BuildContext context) async {
    final newReview = await showDialog<Review>(
      context: context,
      builder: (_) => ReviewCreateDialog(
        userId: _userId,
        userName: _userName,
      ),
    );
    if (newReview != null) {
      // Save the review
      return data.addReview(
        restaurantId: _restaurant.id,
        review: newReview,
      );
    }
  }

  void _onAddRandomReviewsPressed() async {
    // Await adding a random number of random reviews
    final numReviews = Random().nextInt(5) + 5;
    for (var i = 0; i < numReviews; i++) {
      await data.addReview(
        restaurantId: _restaurant.id,
        review: Review.random(
          userId: _userId,
          userName: _userName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            body: Builder(
              builder: (context) => SliverFab(
                floatingWidget: FloatingActionButton(
                  tooltip: 'Add a review',
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.add),
                  onPressed: () => _onCreateReviewPressed(context),
                ),
                floatingPosition: FloatingPosition(right: 16),
                expandedHeight: RestaurantAppBar.appBarHeight,
                slivers: <Widget>[
                  RestaurantAppBar(
                    restaurant: _restaurant,
                    onClosePressed: () => Navigator.pop(context),
                  ),
                  _reviews.isNotEmpty
                      ? SliverPadding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(_reviews
                                .map((Review review) =>
                                    RestaurantReview(review: review))
                                .toList()),
                          ),
                        )
                      : SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyListView(
                            child: Text('${_restaurant.name} has no reviews.'),
                            onPressed: _onAddRandomReviewsPressed,
                          ),
                        ),
                ],
              ),
            ),
          );
  }
}

class RestaurantPageArguments {
  final String id;
  final String currentUser;

  RestaurantPageArguments({@required this.id, @required this.currentUser});
}
