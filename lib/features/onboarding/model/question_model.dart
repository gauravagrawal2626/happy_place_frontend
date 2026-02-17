/// Onboarding Question Models - Enhanced
/// 
/// Data models matching the backend API response structure
/// Supports: text_variations, sub_options, role_mapping
/// API: GET /api/questions/onboarding

/// Sub-option for expandable/inline options
class SubOption {
  final String id;
  final String text;
  final String vectorText;
  final String? editDisplayText; // Text for preferences/edit screen

  SubOption({
    required this.id,
    required this.text,
    required this.vectorText,
    this.editDisplayText,
  });

  factory SubOption.fromJson(Map<String, dynamic> json) {
    return SubOption(
      id: json['id'] as String,
      text: json['text'] as String,
      vectorText: json['vector_text'] as String? ?? json['text'] as String,
      editDisplayText: json['edit_display_text'] as String?,
    );
  }

  /// Get display text for preferences screen (falls back to text)
  String get displayText => editDisplayText ?? text;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'vector_text': vectorText,
      if (editDisplayText != null) 'edit_display_text': editDisplayText,
    };
  }
}

/// Question option with optional sub-options
class QuestionOption {
  final String id;
  final String text;
  final String vectorText;
  final String? imageUrl;
  final bool isParent;              // Has sub-options
  final List<SubOption>? subOptions; // Child options
  final String? editDisplayText;    // Text for preferences/edit screen

  QuestionOption({
    required this.id,
    required this.text,
    required this.vectorText,
    this.imageUrl,
    this.isParent = false,
    this.subOptions,
    this.editDisplayText,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String,
      text: json['text'] as String,
      vectorText: json['vector_text'] as String? ?? json['text'] as String,
      imageUrl: json['image_url'] as String?,
      isParent: json['is_parent'] as bool? ?? false,
      subOptions: (json['sub_options'] as List<dynamic>?)
          ?.map((sub) => SubOption.fromJson(sub as Map<String, dynamic>))
          .toList(),
      editDisplayText: json['edit_display_text'] as String?,
    );
  }

  /// Get display text for preferences screen (falls back to text)
  String get displayText => editDisplayText ?? text;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'vector_text': vectorText,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isParent) 'is_parent': isParent,
      if (subOptions != null) 'sub_options': subOptions!.map((s) => s.toJson()).toList(),
      if (editDisplayText != null) 'edit_display_text': editDisplayText,
    };
  }
}

/// Text variations based on previous answers or role
class TextVariations {
  final String basedOn;  // "GENDER", "role", etc.
  final Map<String, Map<String, String>> variations;

  TextVariations({
    required this.basedOn,
    required this.variations,
  });

  factory TextVariations.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TextVariations(basedOn: '', variations: {});
    }
    
    final variationsJson = json['variations'] as Map<String, dynamic>? ?? {};
    final Map<String, Map<String, String>> parsedVariations = {};
    
    variationsJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedVariations[key] = value.map((k, v) => MapEntry(k, v.toString()));
      }
    });

    return TextVariations(
      basedOn: json['based_on'] as String? ?? '',
      variations: parsedVariations,
    );
  }

  bool get isEmpty => basedOn.isEmpty;
  bool get isNotEmpty => basedOn.isNotEmpty;

  /// Get variation overrides for a given key
  Map<String, String>? getVariation(String key) => variations[key];
}

/// Matching configuration for role updates and matching logic
class MatchingConfig {
  final bool updatesRole;                    // This question updates user role
  final Map<String, String>? roleMapping;    // option_id -> role
  final int? ageRange;
  final bool partialMatch;
  final bool multiSelect;

  MatchingConfig({
    this.updatesRole = false,
    this.roleMapping,
    this.ageRange,
    this.partialMatch = false,
    this.multiSelect = false,
  });

  factory MatchingConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MatchingConfig();
    
    return MatchingConfig(
      updatesRole: json['updates_role'] as bool? ?? false,
      roleMapping: (json['role_mapping'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      ageRange: json['age_range'] as int?,
      partialMatch: json['partial_match'] as bool? ?? false,
      multiSelect: json['multi_select'] as bool? ?? false,
    );
  }

  /// Get role for a given option ID
  String? getRoleForOption(String optionId) => roleMapping?[optionId];
}

/// UI Configuration for different question types
class UiConfig {
  // SLIDER config
  final int? min;
  final int? max;
  final int? step;
  final int? defaultValue;
  final String? unit;
  
  // MCQ config
  final int? maxSelections;
  final int? columns;
  final bool chipStyle;
  
  // Sub-options config
  final bool expandable;           // Accordion-style expansion (USER_TYPE)
  final String? expandedTitle;     // Title when expanded: "Oh, cool. Tell me more."
  final bool showSubOptionsInline; // Inline sub-options (DIETARY, SMOKING)

  UiConfig({
    this.min,
    this.max,
    this.step,
    this.defaultValue,
    this.unit,
    this.maxSelections,
    this.columns,
    this.chipStyle = false,
    this.expandable = false,
    this.expandedTitle,
    this.showSubOptionsInline = false,
  });

  factory UiConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UiConfig();
    return UiConfig(
      min: json['min'] as int?,
      max: json['max'] as int?,
      step: json['step'] as int?,
      defaultValue: json['default'] as int?,
      unit: json['unit'] as String?,
      maxSelections: json['max_selections'] as int?,
      columns: json['columns'] as int?,
      chipStyle: json['chip_style'] as bool? ?? false,
      expandable: json['expandable'] as bool? ?? false,
      expandedTitle: json['expanded_title'] as String?,
      showSubOptionsInline: json['show_sub_options_inline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (step != null) 'step': step,
      if (defaultValue != null) 'default': defaultValue,
      if (unit != null) 'unit': unit,
      if (maxSelections != null) 'max_selections': maxSelections,
      if (columns != null) 'columns': columns,
      if (chipStyle) 'chip_style': chipStyle,
      if (expandable) 'expandable': expandable,
      if (expandedTitle != null) 'expanded_title': expandedTitle,
      if (showSubOptionsInline) 'show_sub_options_inline': showSubOptionsInline,
    };
  }
}

class Question {
  final String id;
  final String fieldName;         // GENDER, AGE, USER_TYPE, etc.
  final String? tertiaryText;     // Greeting: "Hey, {name}", "Okay, cutie."
  final String primaryText;       // Main question: "What's your gender?"
  final String? secondaryText;    // Help text: "Pick what suits you..."
  final String type;              // TEXT_MCQ, IMAGE_MCQ, SLIDER
  final String questionSet;
  final String category;
  final List<QuestionOption> options;
  final bool isRequired;
  final int order;
  final String? helpText;
  final UiConfig uiConfig;
  final TextVariations? textVariations;   // Dynamic text based on previous answers
  final MatchingConfig? matchingConfig;   // Role mapping and matching logic
  final bool showInPreferences;           // Show in preferences editing screen
  final String? editWidgetText;           // Label for preferences screen (e.g., "Food & Smoking preference")
  final dynamic existingAnswer;           // Pre-populated answer (String, int, or List<String>)

  Question({
    required this.id,
    required this.fieldName,
    this.tertiaryText,
    required this.primaryText,
    this.secondaryText,
    required this.type,
    required this.questionSet,
    required this.category,
    required this.options,
    required this.isRequired,
    required this.order,
    this.helpText,
    required this.uiConfig,
    this.textVariations,
    this.matchingConfig,
    this.showInPreferences = false,
    this.editWidgetText,
    this.existingAnswer,
  });

  /// Check if this is a multi-select question
  bool get isMultiSelect => uiConfig.maxSelections != null && uiConfig.maxSelections! > 1;

  /// Get max selections (defaults to 1 for single select)
  int get maxSelections => uiConfig.maxSelections ?? 1;

  /// Check if this question has sub-options
  bool get hasSubOptions => options.any((opt) => opt.isParent && opt.subOptions != null);

  /// Check if this question updates user role
  bool get updatesRole => matchingConfig?.updatesRole ?? false;

  /// Create a copy with modified text fields (for text_variations)
  Question copyWithTextOverrides({
    String? tertiaryText,
    String? primaryText,
    String? secondaryText,
  }) {
    return Question(
      id: id,
      fieldName: fieldName,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      type: type,
      questionSet: questionSet,
      category: category,
      options: options,
      isRequired: isRequired,
      order: order,
      helpText: helpText,
      uiConfig: uiConfig,
      textVariations: textVariations,
      matchingConfig: matchingConfig,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    final textVariationsJson = json['text_variations'] as Map<String, dynamic>?;
    
    return Question(
      id: json['_id'] as String,
      fieldName: json['field_name'] as String? ?? '',
      tertiaryText: json['tertiary_text'] as String?,
      primaryText: json['primary_text'] as String? ?? json['text'] as String,
      secondaryText: json['secondary_text'] as String?,
      type: json['type'] as String,
      questionSet: json['question_set'] as String? ?? '',
      category: json['category'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((opt) => QuestionOption.fromJson(opt as Map<String, dynamic>))
              .toList() ??
          [],
      isRequired: json['is_required'] as bool? ?? true,
      order: json['order'] as int? ?? 1,
      helpText: json['help_text'] as String?,
      uiConfig: UiConfig.fromJson(json['ui_config'] as Map<String, dynamic>?),
      textVariations: textVariationsJson != null 
          ? TextVariations.fromJson(textVariationsJson) 
          : null,
      matchingConfig: MatchingConfig.fromJson(
          json['matching_config'] as Map<String, dynamic>?),
      showInPreferences: json['show_in_preferences'] as bool? ?? false,
      editWidgetText: json['edit_widget_text'] as String?,
      existingAnswer: json['existing_answer'], // Can be String, int, or List
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'field_name': fieldName,
      'tertiary_text': tertiaryText,
      'primary_text': primaryText,
      'secondary_text': secondaryText,
      'type': type,
      'question_set': questionSet,
      'category': category,
      'options': options.map((opt) => opt.toJson()).toList(),
      'is_required': isRequired,
      'order': order,
      'help_text': helpText,
      'ui_config': uiConfig.toJson(),
    };
  }
}

class OnboardingAnswer {
  final String questionId;
  final dynamic answer; // Can be String, int, List<String>

  OnboardingAnswer({
    required this.questionId,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer': answer,
    };
  }
}

/// Response wrapper for onboarding questions API
class OnboardingQuestionsResponse {
  final List<Question> questions;
  final int totalQuestions;
  final List<String> categories;
  final String userRole;

  OnboardingQuestionsResponse({
    required this.questions,
    required this.totalQuestions,
    required this.categories,
    required this.userRole,
  });

  factory OnboardingQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestionsResponse(
      questions: (json['questions'] as List<dynamic>)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      totalQuestions: json['total_questions'] as int? ?? 0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      userRole: json['user_role'] as String? ?? 'SEEKER',
    );
  }
}
