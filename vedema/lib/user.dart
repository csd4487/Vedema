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

class SackProduction {
  int sacks;
  String dateProduced;

  SackProduction({this.sacks = 0, this.dateProduced = ''});
}

class OilProduction {
  int sacksUsed;
  double oilKg;
  String dateGrinded;

  OilProduction({this.sacksUsed = 0, this.oilKg = 0.0, this.dateGrinded = ''});
}

class OilProfit {
  double oilKgSold;
  double pricePerKg;
  double totalEarned;
  String dateSold;

  OilProfit({
    this.oilKgSold = 0.0,
    this.pricePerKg = 0.0,
    this.totalEarned = 0.0,
    this.dateSold = '',
  });
}

class OtherProfit {
  String type;
  String date;
  double profitNo;
  String notes;

  OtherProfit({
    this.type = '',
    this.date = '',
    this.profitNo = 0.0,
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
  List<SackProduction> sackProductions;
  List<OilProduction> oilProductions;
  List<OilProfit> oilProfits;

  double totalExpenses;
  double totalProfits;
  int availableSacks;
  double oilKg;

  Field(
    this.location,
    this.size,
    this.oliveNo,
    this.cubics,
    this.price,
    this.species,
  ) : expenses = [],
      sackProductions = [],
      oilProductions = [],
      oilProfits = [],
      totalExpenses = 0.0,
      totalProfits = 0.0,
      availableSacks = 0,
      oilKg = 0.0;
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
  List<OtherProfit> otherProfits;
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
      otherProfits = [],
      notes = [];
}
