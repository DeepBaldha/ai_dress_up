import 'dart:ui';

import 'package:flutter/material.dart';

import '../model/language_model.dart';

const defaultImagePath = 'asset/images/';
const privacyPolicy = 'https://docs.google.com/document/u/0/d/e/2PACX-1vTM2N0vI47KIf0sLSL8f-CnW-RlYOA8VpTFeKe9EWeTcS0WivhyvAJ3DpasahGJJPFrR4uD4B9CGtnt/pub?pli=1';
const termOfUse = 'https://www.google.com';

const buttonColor = Color(0xff00aaff);

const flagPath = 'asset/images/languages/';

// TODO: when submit
const weeklyIdentifier = 'weeklysubscription:weeklysubscription';
const yearlyIdentifier = 'yearlysubscription:yearlysubscription';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


const Map<String, List<Map<String, String>>> outfitCategories = {
  "Trending": [
    {
      "url": 'https://imagizer.imageshack.com/img924/3168/cOdQsK.png',
      "name": "Modern Chic",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/6521/x3JSsS.png',
      "name": "Urban Style",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/230/6Vdszl.png',
      "name": "Classy Fit",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/7382/LgMziW.png',
      "name": "Royal Look",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/552/j3U0WS.png',
      "name": "Night Wear",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/3681/yn8tGZ.png',
      "name": "Trendy Wear",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/7979/SYV1CE.png',
      "name": "Classic Glam",
    },
    {
      "url": 'https://imagizer.imageshack.com/img923/8927/q3317x.png',
      "name": "Soft Beauty",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/8586/HuDW71.png',
      "name": "Fresh Style",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/5337/hvUl6W.png',
      "name": "Elite Fashion",
    },
    {
      "url": 'https://imagizer.imageshack.com/img923/2176/CMs1SL.png',
      "name": "Grace Mode",
    },
  ],

  "Party Wear": [
    {
      "url": 'https://imagizer.imageshack.com/img924/3168/cOdQsK.png',
      "name": "Party Queen",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/6521/x3JSsS.png',
      "name": "Glow Dress",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/230/6Vdszl.png',
      "name": "Night Charm",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/7382/LgMziW.png',
      "name": "Bright Style",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/552/j3U0WS.png',
      "name": "Disco Look",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/3681/yn8tGZ.png',
      "name": "Shine Glam",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/7979/SYV1CE.png',
      "name": "Glow Queen",
    },
    {
      "url": 'https://imagizer.imageshack.com/img923/8927/q3317x.png',
      "name": "Soft Glow",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/8586/HuDW71.png',
      "name": "Golden Night",
    },
  ],

  "Wedding": [
    {
      "url": 'https://imagizer.imageshack.com/img924/3168/cOdQsK.png',
      "name": "Bride Look",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/6521/x3JSsS.png',
      "name": "Royal Bride",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/230/6Vdszl.png',
      "name": "Wedding Grace",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/7382/LgMziW.png',
      "name": "Bridal Charm",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/552/j3U0WS.png',
      "name": "Festive Glam",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/3681/yn8tGZ.png',
      "name": "Ceremony Fit",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/7979/SYV1CE.png',
      "name": "Bridal Glow",
    },
    {
      "url": 'https://imagizer.imageshack.com/img923/8927/q3317x.png',
      "name": "Soft Bride",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/8586/HuDW71.png',
      "name": "Pure Royal",
    },
  ],

  "Casual": [
    {
      "url": 'https://imagizer.imageshack.com/img924/8586/HuDW71.png',
      "name": "Daily Fit",
    },
    {
      "url": 'https://imagizer.imageshack.com/img923/8927/q3317x.png',
      "name": "Casual Street",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/7979/SYV1CE.png',
      "name": "Simple Wear",
    },
    {
      "url": 'https://imagizer.imageshack.com/img922/3681/yn8tGZ.png',
      "name": "Chill Mode",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/552/j3U0WS.png',
      "name": "Basic Look",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/7382/LgMziW.png',
      "name": "Everyday Style",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/230/6Vdszl.png',
      "name": "Relax Fit",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/6521/x3JSsS.png',
      "name": "Easy Wear",
    },
    {
      "url": 'https://imagizer.imageshack.com/img924/3168/cOdQsK.png',
      "name": "Cool Outfit",
    },
  ],
};

List<LanguageModel> languagesList = [
  LanguageModel(
    language: 'English (Default)',
    selectedIcon: '${defaultImagePath}english.png',
    unSelectedIcon: '${defaultImagePath}p_english.png',
    languageCode: 'en',
    flagImage: '${flagPath}english.png',
  ),
  LanguageModel(
    language: 'Spanish (español)',
    selectedIcon: '${defaultImagePath}spanish.png',
    unSelectedIcon: '${defaultImagePath}p_spanish.png',
    languageCode: 'es',
    flagImage: '${flagPath}spanish.png',
  ),
  LanguageModel(
    language: 'German (Deutsch)',
    selectedIcon: '${defaultImagePath}german.png',
    unSelectedIcon: '${defaultImagePath}p_german.png',
    languageCode: 'de',
    flagImage: '${flagPath}german.png',
  ),
  LanguageModel(
    language: 'French (Français)',
    selectedIcon: '${defaultImagePath}french.png',
    unSelectedIcon: '${defaultImagePath}p_french.png',
    languageCode: 'fr',
    flagImage: '${flagPath}french.png',
  ),
  LanguageModel(
    language: 'Arabic (العربية)',
    selectedIcon: '${defaultImagePath}arabic.png',
    unSelectedIcon: '${defaultImagePath}p_arabic.png',
    languageCode: 'ar',
    flagImage: '${flagPath}arabic.png',
  ),
  LanguageModel(
    language: 'Russian (Русский)',
    selectedIcon: '${defaultImagePath}russian.png',
    unSelectedIcon: '${defaultImagePath}p_russian.png',
    languageCode: 'ru',
    flagImage: '${flagPath}russian.png',
  ),
  LanguageModel(
    language: 'Hindi (हिन्दी)',
    selectedIcon: '${defaultImagePath}hindi.png',
    unSelectedIcon: '${defaultImagePath}p_hindi.png',
    languageCode: 'hi',
    flagImage: '${flagPath}hindi.png',
  ),
  LanguageModel(
    language: 'Portuguese (Português)',
    selectedIcon: '${defaultImagePath}portuguese.png',
    unSelectedIcon: '${defaultImagePath}p_portuguese.png',
    languageCode: 'pt',
    flagImage: '${flagPath}portuguese.png',
  ),
  LanguageModel(
    language: 'Japanese (日本語)',
    selectedIcon: '${defaultImagePath}japanese.png',
    unSelectedIcon: '${defaultImagePath}p_japanese.png',
    languageCode: 'ja',
    flagImage: '${flagPath}japanese.png',
  ),
  LanguageModel(
    language: 'Korean (한국어)',
    selectedIcon: '${defaultImagePath}korean.png',
    unSelectedIcon: '${defaultImagePath}p_korean.png',
    languageCode: 'ko',
    flagImage: '${flagPath}korean.png',
  ),
  LanguageModel(
    language: 'Chinese (中文)',
    selectedIcon: '${defaultImagePath}chinese.png',
    unSelectedIcon: '${defaultImagePath}p_chinese.png',
    languageCode: 'zh',
    flagImage: '${flagPath}chinese.png',
  ),
  LanguageModel(
    language: 'Turkish (Türkçe)',
    selectedIcon: '${defaultImagePath}turkish.png',
    unSelectedIcon: '${defaultImagePath}p_turkish.png',
    languageCode: 'tr',
    flagImage: '${flagPath}turkish.png',
  ),
  LanguageModel(
    language: 'Dutch (Nederlands)',
    selectedIcon: '${defaultImagePath}dutch.png',
    unSelectedIcon: '${defaultImagePath}p_dutch.png',
    languageCode: 'nl',
    flagImage: '${flagPath}dutch.png',
  ),
  LanguageModel(
    language: 'Vietnamese (Tiếng Việt)',
    selectedIcon: '${defaultImagePath}vietnamese.png',
    unSelectedIcon: '${defaultImagePath}p_vietnamese.png',
    languageCode: 'vi',
    flagImage: '${flagPath}vietnamese.png',
  ),
  LanguageModel(
    language: 'Indonesian (Bahasa Indonesia)',
    selectedIcon: '${defaultImagePath}indonesian.png',
    unSelectedIcon: '${defaultImagePath}p_indonesian.png',
    languageCode: 'in',
    flagImage: '${flagPath}indonesian.png',
  ),
  LanguageModel(
    language: 'Thai (Türkçe)',
    selectedIcon: '${defaultImagePath}thai.png',
    unSelectedIcon: '${defaultImagePath}p_thai.png',
    languageCode: 'th',
    flagImage: '${flagPath}thai.png',
  ),
  LanguageModel(
    language: 'Malay (Bahasa Melayu)',
    selectedIcon: '${defaultImagePath}malaysian.png',
    unSelectedIcon: '${defaultImagePath}p_malaysian.png',
    languageCode: 'ms',
    flagImage: '${flagPath}malaysian.png',
  ),
  LanguageModel(
    language: 'Punjabi (ਪੰਜਾਬੀ)',
    selectedIcon: '${defaultImagePath}punjabi.png',
    unSelectedIcon: '${defaultImagePath}p_punjabi.png',
    languageCode: 'pa',
    flagImage: '${flagPath}punjabi.png',
  ),
];