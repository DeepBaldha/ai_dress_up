class LanguageModel {
  final String language;
  final String flagImage;
  final String languageCode;
  final String selectedIcon;
  final String unSelectedIcon;

  LanguageModel(
      {required this.language,
        required this.languageCode,
        required this.flagImage,
        required this.selectedIcon,
        required this.unSelectedIcon});
}