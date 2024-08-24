import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../cart_screens/cart.dart';
import '../widgets/maps.dart';
import '../widgets/progress_bar.dart';
import '../widgets/progressbar_shipping.dart';
import 'delivered_screen.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isCheckboxChecked = false;
  String userFirstName = 'User';
  String userEmail = 'user@example.com';
  String userAddress = '';
  String userArea = '';
  List<Map<String, dynamic>> orderItems = []; // List to hold the order items

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchUserAddress();
    _fetchOrderItems(); // Fetch the order items when initializing
  }

  Future<void> _fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (userDoc.exists) {
        setState(() {
          userFirstName = userDoc['firstname'] ?? 'User';
          userEmail = user.email ?? 'user@example.com';
        });
      }
    }
  }

  Future<void> _fetchUserAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot addressDoc = await FirebaseFirestore.instance
          .collection('shippingdetails')
          .doc(user.email)
          .get();

      if (addressDoc.exists) {
        setState(() {
          userAddress = addressDoc['Address'] ?? 'No address available';
          userArea = addressDoc['Area'] ?? 'No area available';
        });
      }
    }
  }

  Future<void> _fetchOrderItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
            .collection('cartitems')
            .doc(user.email)
            .collection('orders')
            .orderBy('Timestamp', descending: true) // Order by most recent
            .limit(1) // Fetch only the most recent item
            .get();

        List<Map<String, dynamic>> fetchedItems = [];
        for (var doc in ordersSnapshot.docs) {
          final orderData = doc.data() as Map<String, dynamic>;
          if (orderData != null) {
            fetchedItems.add(orderData);
            // Print fetched cart items to the terminal
            print('Fetched Order Item: ${orderData}');
          }
        }
        setState(() {
          orderItems = fetchedItems;
        });
      } catch (e) {
        print('Error fetching order items: $e');
      }
    }
  }

  Future<void> placeOrder() async {
    if (!isCheckboxChecked) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            title: Text(
              'Error',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Please confirm your order by checking the checkbox.',
              style: TextStyle(
                fontFamily: 'Montserrat',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                      fontFamily: 'Montserrat', color: Colors.blueGrey),
                ),
              ),
            ],
          );
        },
      );
    } else {
      try {
        final email = FirebaseAuth.instance.currentUser?.email ?? 'unknown@example.com';

        // Reference to the user's document in the 'cartitems' collection
        final userDocRef = FirebaseFirestore.instance.collection('cartitems').doc(email);

        // Reference to the 'orders' subcollection for the user
        final ordersCollectionRef = userDocRef.collection('orders');

        // Fetch the most recent order document
        final ordersQuery = await ordersCollectionRef.orderBy('Timestamp', descending: true).limit(1).get();

        List<Map<String, dynamic>> items = [];

        for (var doc in ordersQuery.docs) {
          final orderData = doc.data();
          if (orderData != null) {
            items.add(orderData);
          }
        }

        // Reference to the user's document in the 'finalorder' collection
        final finalOrderDocRef = FirebaseFirestore.instance.collection('finalorder').doc(email);

        // Store the order details including cart items in the user's document
        await finalOrderDocRef.collection('orders').add({
          'username': userFirstName,
          'email': userEmail,
          'status': 'Order Confirmed',
          'timestamp': FieldValue.serverTimestamp(),
          'items': items, // Save cart items in the new order
        });

        // Optionally, clear the cart items
        for (var doc in ordersQuery.docs) {
          await doc.reference.delete();
        }

        // Fetch and display the most recent order items again
        await _fetchOrderItems();

        // Navigate to DeliveredScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => DeliveredScreen()),
        );
      } catch (e) {
        print('Error adding order to Firestore: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // Make the screen scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ProgressBarShipping(
              steps: ['Menu', 'Cart', 'Payment'],
              currentIndex: 1, // Adjust this based on the current step
            ),
            SizedBox(height: 5),
            Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  MapWidget(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${userAddress}, ${userArea}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontFamily: 'Montserrat',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                    leading: Checkbox(
                      value: isCheckboxChecked,
                      onChanged: (value) {
                        setState(() {
                          isCheckboxChecked = value!;
                        });
                      },
                    ),
                    title: Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    dense: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10), // Add space between cards
            Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Divider(),
                  ...orderItems.map((order) {
                    final items = List<Map<String, dynamic>>.from(order['Items'] ?? []);
                    return Column(
                      children: items.map((item) {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                          leading: Image.network(
                            item['Image URL'] ?? '', // Provide a default value
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item['Item Name'] ?? 'Unknown Item'),
                          subtitle: Text('Quantity: ${item['Quantity'] ?? 0}'),
                          trailing: Text('Rs. ${item['Price']?.toStringAsFixed(2) ?? '0.00'}'),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.08),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: placeOrder,
                  child: Text(
                    'Place Order',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.05,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}
