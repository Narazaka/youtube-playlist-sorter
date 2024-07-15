import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:googleapis/youtube/v3.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Playlist Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PlaylistPage(),
    );
  }
}

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  String _playlistId = '';
  List<PlaylistItem> _playlistItems = [];
  bool _isLoading = false;
  final TextEditingController _playlistIdController = TextEditingController();

  Future<void> _fetchPlaylistItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final playlistId =
          ApiService.extractPlaylistId(_playlistIdController.text);
      final items = await ApiService.fetchPlaylistItems(context, playlistId);
      setState(() {
        _playlistId = playlistId;
        _playlistItems = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (_) => AlertDialog(content: Text(error.toString())));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reorderPlaylist(int oldIndex, int newIndex) async {
    var newPosition =
        newIndex == 0 ? 0 : _playlistItems[newIndex - 1].snippet!.position! + 1;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    PlaylistItem item = _playlistItems[oldIndex];
    setState(() {
      item = _playlistItems.removeAt(oldIndex);
      _playlistItems.insert(newIndex, item);
    });
    try {
      await ApiService.updatePlaylistItem(context, _playlistId, item.id!,
          item.snippet!.resourceId!.videoId!, newPosition);
    } catch (error) {
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (_) => AlertDialog(content: Text(error.toString())));
      setState(() {
        item = _playlistItems.removeAt(newIndex);
        _playlistItems.insert(oldIndex, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Playlist Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _playlistIdController,
              decoration: const InputDecoration(
                labelText: 'Enter Playlist ID or URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _fetchPlaylistItems,
            child: const Text('Fetch Playlist Items'),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ReorderableListView(
                    onReorder: _reorderPlaylist,
                    children: _playlistItems.map((item) {
                      return ListTile(
                        key: Key(item.contentDetails!.videoId!),
                        leading: Image.network(
                            item.snippet!.thumbnails!.default_!.url!),
                        title: Text(item.snippet!.title!),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
