class ContactOsPayload {
  const ContactOsPayload({
    required this.name,
    this.phone,
    this.email,
    this.company,
    this.jobTitle,
    this.address,
    this.website,
    this.birthday,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? company;
  final String? jobTitle;
  final String? address;
  final String? website;
  final DateTime? birthday;
}
