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
    // Ensure that `currentUser` is not null and map it to `UserModel`
    final loggedInUser = UserModel(
      id: currentUser?.uid ?? '',
      name: currentUser?.displayName ?? 'Unknown User',
      email: currentUser?.email ?? 'No Email',
      password: '', // Leave password blank as it's not available here
    );
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(loggedInUser),
      onModelReady: (model) {
        model.initializeLocationService();
        model.listenToNotifications();
        model.loadEmergencyContacts(
            loggedInUser.id); // Load emergency contacts on startup
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.teal,
          appBar: AppBar(
              title: Text('Smart Sentry'),
              backgroundColor: Colors.greenAccent,
              actions: [
                Text("${currentUser?.displayName}"),
                IconButton(
                  onPressed: () {
                    navigationService.navigateToNotificationView();
                  },
                  icon: Icon(Icons
                      .notifications), // Provide the required icon argument
                ),
                IconButton(
                    onPressed: viewModel.logout, icon: Icon(Icons.logout))
              ]),
          body: viewModel.isBusy
              ? Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // // Message Display
                      // viewModel.message != null
                      //     ? Text(
                      //         viewModel.message!,
                      //         style:
                      //             TextStyle(fontSize: 16, color: Colors.green),
                      //       )
                      //     : SizedBox.shrink(),
                      SizedBox(height: 20),

                      Container(
                        width: 200,
                        height: 200,
                        // decoration: BoxDecoration(
                        //   borderRadius: BorderRadius.circular(15),
                        //   image: DecorationImage(
                        //     image: AssetImage('assets/your_image.jpg'),
                        //     fit: BoxFit.cover,
                        //   ),
                        // ),
                        child: Card(
                          color: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationView(),
                                ),
                              );
                            },
                            child: Center(
                              child: Text(
                                'Start',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showSearchBottomSheet(context, viewModel);
            },
            backgroundColor: Colors.green,
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
  // Show dialog to add emergency contact

  void _showSearchBottomSheet(BuildContext context, HomeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Adjust for keyboard
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6, // Limit height
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Field
                TextField(
                  decoration: InputDecoration(
                    labelText: "Search for User",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    String currentUserId =
                        FirebaseAuth.instance.currentUser?.uid ??
                            ''; // Get current user's ID
                    viewModel.searchUser(query,
                        currentUserId); // Pass both query and currentUserId
                  },
                ),
                const SizedBox(height: 16),
                // Title for search results
                Text(
                  "Search Results",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Search Results List
                Expanded(
                  child: viewModel.searchResults.isEmpty
                      ? Center(child: Text("No users found"))
                      : ListView.separated(
                          itemCount: viewModel.searchResults.length,
                          separatorBuilder: (_, __) => Divider(),
                          itemBuilder: (context, index) {
                            final user = viewModel.searchResults[index];
                            return ListTile(
                              title: Text(user.name),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  if (user.isEmergencyContact) {
                                    viewModel.removeEmergencyContact(user.id);
                                  } else {
                                    viewModel.addEmergencyContact(
                                        context, user.id, user.name);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: user.isEmergencyContact
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                child: Text(
                                  user.isEmergencyContact ? 'Remove' : 'Add',
                                  style: TextStyle(color: Colors.white),
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
