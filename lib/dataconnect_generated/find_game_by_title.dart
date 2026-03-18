part of 'generated.dart';

class FindGameByTitleVariablesBuilder {
  String title;

  final FirebaseDataConnect _dataConnect;
  FindGameByTitleVariablesBuilder(this._dataConnect, {required  this.title,});
  Deserializer<FindGameByTitleData> dataDeserializer = (dynamic json)  => FindGameByTitleData.fromJson(jsonDecode(json));
  Serializer<FindGameByTitleVariables> varsSerializer = (FindGameByTitleVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindGameByTitleData, FindGameByTitleVariables>> execute() {
    return ref().execute();
  }

  QueryRef<FindGameByTitleData, FindGameByTitleVariables> ref() {
    FindGameByTitleVariables vars= FindGameByTitleVariables(title: title,);
    return _dataConnect.query("FindGameByTitle", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FindGameByTitleGames {
  final String id;
  final String title;
  final String publisher;
  final String? description;
  FindGameByTitleGames.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  title = nativeFromJson<String>(json['title']),
  publisher = nativeFromJson<String>(json['publisher']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindGameByTitleGames otherTyped = other as FindGameByTitleGames;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    publisher == otherTyped.publisher && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, publisher.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['publisher'] = nativeToJson<String>(publisher);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  const FindGameByTitleGames({
    required this.id,
    required this.title,
    required this.publisher,
    this.description,
  });
}

@immutable
class FindGameByTitleData {
  final List<FindGameByTitleGames> games;
  FindGameByTitleData.fromJson(dynamic json):
  
  games = (json['games'] as List<dynamic>)
        .map((e) => FindGameByTitleGames.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindGameByTitleData otherTyped = other as FindGameByTitleData;
    return games == otherTyped.games;
    
  }
  @override
  int get hashCode => games.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['games'] = games.map((e) => e.toJson()).toList();
    return json;
  }

  const FindGameByTitleData({
    required this.games,
  });
}

@immutable
class FindGameByTitleVariables {
  final String title;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FindGameByTitleVariables.fromJson(Map<String, dynamic> json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindGameByTitleVariables otherTyped = other as FindGameByTitleVariables;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  const FindGameByTitleVariables({
    required this.title,
  });
}

