class Field {
  String location;
  double size;
  int oliveNo;
  double cubics;
  double price;
  Field(this.location, this.size, this.oliveNo, this.cubics, this.price);
}

class User {
  String firstname;
  String lastname;
  String email;
  String password;
  String confirmpassword;
  List<Field> fields;
  User(
    this.firstname,
    this.lastname,
    this.email,
    this.password,
    this.confirmpassword,
  ) : fields = [];
}
