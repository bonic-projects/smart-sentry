import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_sentry/app/app.locator.dart';
import 'package:smart_sentry/models/locatio_model.dart';
import 'package:smart_sentry/ui/views/home/home_viewmodel.dart';
import 'package:smart_sentry/ui/views/location/location_view.dart';
import 'package:stacked/stacked.dart';
import 'package:smart_sentry/models/appuser.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.router.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final navigationService = locator<NavigationService>();
    final loggedInUser = UserModel(
      id: currentUser?.uid ?? '',
      name: '',
      email: currentUser?.email ?? 'No Email',
      password: '',
    );

    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(loggedInUser),
      onModelReady: (model) {
        model.initializeLocationService();
        model.listenToNotifications();
        model.loadEmergencyContacts(loggedInUser.id);
        model.fetchUserName();
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.black,
            title: Row(
              children: [
                Text(
                  'SMART SENTRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    viewModel.userName.isNotEmpty
                        ? viewModel.userName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  navigationService.navigateToNotificationView();
                },
                icon: Icon(Icons.notifications_outlined, color: Colors.white),
              ),
              IconButton(
                onPressed: viewModel.logout,
                icon: Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          body: viewModel.isBusy
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  Text(
                    'Your shield in every step',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 60),
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(140),
                        border: Border.all(
                          color: Colors.white24,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(140),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationView(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 80,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'START',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 60),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Add trusted contacts who will be notified in case of emergency.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showSearchBottomSheet(context, viewModel);
            },
            backgroundColor: Colors.white,
            child: Icon(Icons.add, color: Colors.black),
          ),
        );
      },
    );
  }

  void _showSearchBottomSheet(BuildContext context, HomeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Emergency Contact",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Search for User",
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: Icon(Icons.search, color: Colors.white70),
                  ),
                  onChanged: (query) {
                    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                    viewModel.searchUser(query, currentUserId);
                  },
                ),
                SizedBox(height: 24),
                Expanded(
                  child: viewModel.searchResults.isEmpty
                      ? Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                      : ListView.separated(
                    itemCount: viewModel.searchResults.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white24),
                    itemBuilder: (context, index) {
                      final user = viewModel.searchResults[index];
                      return ListTile(
                        title: Text(
                          user.name,
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            if (user.isEmergencyContact) {
                              viewModel.removeEmergencyContact(context,user.id,user.name);
                            } else {
                              viewModel.addEmergencyContact(
                                  context, user.id, user.name);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isEmergencyContact
                                ? Colors.red
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            user.isEmergencyContact ? 'Remove' : 'Add',
                            style: TextStyle(
                              color: user.isEmergencyContact
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}