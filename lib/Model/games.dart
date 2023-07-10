import '../Provider/homeProvider.dart';

class GamesModel {
  String? id;
  String? score;
  String? fullname;
  String? abbreviation;
  String? date;
  String? picture;
  String? score2;
  String? picture2;
  String? week;
  String? year;
  String? fullname2;
  String? abbreviation2;


  GamesModel({
    this.id,
    this.score,
    this.score2,
    this.abbreviation,
    this.abbreviation2,
    this.picture,
    this.picture2,
    this.week,
    this.date,
    this.year,
    this.fullname,
    this.fullname2
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      "fullname2": fullname2,
      "fullname2": fullname2,
      "abbreviation2": abbreviation2,
      "abbreviation": abbreviation,
      "picture2": picture2,
      "picture": picture,
      "date": date,
      "year": year,
      "week": week,
      "score2": score2,
      "score": score,
    };
  }

  factory GamesModel.fromJson(jsonData) => GamesModel(
    id: jsonData['_id'],
    fullname2: jsonData['fullname2'],
    fullname: jsonData["fullname"],
    week: jsonData["week"],
    year: jsonData["year"],
    // date: DataProvider().formatStringDate(jsonData["date"]) ,
    date: jsonData["date"],
    picture2: jsonData["picture2"],
    picture: jsonData["picture"],
    score: jsonData["score"],
    score2: jsonData["score2"],
    abbreviation2: jsonData["abbreviation2"],
    abbreviation: jsonData["abbreviation"],
  );
}
