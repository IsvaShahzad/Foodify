// review_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Add this dependency in pubspec.yaml

class ReviewScreen extends StatefulWidget {
  final String orderId; // Pass orderId to this screen

  ReviewScreen({required this.orderId});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController reviewController = TextEditingController();
  double rating = 0.0; // Initial rating

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: reviewController,
              decoration: InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            Text(
              'Rate your experience:',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  this.rating = rating;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                String review = reviewController.text.trim();
                User? user = FirebaseAuth.instance.currentUser;

                if (review.isNotEmpty && user != null) {
                  // Use the user's email as the document ID
                  String email = user.email ?? 'Unknown User';

                  // Save the review to Firestore
                  await FirebaseFirestore.instance.collection('reviews').doc(email).set({
                    'orderId': widget.orderId,
                    'review': review,
                    'rating': rating,
                    'timestamp': Timestamp.now(),
                  });

                  // Close the screen and show a confirmation message
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Review added successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a review')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
