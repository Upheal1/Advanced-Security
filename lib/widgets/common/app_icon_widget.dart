import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Widget to display actual app icons with fallback to themed icons
class AppIconWidget extends StatefulWidget {
  final String packageName;
  final String appName;
  final double size;

  const AppIconWidget({
    super.key,
    required this.packageName,
    required this.appName,
    this.size = 40,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  static const MethodChannel _platform = MethodChannel('com.appguard.native_calls');
  static final Map<String, Uint8List?> _iconCache = {};

  Uint8List? _iconBytes;

  @override
  void initState() {
    super.initState();
    // Try cache first
    _iconBytes = _iconCache[widget.packageName];
    if (_iconBytes == null) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    try {
      final bytes = await _platform.invokeMethod('getAppIcon', {
        'packageName': widget.packageName,
      });
      if (!mounted) return;
      if (bytes != null) {
        setState(() {
          _iconBytes = bytes as Uint8List;
          _iconCache[widget.packageName] = _iconBytes;
        });
      }
    } catch (e) {
      // Fallback to placeholder icon
      debugPrint('Icon load failed for ${widget.packageName}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getAppColor(widget.appName).withOpacity(0.3);
    final bgColor = _getAppColor(widget.appName).withOpacity(0.1);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.18),
        child: _iconBytes != null
            ? Image.memory(
                _iconBytes!,
                fit: BoxFit.cover,
              )
            : Icon(
                _getAppIcon(widget.appName),
                size: widget.size * 0.6,
                color: _getAppColor(widget.appName),
              ),
      ),
    );
  }

  Color _getAppColor(String appName) {
    if (appName.contains('Instagram')) return Colors.blueAccent;
    if (appName.contains('YouTube')) return Colors.red;
    if (appName.contains('Chrome')) return Colors.orange;
    if (appName.contains('Discord')) return Colors.purple;
    if (appName.contains('Spotify')) return Colors.green;
    if (appName.contains('TikTok')) return Colors.black;
    if (appName.contains('Facebook')) return Colors.blue;
    if (appName.contains('Twitter')) return Colors.lightBlue;
    if (appName.contains('Snapchat')) return Colors.yellow;
    if (appName.contains('WhatsApp')) return Colors.green;
    if (appName.contains('Telegram')) return Colors.blue;
    if (appName.contains('Netflix')) return Colors.red;
    if (appName.contains('Gmail')) return Colors.red;
    if (appName.contains('Maps')) return Colors.green;
    if (appName.contains('Photos')) return Colors.blue;
    if (appName.contains('Calendar')) return Colors.blue;
    if (appName.contains('Drive')) return Colors.blue;
    if (appName.contains('Zoom')) return Colors.blue;
    if (appName.contains('Slack')) return Colors.purple;
    if (appName.contains('Uber')) return Colors.black;
    if (appName.contains('Airbnb')) return Colors.red;
    if (appName.contains('Pinterest')) return Colors.red;
    if (appName.contains('Reddit')) return Colors.orange;
    if (appName.contains('LinkedIn')) return Colors.blue;
    if (appName.contains('GitHub')) return Colors.black;
    if (appName.contains('Medium')) return Colors.black;
    if (appName.contains('Quora')) return Colors.red;
    if (appName.contains('Tumblr')) return Colors.blue;
    if (appName.contains('Flickr')) return Colors.pink;
    if (appName.contains('VSCO')) return Colors.black;
    if (appName.contains('Lightroom')) return Colors.purple;
    if (appName.contains('Snapseed')) return Colors.blue;
    if (appName.contains('Canva')) return Colors.blue;
    if (appName.contains('Adobe')) return Colors.red;
    if (appName.contains('Kindle')) return Colors.orange;
    if (appName.contains('Audible')) return Colors.orange;
    if (appName.contains('Podcasts')) return Colors.purple;
    if (appName.contains('SoundCloud')) return Colors.orange;
    if (appName.contains('Pandora')) return Colors.pink;
    if (appName.contains('iHeartRadio')) return Colors.red;
    if (appName.contains('Fitness')) return Colors.green;
    if (appName.contains('Strava')) return Colors.orange;
    if (appName.contains('Nike')) return Colors.black;
    if (appName.contains('Stack')) return Colors.orange;
    if (appName.contains('Teams')) return Colors.blue;
    if (appName.contains('Skype')) return Colors.blue;
    if (appName.contains('Trello')) return Colors.blue;
    if (appName.contains('Notion')) return Colors.black;
    if (appName.contains('Evernote')) return Colors.green;
    if (appName.contains('Keep')) return Colors.yellow;
    if (appName.contains('Duo')) return Colors.blue;
    if (appName.contains('Messages')) return Colors.green;
    if (appName.contains('Firefox')) return Colors.orange;
    if (appName.contains('Opera')) return Colors.red;
    if (appName.contains('Edge')) return Colors.blue;
    if (appName.contains('Samsung')) return Colors.blue;
    if (appName.contains('Books')) return Colors.orange;
    if (appName.contains('Meet')) return Colors.green;
    if (appName.contains('Translate')) return Colors.blue;
    if (appName.contains('Docs')) return Colors.blue;
    if (appName.contains('Excel')) return Colors.green;
    if (appName.contains('Word')) return Colors.blue;
    if (appName.contains('PowerPoint')) return Colors.orange;
    if (appName.contains('DoorDash')) return Colors.red;
    if (appName.contains('Grubhub')) return Colors.orange;
    if (appName.contains('Booking')) return Colors.blue;
    if (appName.contains('Layout')) return Colors.purple;
    if (appName.contains('Boomerang')) return Colors.blue;
    if (appName.contains('Hyperlapse')) return Colors.purple;
    
    return Colors.teal;
  }

  IconData _getAppIcon(String appName) {
    final lowerName = appName.toLowerCase();
    
    if (lowerName.contains('tiktok')) return LucideIcons.music;
    if (lowerName.contains('instagram')) return LucideIcons.camera;
    if (lowerName.contains('youtube')) return LucideIcons.play;
    if (lowerName.contains('facebook')) return LucideIcons.facebook;
    if (lowerName.contains('twitter')) return LucideIcons.twitter;
    if (lowerName.contains('snapchat')) return LucideIcons.camera;
    if (lowerName.contains('whatsapp')) return LucideIcons.messageCircle;
    if (lowerName.contains('telegram')) return LucideIcons.send;
    if (lowerName.contains('discord')) return LucideIcons.messageSquare;
    if (lowerName.contains('spotify')) return LucideIcons.music;
    if (lowerName.contains('netflix')) return LucideIcons.tv;
    if (lowerName.contains('chrome')) return LucideIcons.globe;
    if (lowerName.contains('gmail')) return LucideIcons.mail;
    if (lowerName.contains('maps')) return LucideIcons.mapPin;
    if (lowerName.contains('photos')) return LucideIcons.image;
    if (lowerName.contains('calendar')) return LucideIcons.calendar;
    if (lowerName.contains('drive')) return LucideIcons.folder;
    if (lowerName.contains('zoom')) return LucideIcons.video;
    if (lowerName.contains('slack')) return LucideIcons.messageSquare;
    if (lowerName.contains('uber')) return LucideIcons.car;
    if (lowerName.contains('airbnb')) return LucideIcons.home;
    if (lowerName.contains('pinterest')) return LucideIcons.pin;
    if (lowerName.contains('reddit')) return LucideIcons.messageCircle;
    if (lowerName.contains('linkedin')) return LucideIcons.linkedin;
    if (lowerName.contains('github')) return LucideIcons.github;
    if (lowerName.contains('medium')) return LucideIcons.bookOpen;
    if (lowerName.contains('quora')) return LucideIcons.helpCircle;
    if (lowerName.contains('tumblr')) return LucideIcons.type;
    if (lowerName.contains('flickr')) return LucideIcons.image;
    if (lowerName.contains('vsco')) return LucideIcons.camera;
    if (lowerName.contains('lightroom')) return LucideIcons.sun;
    if (lowerName.contains('snapseed')) return LucideIcons.sliders;
    if (lowerName.contains('canva')) return LucideIcons.palette;
    if (lowerName.contains('adobe')) return LucideIcons.penTool;
    if (lowerName.contains('kindle')) return LucideIcons.book;
    if (lowerName.contains('audible')) return LucideIcons.headphones;
    if (lowerName.contains('podcasts')) return LucideIcons.mic;
    if (lowerName.contains('soundcloud')) return LucideIcons.music;
    if (lowerName.contains('pandora')) return LucideIcons.radio;
    if (lowerName.contains('iheartradio')) return LucideIcons.radio;
    if (lowerName.contains('fitness')) return LucideIcons.activity;
    if (lowerName.contains('strava')) return LucideIcons.trendingUp;
    if (lowerName.contains('nike')) return LucideIcons.footprints;
    if (lowerName.contains('stack')) return LucideIcons.layers;
    if (lowerName.contains('teams')) return LucideIcons.users;
    if (lowerName.contains('skype')) return LucideIcons.phoneCall;
    if (lowerName.contains('trello')) return LucideIcons.trello;
    if (lowerName.contains('notion')) return LucideIcons.fileText;
    if (lowerName.contains('evernote')) return LucideIcons.bookOpen;
    if (lowerName.contains('keep')) return LucideIcons.stickyNote;
    if (lowerName.contains('duo')) return LucideIcons.video;
    if (lowerName.contains('messages')) return LucideIcons.messageSquare;
    if (lowerName.contains('firefox')) return LucideIcons.globe;
    if (lowerName.contains('opera')) return LucideIcons.globe;
    if (lowerName.contains('edge')) return LucideIcons.globe;
    if (lowerName.contains('samsung')) return LucideIcons.smartphone;
    if (lowerName.contains('books')) return LucideIcons.book;
    if (lowerName.contains('meet')) return LucideIcons.video;
    if (lowerName.contains('translate')) return LucideIcons.languages;
    if (lowerName.contains('docs')) return LucideIcons.fileText;
    if (lowerName.contains('excel')) return LucideIcons.sheet;
    if (lowerName.contains('word')) return LucideIcons.fileText;
    if (lowerName.contains('powerpoint')) return LucideIcons.presentation;
    if (lowerName.contains('doordash')) return LucideIcons.utensils;
    if (lowerName.contains('grubhub')) return LucideIcons.utensils;
    if (lowerName.contains('booking')) return LucideIcons.bed;
    if (lowerName.contains('layout')) return LucideIcons.layout;
    if (lowerName.contains('boomerang')) return LucideIcons.repeat;
    if (lowerName.contains('hyperlapse')) return LucideIcons.clock;
    if (lowerName.contains('game')) return LucideIcons.gamepad2;
    if (lowerName.contains('browser')) return LucideIcons.globe;
    if (lowerName.contains('camera')) return LucideIcons.camera;
    if (lowerName.contains('clock')) return LucideIcons.clock;
    if (lowerName.contains('weather')) return LucideIcons.cloudRain;
    if (lowerName.contains('news')) return LucideIcons.newspaper;
    if (lowerName.contains('shopping')) return LucideIcons.shoppingCart;
    if (lowerName.contains('music')) return LucideIcons.music;
    if (lowerName.contains('video')) return LucideIcons.video;
    if (lowerName.contains('phone')) return LucideIcons.phone;
    if (lowerName.contains('settings')) return LucideIcons.settings;
    if (lowerName.contains('files')) return LucideIcons.folder;
    if (lowerName.contains('gallery')) return LucideIcons.image;
    if (lowerName.contains('calculator')) return LucideIcons.calculator;
    if (lowerName.contains('notes')) return LucideIcons.stickyNote;
    if (lowerName.contains('contacts')) return LucideIcons.users;
    
    return LucideIcons.smartphone;
  }
}
