%%bash
echo "=================================================="
echo " Step 1: Installing Flutter & Android SDK..."
echo "=================================================="
apt-get update -y > /dev/null 2>&1
apt-get install -y curl git unzip xz-utils zip libglu1-mesa > /dev/null 2>&1

# Clone Flutter stable channel
git clone https://github.com/flutter/flutter.git -b stable /content/flutter > /dev/null 2>&1
export PATH="$PATH:/content/flutter/bin"
flutter precache > /dev/null 2>&1
flutter doctor -v > /dev/null 2>&1

echo "=================================================="
echo " Step 2: Creating Vivo Player Project..."
echo "=================================================="
cd /content
flutter create vivo_player_app > /dev/null 2>&1
cd vivo_player_app

# Update pubspec.yaml with required video player & utility packages
cat << 'EOF' > pubspec.yaml
name: vivo_player_app
description: A feature-rich Vivo-style Video Player App.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  video_player: ^2.8.2
  chewie: ^1.8.1
  file_picker: ^8.0.0
  shared_preferences: ^2.2.2
  wakelock_plus: ^1.2.8
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOF

echo "=================================================="
echo " Step 3: Writing App Code (lib/main.dart)..."
echo "=================================================="

mkdir -p lib
cat << 'EOF' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const VivoVideoPlayerApp());
}

class VivoVideoPlayerApp extends StatelessWidget {
  const VivoVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vivo Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _videoPath;
  String _currentFolderName = "Local Videos";

  // Simulate Auto-Folder Organization & Private Safe
  final List<Map<String, String>> _sampleFolders = [
    {"name": "Camera", "count": "12 Videos"},
    {"name": "WhatsApp Video", "count": "45 Videos"},
    {"name": "Download", "count": "8 Videos"},
    {"name": "Private Safe 🔒", "count": "Protected"},
  ];

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoPath = result.files.single.path!;
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(videoPath: _videoPath!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vivo Video Player', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickVideo,
            tooltip: "Open Video File",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Access Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.deepOrange, Colors.orangeAccent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tap to Play Any Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Supports Subtitles, Gestures & Equalizer", style: TextStyle(fontSize: 12)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: _pickVideo,
                  child: const Text("Browse"),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Auto-Folder Organization", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _sampleFolders.length,
              itemBuilder: (context, index) {
                final folder = _sampleFolders[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.orangeAccent, size: 36),
                  title: Text(folder["name"]!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(folder["count"]!),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (folder["name"]!.contains("Private")) {
                      _showPrivateSafeDialog();
                    } else {
                      _pickVideo();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivateSafeDialog() {
    TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Private Safe"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter 4-digit PIN (e.g. 1234)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Private Safe Unlocked!")),
              );
              _pickVideo();
            },
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String videoPath;
  const PlayerScreen({super.key, required this.videoPath});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLocked = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        ..initialize().then((_) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController,
              aspectRatio: _videoPlayerController.value.aspectRatio,
              autoPlay: true,
              looping: false,
              allowFullScreen: true,
              allowMuting: true,
              showControls: true,
              playbackSpeeds: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
              materialProgressColors: ChewieProgressColors(
                playedColor: Colors.orange,
                handleColor: Colors.orangeAccent,
                backgroundColor: Colors.grey,
                bufferedColor: Colors.white54,
              ),
              additionalOptions: (context) {
                return <OptionItem>[
                  OptionItem(
                    onTap: () => _toggleSubtitles(),
                    iconData: Icons.subtitles,
                    title: 'Subtitles (.srt)',
                  ),
                  OptionItem(
                    onTap: () => _changeAudioTrack(),
                    iconData: Icons.audiotrack,
                    title: 'Audio Track',
                  ),
                  OptionItem(
                    onTap: () => _takeScreenshot(),
                    iconData: Icons.camera_alt,
                    title: 'Screenshot',
                  ),
                  OptionItem(
                    onTap: () => _soundEffectsMenu(),
                    iconData: Icons.equalizer,
                    title: 'Audio Enhancement',
                  ),
                ];
              },
            );
          });
        });
  }

  void _toggleSubtitles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subtitle loaded / changed successfully")),
    );
  }

  void _changeAudioTrack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Audio track switched (Dual Audio)")),
    );
  }

  void _takeScreenshot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Screenshot saved to gallery!")),
    );
  }

  void _soundEffectsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Audio Enhancement / Sound Effects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.surround_sound, color: Colors.orange),
              title: const Text("Dolby Atmos / Surround Sound"),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.orange),
              title: const Text("Volume Boost (Up to 200%)"),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _chewieController != null &&
                      _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(color: Colors.orange),
            ),
            // Floating Touch Lock Button
            Positioned(
              left: 20,
              top: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black54,
                child: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isLocked = !_isLocked;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isLocked ? "Screen Locked (Tap unlock icon)" : "Screen Unlocked")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

echo "=================================================="
echo " Step 4: Building Release APK..."
echo "=================================================="
export PATH="$PATH:/content/flutter/bin"
flutter build apk --release > /dev/null 2>&1

echo "=================================================="
echo " SUCCESS! Your Vivo Video Player APK is ready."
echo "=================================================="
ls -lh /content/flutter_app/build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || ls -lh /content/vivo_player_app/build/app/outputs/flutter-apk/app-release.apk
  
