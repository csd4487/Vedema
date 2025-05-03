class Expense {
  String task;
  String date;
  double cost;
  String synthesis;
  String type;
  String npk;
  String notes;

  Expense({
    this.task = '',
    this.date = '',
    this.cost = 0.0,
    this.synthesis = '',
    this.type = '',
    this.npk = '',
    this.notes = '',
  });
}

class Note {
  String text;
  String date;

  Note({this.text = '', this.date = ''});
}

class Profit {
  int sacks;
  double price;

  Profit({this.sacks = 0, this.price = 0.0});
}

class OtherExpense {
  String task;
  String date;
  double cost;
  String notes;

  OtherExpense({
    this.task = '',
    this.date = '',
    this.cost = 0.0,
    this.notes = '',
  });
}

class Field {
  String location;
  double size;
  int oliveNo;
  double cubics;
  double price;
  String species;

  List<Expense> expenses;
  List<Profit> profits;
  double totalExpenses;
  double totalProfits;

  Field(
    this.location,
    this.size,
    this.oliveNo,
    this.cubics,
    this.price,
    this.species,
  ) : expenses = [],
      profits = [],
      totalExpenses = 0.0,
      totalProfits = 0.0;
}

class User {
  String firstname;
  String lastname;
  String email;
  String password;
  String confirmpassword;

  List<Field> fields;
  double totalExpenses;
  double totalProfits;
  List<OtherExpense> otherExpenses;
  List<Note> notes;

  User(
    this.firstname,
    this.lastname,
    this.email,
    this.password,
    this.confirmpassword,
  ) : fields = [],
      totalExpenses = 0.0,
      totalProfits = 0.0,
      otherExpenses = [],
      notes = [];
}
