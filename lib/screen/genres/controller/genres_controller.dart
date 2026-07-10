import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';

class GenresController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxList genres = [].obs;
  final RxList stories = [].obs;
  final RxInt selectedIndex = 0.obs;
  final RxString selectedSlug = ''.obs;

  int _page = 1;
  static const _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
    isLoading.value = true;
    final res = await ApiService.getGenres();
    isLoading.value = false;
    if (res['success']) {
      genres.value = res['data'] is List ? res['data'] : [];
      if (genres.isNotEmpty) {
        selectGenre(0, genres[0]['slug'].toString());
      }
    }
  }

  Future<void> selectGenre(int index, String slug) async {
    selectedIndex.value = index;
    selectedSlug.value = slug;

    // Reset pagination state for the new genre.
    _page = 1;
    hasMore.value = true;
    stories.clear();

    isLoading.value = true;
    final res = await ApiService.getStories(
      genre: slug,
      page: 1,
      pageSize: _pageSize,
    );
    isLoading.value = false;
    if (res['success']) {
      final d = res['data'];
      final list = d is List ? d : ((d as Map?)?['results'] ?? []);
      stories.value = list;
      hasMore.value = _hasNext(d);
      if (hasMore.value) _page = 2;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    final res = await ApiService.getStories(
      genre: selectedSlug.value,
      page: _page,
      pageSize: _pageSize,
    );
    if (res['success']) {
      final d = res['data'];
      final list = d is List ? d : ((d as Map?)?['results'] ?? []);
      stories.addAll(list as List);
      hasMore.value = _hasNext(d);
      if (hasMore.value) _page++;
    }
    isLoadingMore.value = false;
  }

  static bool _hasNext(dynamic d) {
    if (d is! Map) return false;
    if (d['has_next'] == true) return true;
    final next = d['next'];
    return next != null && next.toString().isNotEmpty;
  }

  String getCoverUrl(Map story) {
    final c = story['cover_image'];
    if (c == null || c.toString().isEmpty) return '';
    if (c.toString().startsWith('http')) return c.toString();
    return 'http://10.0.2.2:8000$c';
  }
}
