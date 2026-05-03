import 'package:flutter/foundation.dart';

import '../models/avatar_config.dart';

class AvatarProvider extends ChangeNotifier {
  AvatarConfig _config = AvatarConfig(
    skin: 'skin_1',
    hair: 'hair_1',
    outfit: 'outfit_1',
  );
  String _mood = 'happy';
  String _selectedAvatarAsset = 'assets/avatar/baby_boy/baby_batman.png';

  AvatarConfig get config => _config;
  String get mood => _mood;
  String get selectedAvatarAsset => _selectedAvatarAsset;

  void updateAvatar(AvatarConfig newConfig) {
    _config = AvatarConfig(
      skin: newConfig.skin,
      hair: newConfig.hair,
      outfit: newConfig.outfit,
    );
    notifyListeners();
  }

  void updateMood(String newMood) {
    if (newMood != 'happy' && newMood != 'calm' && newMood != 'stressed') {
      return;
    }
    _mood = newMood;
    notifyListeners();
  }

  void updateAvatarAndMood({
    required AvatarConfig newConfig,
    required String newMood,
  }) {
    _config = AvatarConfig(
      skin: newConfig.skin,
      hair: newConfig.hair,
      outfit: newConfig.outfit,
    );
    _mood = (newMood == 'happy' || newMood == 'calm' || newMood == 'stressed')
        ? newMood
        : 'happy';
    notifyListeners();
  }

  void selectUploadedAvatar(String assetPath) {
    _selectedAvatarAsset = assetPath;
    notifyListeners();
  }
}
