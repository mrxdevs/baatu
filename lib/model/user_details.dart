class UserDetails {
  String? name;
  String? email;
  String? phoneNumber;
  bool isEmailVerified;
  String? uid;
  String? profileImage;
  String? bio;
  String? location;
  String? website;
  String? gender;
  String? dob;
  String? profession;
  List<String>? interests;
  String? education;

  UserDetails({
    this.name,
    this.email,
    this.phoneNumber,
    this.uid,
    this.profileImage,
    this.bio,
    this.location,
    this.website,
    this.gender,
    this.dob,
    this.isEmailVerified = false,
    this.profession,
    this.interests,
    this.education,
  });
}
