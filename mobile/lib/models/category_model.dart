class CategoryModel {
  final int id;
  final String name;
  final String color;

  CategoryModel({required this.id, required this.name, required this.color});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id:    json['id'],
    name:  json['name'],
    color: json['color'] ?? '#6366f1',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
}
