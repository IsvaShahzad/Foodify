import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressScreen extends StatefulWidget {
  final String mobileNumber;
  final String address;
  final String province;

  AddressScreen({
    required this.mobileNumber,
    required this.address,
    required this.province,
  });

  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedProvince = '';
  bool _isEditing = false;

  final List<String> _provinceOptions = [
    'Bahria Phase 1-4',
    'Bahria Phase 7-8',
    'DHA Phase 1',
    'DHA Phase 2',
    'Gulraiz',
    'Chaklala',
    'Pwd'
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _mobileController.text =
            prefs.getString('mobileNumber') ?? widget.mobileNumber;
        _addressController.text = prefs.getString('address') ?? widget.address;
        _selectedProvince = prefs.getString('province') ?? widget.province;
      });

      final addressDoc = await FirebaseFirestore.instance
          .collection('shippingdetails')
          .doc(user.email)
          .get();

      if (addressDoc.exists) {
        final data = addressDoc.data() as Map<String, dynamic>?;

        setState(() {

          _mobileController.text =
              data?['Mobile Number'] ?? _mobileController.text;
          _addressController.text = data?['Address'] ?? _addressController.text;
          _selectedProvince = data?['Area'] ?? _selectedProvince;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_formKey.currentState?.validate() ?? false) {
        try {
          await FirebaseFirestore.instance
              .collection('shippingdetails')
              .doc(user.email)
              .set({
            'Email': user.email ?? 'Unknown',

            'Mobile Number': _mobileController.text,
            'Address': _addressController.text,
            'Area': _selectedProvince,
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('postalCode', _postalCodeController.text);
          await prefs.setString('mobileNumber', _mobileController.text);
          await prefs.setString('address', _addressController.text);
          await prefs.setString('province', _selectedProvince);

          setState(() {
            _isEditing = false; // Return to view mode after saving
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Address updated successfully!')),
          );
        } catch (e) {
          print('Error saving address: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving address. Please try again.')),
          );
        }
      }
    } else {
      print('No user is currently signed in.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to save address.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Address',
          style: TextStyle(fontFamily: 'Kanit', fontSize: 22, letterSpacing: 0.5),
        ),
        actions: [],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: _isEditing ? _buildEditForm() : _buildAddressView(),
      ),
    );
  }

  Widget _buildAddressView() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 40.0.h, // Adjust vertical padding to move the card down
        horizontal: 16.0.w, // Optional: Horizontal padding for spacing from edges
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch the column to full width
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0), // Slightly rounded corners
            ),
            elevation: 1.5,
            child: SizedBox(
              height: 120.h, // Set a fixed height for the Card
              child: ListView(
                padding: EdgeInsets.all(12.0.w), // Padding inside the ListView
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _addressController.text,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            SizedBox(height: 5.h), // Space between text elements
                            Text(
                              _mobileController.text,
                              style: TextStyle(fontFamily: 'Montserrat'),
                            ),
                            Text(
                              _selectedProvince,
                              style: TextStyle(fontFamily: 'Montserrat'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 300.h), // Space before the button
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isEditing = true; // Toggle to edit mode
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFB3C6D1),
              padding: EdgeInsets.symmetric(vertical: 12.0.h), // Adjust padding as needed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.0),
              ),
              elevation: 1.0,
            ),
            child: Text(
              'Change Address',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Container(
        height: screenHeight * 0.7, // Adjust height to fit the screen if needed
        padding: EdgeInsets.all(16.0.w), // Padding inside the Container
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.0), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 2,
              offset: Offset(0, 2), // Shadow position
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Postal Code Field
         // Space between fields

              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle(color: Colors.grey[700]), // Label text color
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // Underline color
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // Underline color
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  return null;
                },
                cursorColor: Colors.blueGrey, // Cursor color
                style: TextStyle(fontFamily: 'Montserrat'), // Font family
              ),
              SizedBox(height: 16.h), // Space between fields

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Colors.grey[700]), // Label text color
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // Underline color
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // Underline color
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
                cursorColor: Colors.blueGrey, // Cursor color
                style: TextStyle(fontFamily: 'Montserrat'), // Font family
              ),
              SizedBox(height: 16.h), // Space between fields

              // Province Dropdown
              DropdownButtonFormField<String>(
                value: _selectedProvince.isEmpty ? null : _selectedProvince,
                decoration: InputDecoration(
                  labelText: 'Province',
                  labelStyle: TextStyle(color: Colors.grey[700]), // Label text color
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // Underline color
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // Underline color
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value!;
                  });
                },
                items: _provinceOptions.map((province) {
                  return DropdownMenuItem(
                    value: province,
                    child: Text(province, style: TextStyle(fontFamily: 'Montserrat')),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select area';
                  }
                  return null;
                },
              ),
              SizedBox(height: 90.h), // Space before the save button

              // Save Button
              SizedBox(
                width: double.infinity,

                // Full-width button
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFB3C6D1),
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      elevation: 1.0,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h), // Space after the button
            ],
          ),
        ),
      ),
    );
  }
}
