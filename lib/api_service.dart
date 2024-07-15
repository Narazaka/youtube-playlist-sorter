import 'package:googleapis/youtube/v3.dart';
import 'package:flutter/material.dart';
import 'auth.dart';

class ApiService {
  static Future<YouTubeApi> _getYouTubeApi(BuildContext context) async {
    final authClient = await Auth.authenticate(context);
    return YouTubeApi(authClient);
  }

  static Future<List<PlaylistItem>> fetchPlaylistItems(
      BuildContext context, String playlistId) async {
    final youTubeApi = await _getYouTubeApi(context);
    List<PlaylistItem> allItems = [];
    String? nextPageToken;

    do {
      final response = await youTubeApi.playlistItems.list(
        ['snippet', 'contentDetails'],
        playlistId: playlistId,
        maxResults: 50,
        pageToken: nextPageToken,
      );
      allItems.addAll(response.items ?? []);
      nextPageToken = response.nextPageToken;
    } while (nextPageToken != null);

    allItems.sort((a, b) => a.snippet!.position! - b.snippet!.position!);
    return allItems;
  }

  static Future<void> updatePlaylistItem(
      BuildContext context,
      String playlistId,
      String playlistItemId,
      String videoId,
      int position) async {
    final youTubeApi = await _getYouTubeApi(context);
    final playlistItem = PlaylistItem(
      id: playlistItemId,
      snippet: PlaylistItemSnippet(
          position: position,
          playlistId: playlistId,
          resourceId: ResourceId(kind: 'youtube#video', videoId: videoId)),
    );
    await youTubeApi.playlistItems.update(playlistItem, ['snippet']);
    print("updated $playlistItemId video=$videoId pos=$position");
  }

  static String extractPlaylistId(String playlistIdOrUrl) {
    final uri = Uri.tryParse(playlistIdOrUrl);
    if (uri != null && uri.queryParameters['list'] != null) {
      return uri.queryParameters['list']!;
    }
    return playlistIdOrUrl;
  }
}
