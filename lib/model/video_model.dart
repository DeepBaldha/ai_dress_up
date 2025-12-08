import '../utils/global_variables.dart';

class VideoModel {
  final String title;
  final String userName; // THIS IS UNIQUE - identifies the video template
  final String thumbnail;
  final String video;
  final String audio;
  final String inputImage;
  final String prompt;
  final String description;
  String apiType;
  final String poloTemplateId;
  final String seaArtApplyId;
  String seaArtTemplateId;
  final String seaArtModelNo;
  final String seaArtVersionNo;
  final List seaArtApplyInput;
  final int creditCharge;
  final String dezgoPrompt;
  final int likes;
  final bool isOneTimeFree;

  VideoModel({
    required this.title,
    required this.userName,
    required this.thumbnail,
    required this.video,
    required this.audio,
    required this.inputImage,
    required this.prompt,
    required this.description,
    required this.apiType,
    required this.poloTemplateId,
    required this.seaArtApplyId,
    required this.seaArtTemplateId,
    required this.seaArtModelNo,
    required this.seaArtVersionNo,
    required this.seaArtApplyInput,
    required this.creditCharge,
    required this.dezgoPrompt,
    required this.likes,
    required this.isOneTimeFree,
  });

  String getUniqueKey() => userName;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      title: json['title']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      video: json['video']?.toString() ?? '',
      audio: json['audio']?.toString() ?? '',
      inputImage: json['inputImage']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      apiType: json['apiType']?.toString() ?? '',
      poloTemplateId: json['poloTemplateId']?.toString() ?? '',
      seaArtApplyId: json['seaArtApplyId']?.toString() ?? '',
      seaArtTemplateId: json['seaArtTemplateId']?.toString() ?? '',
      seaArtModelNo: json['seaArtModelNo']?.toString() ?? '',
      seaArtVersionNo: json['seaArtVersionNo']?.toString() ?? '',
      creditCharge: json['creditCharge'] is int
          ? json['creditCharge']
          : int.tryParse(
        json['creditCharge']?.toString() ??
            '${GlobalVariables.videoCredit}',
      ) ??
          GlobalVariables.videoCredit,
      seaArtApplyInput: json['seaArtApplyInput'] is List
          ? json['seaArtApplyInput']
          : [],
      dezgoPrompt: json['dezgoPrompt']?.toString() ?? '',
      likes: json['likes'] is int
          ? json['likes']
          : int.tryParse(json['likes']?.toString() ?? '0') ?? 0,
      isOneTimeFree: json['isOneTimeFree']?.toString().toLowerCase() == "true",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'userName': userName,
      'thumbnail': thumbnail,
      'video': video,
      'audio': audio,
      'inputImage': inputImage,
      'prompt': prompt,
      'description': description,
      'apiType': apiType,
      'poloTemplateId': poloTemplateId,
      'seaArtApplyId': seaArtApplyId,
      'seaArtTemplateId': seaArtTemplateId,
      'seaArtModelNo': seaArtModelNo,
      'seaArtVersionNo': seaArtVersionNo,
      'seaArtApplyInput': seaArtApplyInput,
      'creditCharge': creditCharge,
      'dezgoPrompt': dezgoPrompt,
      'likes': likes,
      'isOneTimeFree': isOneTimeFree,
    };
  }

  VideoModel copyWith({
    String? title,
    String? userName,
    String? thumbnail,
    String? video,
    String? audio,
    String? inputImage,
    String? prompt,
    String? description,
    String? apiType,
    String? poloTemplateId,
    String? seaArtApplyId,
    String? seaArtTemplateId,
    String? seaArtModelNo,
    String? seaArtVersionNo,
    List? seaArtApplyInput,
    int? creditCharge,
    String? dezgoPrompt,
    int? likes,
    bool? isOneTimeFree,
  }) {
    return VideoModel(
      title: title ?? this.title,
      userName: userName ?? this.userName,
      thumbnail: thumbnail ?? this.thumbnail,
      video: video ?? this.video,
      audio: audio ?? this.audio,
      inputImage: inputImage ?? this.inputImage,
      prompt: prompt ?? this.prompt,
      description: description ?? this.description,
      apiType: apiType ?? this.apiType,
      poloTemplateId: poloTemplateId ?? this.poloTemplateId,
      seaArtApplyId: seaArtApplyId ?? this.seaArtApplyId,
      seaArtTemplateId: seaArtTemplateId ?? this.seaArtTemplateId,
      seaArtModelNo: seaArtModelNo ?? this.seaArtModelNo,
      seaArtVersionNo: seaArtVersionNo ?? this.seaArtVersionNo,
      seaArtApplyInput: seaArtApplyInput ?? this.seaArtApplyInput,
      creditCharge: creditCharge ?? this.creditCharge,
      dezgoPrompt: dezgoPrompt ?? this.dezgoPrompt,
      likes: likes ?? this.likes,
      isOneTimeFree: isOneTimeFree ?? this.isOneTimeFree,
    );
  }
}