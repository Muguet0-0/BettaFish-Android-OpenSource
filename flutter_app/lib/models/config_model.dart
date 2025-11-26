/// 配置项模型
class ConfigItem {
  final String key;
  final String label;
  final String type;
  final String value;
  final String? description;
  
  ConfigItem({
    required this.key,
    required this.label,
    required this.type,
    this.value = '',
    this.description,
  });
  
  ConfigItem copyWith({
    String? key,
    String? label,
    String? type,
    String? value,
    String? description,
  }) {
    return ConfigItem(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      value: value ?? this.value,
      description: description ?? this.description,
    );
  }
  
  bool get isPassword => type == 'password';
  bool get isNumber => type == 'number';
}

/// 配置组模型
class ConfigGroup {
  final String title;
  final List<ConfigItem> items;
  
  ConfigGroup({
    required this.title,
    required this.items,
  });
  
  ConfigGroup copyWith({
    String? title,
    List<ConfigItem>? items,
  }) {
    return ConfigGroup(
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }
}

/// 应用配置模型
class AppConfigModel {
  final Map<String, String> values;
  final bool isLoaded;
  final bool isSaving;
  final String? error;
  
  AppConfigModel({
    Map<String, String>? values,
    this.isLoaded = false,
    this.isSaving = false,
    this.error,
  }) : values = values ?? {};
  
  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final values = <String, String>{};
    json.forEach((key, value) {
      values[key] = value?.toString() ?? '';
    });
    return AppConfigModel(
      values: values,
      isLoaded: true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(values);
  }
  
  String getValue(String key) {
    return values[key] ?? '';
  }
  
  AppConfigModel copyWith({
    Map<String, String>? values,
    bool? isLoaded,
    bool? isSaving,
    String? error,
  }) {
    return AppConfigModel(
      values: values ?? this.values,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
  
  AppConfigModel updateValue(String key, String value) {
    final newValues = Map<String, String>.from(values);
    newValues[key] = value;
    return copyWith(values: newValues);
  }
}

