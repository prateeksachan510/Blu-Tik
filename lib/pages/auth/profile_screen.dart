import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blu_tik/api/apis.dart';
import 'package:blu_tik/helper/dialogs.dart';
import 'package:blu_tik/models/chat_user.dart';
import 'package:blu_tik/pages/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ChatUser? user;
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();
  String? _image;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _aboutFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _nameFocus.addListener(() {
      setState(() {}); // Update UI when focus changes
    });

    _aboutFocus.addListener(() {
      setState(() {}); // Update UI when focus changes
    });
  }

  void _loadUserData() async {
    try {
      final fetchedUser = await APIs.getChatUser();
      setState(() {
        user = fetchedUser;
        _nameController.text = user?.name ?? '';
        _aboutController.text = user?.about ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _nameFocus.dispose();
    _aboutFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Hide keyboard on tap
      child: Scaffold(
        backgroundColor: AppColors.IappbarkC,
        appBar: AppBar(
          backgroundColor: AppColors.IappbarkC,
          title: const Text("Profile", style: TextStyle(color: Colors.white)),
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        resizeToAvoidBottomInset: true,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    Form(
                      key: _formKey,
                      child: Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _image != null
                                  ? FileImage(
                                      File(_image!)) // Show new selected image
                                  : (user?.image != null &&
                                          user!.image.isNotEmpty)
                                      ? NetworkImage(user!
                                          .image) // Load saved image from Firestore
                                      : null,
                              child: (_image == null &&
                                      (user?.image == null ||
                                          user!.image.isEmpty))
                                  ? Text(
                                      user?.name.isNotEmpty == true
                                          ? user!.name[0].toUpperCase()
                                          : '',
                                      style: const TextStyle(fontSize: 40),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () {
                                  _showEditProfileBottomSheet(context);
                                },
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppColors.appbarkC,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.darkYellowC,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    //UID display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "UID: ",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkYellowC,
                          ),
                        ),
                        Text(
                          user?.id ?? "N/A",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Email Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email,
                            size: 16, color: AppColors.darkYellowC),
                        const SizedBox(width: 5),
                        Text(
                          user?.email ?? "N/A",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    // Editable Name Field
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      // onSaved: (val) => APIs.user.displayName = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      onSaved: (val) {
                        if (val != null && val.isNotEmpty) {
                          setState(() {
                            user = user!.copyWith(name: val);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(
                          color: _nameFocus.hasFocus
                              ? AppColors.darkYellowC
                              : Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.person,
                            color: AppColors.darkYellowC),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.darkYellowC),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Editable About Field
                    TextFormField(
                      controller: _aboutController,
                      focusNode: _aboutFocus,
                      //  onSaved: (val) => APIs.user.about = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',

                      onSaved: (val) {
                        if (val != null && val.isNotEmpty) {
                          setState(() {
                            user = user!.copyWith(about: val);
                          });
                        }
                      },

                      decoration: InputDecoration(
                        labelText: "About",
                        labelStyle: TextStyle(
                          color: _aboutFocus.hasFocus
                              ? AppColors.darkYellowC
                              : Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.info_outline,
                            color: AppColors.darkYellowC),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.darkYellowC),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          String? imageUrl;
                          if (_image != null) {
                            imageUrl =
                                await APIs.uploadImageToImageKit(_image!);
                          }

                          APIs.updateUserInfo(
                                  _nameController.text, _aboutController.text,
                                  imageUrl: imageUrl)
                              .then((success) {
                            if (success) {
                              Dialogs.showSnackbar(
                                  context, 'Profile Updated Successfully');
                            } else {
                              Dialogs.showSnackbar(
                                  context, 'Failed to update profile');
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appbarkC,
                      ),
                      child: const Text("Save Changes",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await APIs.auth.signOut();
            await GoogleSignIn().signOut().then((_) async {
              Navigator.pop(context);
              await Navigator.pushReplacementNamed(context, '/getstarted');
            });
            print('Logged out!');
          },
          backgroundColor: AppColors.darkYellowC,
          icon: const Icon(Icons.logout),
          label: const Text("Log Out"),
        ),
      ),
    );
  }

  // void _saveProfile() {
  //   if (user == null) return;

  //   setState(() {
  //     user = user!.copyWith(
  //       name: _nameController.text,
  //       about: _aboutController.text,
  //     );
  //   });

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Profile updated successfully!")),
  //   );
  // }

  // void _changeProfilePicture() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Change Profile Picture Clicked!")),
  //   );
  // }

  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.IappbarkC,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Profile Picture",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    child: Column(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            "images/camera.jpg",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text("Camera",
                            style: TextStyle(color: Colors.white))
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Column(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            "images/media_picker.png",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text("Gallery",
                            style: TextStyle(color: Colors.white))
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      debugPrint("image path: ${image.path} ");

      setState(() {
        _image = image.path; // Ensure _image is of type String if used this way
      });

      // Upload image to ImageKit
      String? uploadedUrl = await APIs.uploadImageToImageKit(image.path);
      if (uploadedUrl != null) {
        // Save uploaded URL to Firestore
        await APIs.updateUserProfileImage(uploadedUrl);
        setState(() {
          user = user!.copyWith(image: uploadedUrl);
        });
      } else {
        Dialogs.showSnackbar(context, "Failed to upload image");
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    // final picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    // if (image != null) {
    //   debugPrint("image path: ${image.path} -- Mime type: ${image.mimeType}");
    //   setState(() {
    //     _image = image.path; // Ensure _image is of type String if used this way
    //   });

    //   // Upload image to ImageKit
    //   String? uploadedUrl = await APIs.uploadImageToImageKit(image.path);
    //   if (uploadedUrl != null) {
    //     // Save uploaded URL to Firestore
    //     await APIs.updateUserProfileImage(uploadedUrl);
    //     setState(() {
    //       user = user!.copyWith(image: uploadedUrl);
    //     });
    //   } else {
    //     Dialogs.showSnackbar(context, "Failed to upload image");
    //   }
    // }

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (_image == pickedFile.path) {
      print("Same image selected, skipping upload.");
      return; // Prevent duplicate upload
    }

    setState(() => _image = pickedFile.path);
  }
}
