import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'dart:developer' as myLog;

class ExploreController extends GetxController {
  // ── Loading flags (UNCHANGED from your original) ──────────────────────────
  final RxBool isLoadingTrending = false.obs;
  final RxBool isLoadingFeatured = false.obs;
  final RxBool isLoadingEditors = false.obs;
  final RxBool isLoadingForYou = false.obs;
  final RxBool isLoadingworldFamous = false.obs;
  final RxBool isLoadingFreeDownlaod = false.obs;
  final RxBool isLoadingCompletedStories = false.obs;
  final RxBool isLoadingAfricanFolkTale = false.obs;
  final RxBool isLoadingBanners = false.obs;
  final RxBool isLoadingPrefs = false.obs;

  // ── NEW: "load more" loading flags (one per section) ─────────────────────
  final RxBool isLoadingMoreTrending = false.obs;
  final RxBool isLoadingMoreFeatured = false.obs;
  final RxBool isLoadingMoreEditors = false.obs;
  final RxBool isLoadingMoreForYou = false.obs;
  final RxBool isLoadingMoreWorldFamous = false.obs;
  final RxBool isLoadingMoreFreeDownload = false.obs;
  final RxBool isLoadingMoreCompleted = false.obs;
  final RxBool isLoadingMoreAfricanFolktale = false.obs;

  // ── NEW: hasMore flags (stops fetching when backend says no next page) ────
  final RxBool hasMoreTrending = true.obs;
  final RxBool hasMoreFeatured = true.obs;
  final RxBool hasMoreEditors = true.obs;
  final RxBool hasMoreForYou = true.obs;
  final RxBool hasMoreWorldFamous = true.obs;
  final RxBool hasMoreFreeDownload = true.obs;
  final RxBool hasMoreCompleted = true.obs;
  final RxBool hasMoreAfricanFolktale = true.obs;

  // ── NEW: page counters (one per section) ──────────────────────────────────
  int _trendingPage = 1;
  int _featuredPage = 1;
  int _editorsPage = 1;
  int _forYouPage = 1;
  int _worldFamousPage = 1;
  int _freeDownloadPage = 1;
  int _completedPage = 1;
  int _africanPage = 1;

  static const _pageSize = 5;

  // ── Story lists (SAME names as your original — no breaking change) ────────
  final RxList trending = [].obs;
  final RxList featured = [].obs;
  final RxList editorsPick = [].obs;
  final RxList forYou = [].obs;
  final RxList worldFamous = [].obs;
  final RxList completedStories = [].obs;
  final RxList freeDownLoad = [].obs;
  final RxList africanfolktale = [].obs;
  final RxList bestNovels = [].obs;
  final RxBool isLoadingBestNovels = false.obs;
  final RxString selectedBestNovelsSort = 'views'.obs;

  final RxList genres = [].obs;
  final RxList promoBanners = [].obs;

  // ── New home sections ─────────────────────────────────────────────────────
  final RxList newArrivals = [].obs;
  final RxBool isLoadingNewArrivals = false.obs;

  final RxList recommended = [].obs;
  final RxBool isLoadingRecommended = false.obs;

  final RxList freeDiscount = [].obs;
  final RxBool isLoadingFreeDiscount = false.obs;

  final RxList shortStories = [].obs;
  final RxBool isLoadingShortStories = false.obs;

  // Rankings — one cached list per period, loaded on first tab switch only
  final RxList rankingsDaily = [].obs;
  final RxList rankingsWeekly = [].obs;
  final RxList rankingsMonthly = [].obs;
  final RxList rankingsAllTime = [].obs;
  final RxBool isLoadingRankings = false.obs;
  final RxString selectedRankingPeriod = 'all-time'.obs;
  final _rankingsLoaded = <String>{};

  // Author spotlight
  final Rx<Map<String, dynamic>> authorSpotlight = Rx<Map<String, dynamic>>({});
  final RxBool isLoadingAuthorSpotlight = false.obs;

  // ── Genre tab data (Werewolf, Billionaire, Short Fics, etc.) ─────────────
  final RxMap<String, Map<String, dynamic>> genreTabCache =
      <String, Map<String, dynamic>>{}.obs;
  final RxSet<String> genreTabLoading = <String>{}.obs;

  // ── Preferences (UNCHANGED) ───────────────────────────────────────────────
  final RxList<String> preferredGenres = <String>[].obs;
  final RxList<Map<String, String>> forYouTabs = <Map<String, String>>[].obs;
  final RxString selectedForYouTab = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedGenre = ''.obs;

  // ── Default banners (UNCHANGED) ───────────────────────────────────────────
  static const defaultBanners = [
    {
      'image': 'assets/images/promotion1.png',
      'slug': '',
      'title': 'New Arrivals This Week',
    },
    {
      'image': 'assets/images/promotion2.png',
      'slug': '',
      'title': 'Top Romance Picks',
    },
    {
      'image': 'assets/images/promotion3.png',
      'slug': '',
      'title': 'African Bestsellers',
    },
  ];

  // ── Category metadata (UNCHANGED) ────────────────────────────────────────
  static const _categoryMeta = {
    'romance': {'label': 'Romance', 'emoji': '💕'},
    'billionaire': {'label': 'Billionaire', 'emoji': '💰'},
    'werewolf': {'label': 'Werewolf', 'emoji': '🐺'},
    'fantasy': {'label': 'Fantasy', 'emoji': '🧙'},
    'ceo-office': {'label': 'CEO', 'emoji': '🏢'},
    'african-fiction': {'label': 'African', 'emoji': '🌍'},
    'thriller': {'label': 'Thriller', 'emoji': '🔪'},
    'mystery': {'label': 'Mystery', 'emoji': '🕵️'},
    'sci-fi': {'label': 'Sci-Fi', 'emoji': '🚀'},
    'horror': {'label': 'Horror', 'emoji': '👻'},
    'historical': {'label': 'Historical', 'emoji': '🏛️'},
    'comedy': {'label': 'Comedy', 'emoji': '😂'},
    'action': {'label': 'Action', 'emoji': '⚔️'},
    'drama': {'label': 'Drama', 'emoji': '🎭'},
    'young-adult': {'label': 'YA', 'emoji': '🎓'},
    'reverse-harem': {'label': 'Harem', 'emoji': '👑'},
    'mafia': {'label': 'Mafia', 'emoji': '🔫'},
    'second-chance': {'label': '2nd Chance', 'emoji': '🔄'},
  };

  // ══════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE (UNCHANGED)
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    _loadPreferencesFromBackend().then((_) => fetchAll());
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PREFERENCES (UNCHANGED logic, same method names)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadPreferencesFromBackend() async {
    isLoadingPrefs.value = true;
    final res = await ApiService.getUserPreferences();
    myLog.log('Loaded preferences: $res');
    isLoadingPrefs.value = false;
    if (res['success']) {
      final data = res['data'];
      final genres = List<String>.from(data['preferred_genres'] ?? []);
      myLog.log('genre: $genres');
      _applyPreferences(genres);
    }
  }

  void _applyPreferences(List<String> genres) {
    for (final i in genres) {
      preferredGenres.add(i);
    }
    myLog.log('preferred Genres: $preferredGenres');
    // Default-select the first preferred genre (no "All" tab); if the user
    // has no preferences, selectedForYouTab stays 'All' → unfiltered fetch
    if (genres.isNotEmpty) {
      selectedForYouTab.value =
          genres.first.replaceAll('-', ' ').capitalize ?? genres.first;
    }
    final tabs = <Map<String, String>>[];
    for (final slug in genres) {
      final meta = _categoryMeta[slug];
      tabs.add({
        'slug': slug,
        'label': meta?['label'] ?? slug,
        'emoji': meta?['emoji'] ?? '📖',
      });
    }
    forYouTabs.value = tabs;
  }

  Future<void> refreshPreferences() async {
    await _loadPreferencesFromBackend();
    await fetchForYouByPreferences();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH ALL  (UNCHANGED — same call as before)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchAll() async {
    myLog.log('fetching all story type', name: 'FETACH ALL.');
    fetchTrending();
    fetchFeatured();
    fetchEditorsPick();
    fetchGenres();
    fetchForYouByPreferences();
    fetchFreeDownLoad();
    fetchCompletedStories();
    fetchWorldFamous();
    fetchAfricanFolktale();
    fetchPromoBanners();
    fetchBestNovels('views');
    // New home sections
    fetchNewArrivals();
    fetchRecommended();
    fetchFreeDiscount();
    fetchShortStories();
    fetchRankings('all-time');
    fetchAuthorSpotlight();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PROMO BANNERS (UNCHANGED)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchPromoBanners() async {
    myLog.log('Fetching promo banners from backend...');
    isLoadingBanners.value = true;
    final res = await ApiService.getPromoBanners();
    myLog.log('Fetched promo banners: $res');
    isLoadingBanners.value = false;
    if (res['success']) {
      final data = res['data'];
      if (data is List && data.isNotEmpty) {
        promoBanners.value = data;
        return;
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FOR YOU — first load + loadMore + filterForYou
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchForYouByPreferences() async {
    // Reset pagination state on first load
    myLog.log('fetching for you......');
    _forYouPage = 1;
    hasMoreForYou.value = true;
    isLoadingForYou.value = true;
    myLog.log(selectedForYouTab.value);
    final res = await ApiService.getStories(
      page: 1,
      pageSize: _pageSize,
      genre: selectedForYouTab.value == 'All' ? null : selectedForYouTab.value,
    );

    isLoadingForYou.value = false;
    if (res['success']) {
      final data = res['data'];
      forYou.value = _extractList(data);
      hasMoreForYou.value = _hasNext(data);
      if (hasMoreForYou.value) _forYouPage = 2;
    }
  }

  /// Called by LazyStoryRow/Grid when user scrolls to 80%
  Future<void> loadMoreForYou() async {
    if (!hasMoreForYou.value || isLoadingMoreForYou.value) return;
    isLoadingMoreForYou.value = true;

    final res = await ApiService.getStories(
      page: _forYouPage,
      pageSize: _pageSize,
      genre: selectedForYouTab.value == 'All' ? null : selectedForYouTab.value,
    );

    isLoadingMoreForYou.value = false;
    if (res['success']) {
      final data = res['data'];
      forYou.addAll(_extractList(data));
      hasMoreForYou.value = _hasNext(data);
      if (hasMoreForYou.value) _forYouPage++;
    }
  }

  /// Tab filter (UNCHANGED signature — your screen calls this already)
  Future<void> filterForYou(String slug) async {
    print('Filtering For You by: $slug');
    selectedForYouTab.value = slug;
    // Reset and reload
    _forYouPage = 1;
    hasMoreForYou.value = true;
    await fetchForYouByPreferences();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TRENDING — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchTrending() async {
    _trendingPage = 1;
    hasMoreTrending.value = true;
    isLoadingTrending.value = true;
    final res = await ApiService.getTrending(page: 1, pageSize: _pageSize);
    myLog.log(res.toString());
    isLoadingTrending.value = false;
    if (res['success']) {
      final data = res['data'];
      trending.value = _extractList(data);
      myLog.log('Trending data: $data');
      hasMoreTrending.value = _hasNext(data);
      if (hasMoreTrending.value) _trendingPage = 2;
    }
  }

  Future<void> loadMoreTrending() async {
    if (!hasMoreTrending.value || isLoadingMoreTrending.value) return;
    isLoadingMoreTrending.value = true;
    final res = await ApiService.getTrending(
      page: _trendingPage,
      pageSize: _pageSize,
    );
    isLoadingMoreTrending.value = false;
    if (res['success']) {
      final data = res['data'];
      trending.addAll(_extractList(data));
      hasMoreTrending.value = _hasNext(data);
      if (hasMoreTrending.value) _trendingPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BEST NOVELS — sorted by tab selection
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchBestNovels(String sortBy) async {
    if (isLoadingBestNovels.value) return;
    selectedBestNovelsSort.value = sortBy;
    isLoadingBestNovels.value = true;
    try {
      final res = await ApiService.getBestNovels(sortBy: sortBy, pageSize: 9);
      if (res['success']) {
        bestNovels.value = _extractList(res['data']);
      }
    } catch (e) {
      myLog.log('fetchBestNovels error: $e');
    } finally {
      isLoadingBestNovels.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FEATURED — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchFeatured() async {
    _featuredPage = 1;
    hasMoreFeatured.value = true;
    isLoadingFeatured.value = true;
    final res = await ApiService.getFeatured(page: 1, pageSize: _pageSize);
    isLoadingFeatured.value = false;
    if (res['success']) {
      final data = res['data'];
      featured.value = _extractList(data);
      hasMoreFeatured.value = _hasNext(data);
      if (hasMoreFeatured.value) _featuredPage = 2;
    }
  }

  Future<void> loadMoreFeatured() async {
    if (!hasMoreFeatured.value || isLoadingMoreFeatured.value) return;
    isLoadingMoreFeatured.value = true;
    final res = await ApiService.getFeatured(
      page: _featuredPage,
      pageSize: _pageSize,
    );
    isLoadingMoreFeatured.value = false;
    if (res['success']) {
      final data = res['data'];
      featured.addAll(_extractList(data));
      hasMoreFeatured.value = _hasNext(data);
      if (hasMoreFeatured.value) _featuredPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  EDITORS PICK — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchEditorsPick() async {
    _editorsPage = 1;
    hasMoreEditors.value = true;
    isLoadingEditors.value = true;
    final res = await ApiService.getEditorsPick(page: 1, pageSize: _pageSize);
    isLoadingEditors.value = false;
    if (res['success']) {
      final data = res['data'];
      editorsPick.value = _extractList(data);
      hasMoreEditors.value = _hasNext(data);
      if (hasMoreEditors.value) _editorsPage = 2;
    }
  }

  Future<void> loadMoreEditorsPick() async {
    if (!hasMoreEditors.value || isLoadingMoreEditors.value) return;
    isLoadingMoreEditors.value = true;
    final res = await ApiService.getEditorsPick(
      page: _editorsPage,
      pageSize: _pageSize,
    );
    isLoadingMoreEditors.value = false;
    if (res['success']) {
      final data = res['data'];
      editorsPick.addAll(_extractList(data));
      hasMoreEditors.value = _hasNext(data);
      if (hasMoreEditors.value) _editorsPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WORLD FAMOUS — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchWorldFamous() async {
    _worldFamousPage = 1;
    hasMoreWorldFamous.value = true;
    isLoadingworldFamous.value = true;
    final res = await ApiService.getWorldFamous(page: 1, pageSize: _pageSize);
    isLoadingworldFamous.value = false;
    if (res['success']) {
      final data = res['data'];
      worldFamous.value = _extractList(data);
      hasMoreWorldFamous.value = _hasNext(data);
      if (hasMoreWorldFamous.value) _worldFamousPage = 2;
    }
  }

  Future<void> loadMoreWorldFamous() async {
    if (!hasMoreWorldFamous.value || isLoadingMoreWorldFamous.value) return;
    isLoadingMoreWorldFamous.value = true;
    final res = await ApiService.getWorldFamous(
      page: _worldFamousPage,
      pageSize: _pageSize,
    );
    isLoadingMoreWorldFamous.value = false;
    if (res['success']) {
      final data = res['data'];
      worldFamous.addAll(_extractList(data));
      hasMoreWorldFamous.value = _hasNext(data);
      if (hasMoreWorldFamous.value) _worldFamousPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  COMPLETED STORIES — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchCompletedStories() async {
    _completedPage = 1;
    hasMoreCompleted.value = true;
    isLoadingCompletedStories.value = true;
    final res = await ApiService.getCompletedStories(
      page: 1,
      pageSize: _pageSize,
    );
    isLoadingCompletedStories.value = false;
    if (res['success']) {
      final data = res['data'];
      completedStories.value = _extractList(data);
      hasMoreCompleted.value = _hasNext(data);
      if (hasMoreCompleted.value) _completedPage = 2;
    }
  }

  Future<void> loadMoreCompleted() async {
    if (!hasMoreCompleted.value || isLoadingMoreCompleted.value) return;
    isLoadingMoreCompleted.value = true;
    final res = await ApiService.getCompletedStories(
      page: _completedPage,
      pageSize: _pageSize,
    );
    isLoadingMoreCompleted.value = false;
    if (res['success']) {
      final data = res['data'];
      completedStories.addAll(_extractList(data));
      hasMoreCompleted.value = _hasNext(data);
      if (hasMoreCompleted.value) _completedPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FREE DOWNLOAD — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchFreeDownLoad() async {
    _freeDownloadPage = 1;
    hasMoreFreeDownload.value = true;
    isLoadingFreeDownlaod.value = true;
    final res = await ApiService.getFreeDownLoad(page: 1, pageSize: _pageSize);
    isLoadingFreeDownlaod.value = false;
    if (res['success']) {
      final data = res['data'];
      freeDownLoad.value = _extractList(data);
      hasMoreFreeDownload.value = _hasNext(data);
      if (hasMoreFreeDownload.value) _freeDownloadPage = 2;
    }
  }

  Future<void> loadMoreFreeDownload() async {
    if (!hasMoreFreeDownload.value || isLoadingMoreFreeDownload.value) return;
    isLoadingMoreFreeDownload.value = true;
    final res = await ApiService.getFreeDownLoad(
      page: _freeDownloadPage,
      pageSize: _pageSize,
    );
    isLoadingMoreFreeDownload.value = false;
    if (res['success']) {
      final data = res['data'];
      freeDownLoad.addAll(_extractList(data));
      hasMoreFreeDownload.value = _hasNext(data);
      if (hasMoreFreeDownload.value) _freeDownloadPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  AFRICAN FOLKTALE — first load + loadMore
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchAfricanFolktale() async {
    _africanPage = 1;
    hasMoreAfricanFolktale.value = true;
    isLoadingAfricanFolkTale.value = true;
    final res = await ApiService.getAfricanFolkTale(
      page: 1,
      pageSize: _pageSize,
    );
    isLoadingAfricanFolkTale.value = false;
    if (res['success']) {
      final data = res['data'];
      africanfolktale.value = _extractList(data);
      hasMoreAfricanFolktale.value = _hasNext(data);
      if (hasMoreAfricanFolktale.value) _africanPage = 2;
    }
  }

  Future<void> loadMoreAfricanFolktale() async {
    if (!hasMoreAfricanFolktale.value || isLoadingMoreAfricanFolktale.value)
      return;
    isLoadingMoreAfricanFolktale.value = true;
    final res = await ApiService.getAfricanFolkTale(
      page: _africanPage,
      pageSize: _pageSize,
    );
    isLoadingMoreAfricanFolktale.value = false;
    if (res['success']) {
      final data = res['data'];
      africanfolktale.addAll(_extractList(data));
      hasMoreAfricanFolktale.value = _hasNext(data);
      if (hasMoreAfricanFolktale.value) _africanPage++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GENRES (UNCHANGED)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchGenres() async {
    final res = await ApiService.getGenres();
    if (res['success']) genres.value = _extractList(res['data']);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UNCHANGED helper methods (kept exactly as you had them)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchForYou() async {
    final res = await ApiService.getStories(page: 1, pageSize: _pageSize);
    if (res['success']) forYou.value = _extractList(res['data']);
  }

  Future<void> filterByGenre(String genreSlug) async {
    selectedGenre.value = genreSlug;
    final res = await ApiService.getStories(genre: genreSlug);
    if (res['success']) forYou.value = _extractList(res['data']);
  }

  Future<void> search(String query) async {
    searchQuery.value = query;
    final res = await ApiService.getStories(search: query);
    if (res['success']) forYou.value = _extractList(res['data']);
  }

  // ── Helpers (UNCHANGED) ───────────────────────────────────────────────────

  /// Works for both plain lists AND paginated { results: [...] } responses
  List _extractList(dynamic data) =>
      data is List ? data : ((data as Map?)?['results'] ?? []);

  /// Reads has_next from paginated response; false for plain lists
  bool _hasNext(dynamic data) {
    if (data is Map) return data['has_next'] == true;
    return false; // plain list → treat as single page
  }

  String getCoverUrl(Map? story) {
    final cover = story!['cover_image'];
    if (cover == null || cover.toString().isEmpty) return '';
    if (cover.toString().startsWith('http')) return cover.toString();
    return 'http://10.0.2.2:8000$cover';
  }

  String getBannerImageUrl(Map banner) {
    final img = banner['image'];
    if (img == null || img.toString().isEmpty) return '';
    if (img.toString().startsWith('http')) return img.toString();
    if (img.toString().startsWith('assets/')) return img.toString();
    return 'http://10.0.2.2:8000$img';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NEW HOME SECTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchNewArrivals() async {
    isLoadingNewArrivals.value = true;
    final res = await ApiService.getNewArrivals(page: 1, pageSize: 10);
    isLoadingNewArrivals.value = false;
    if (res['success']) newArrivals.value = _extractList(res['data']);
  }

  Future<void> fetchRecommended() async {
    isLoadingRecommended.value = true;
    final res = await ApiService.getRecommended(page: 1, pageSize: _pageSize);
    isLoadingRecommended.value = false;
    if (res['success']) recommended.value = _extractList(res['data']);
  }

  Future<void> fetchFreeDiscount() async {
    isLoadingFreeDiscount.value = true;
    final res = await ApiService.getFreeDiscount(page: 1, pageSize: _pageSize);
    isLoadingFreeDiscount.value = false;
    if (res['success']) freeDiscount.value = _extractList(res['data']);
  }

  Future<void> fetchShortStories() async {
    isLoadingShortStories.value = true;
    final res = await ApiService.getShortStories(page: 1, pageSize: _pageSize);
    isLoadingShortStories.value = false;
    if (res['success']) shortStories.value = _extractList(res['data']);
  }

  Future<void> fetchRankings(String period) async {
    // Use cached data if this period was already fetched
    if (_rankingsLoaded.contains(period)) {
      selectedRankingPeriod.value = period;
      return;
    }
    selectedRankingPeriod.value = period;
    isLoadingRankings.value = true;
    final res = await ApiService.getRankings(period: period, pageSize: 20);
    isLoadingRankings.value = false;
    if (res['success']) {
      final list = _extractList(res['data']);
      _rankingsLoaded.add(period);
      switch (period) {
        case 'daily':
          rankingsDaily.value = list;
          break;
        case 'weekly':
          rankingsWeekly.value = list;
          break;
        case 'monthly':
          rankingsMonthly.value = list;
          break;
        case 'all-time':
          rankingsAllTime.value = list;
          break;
      }
    }
  }

  RxList get currentRankingsList {
    switch (selectedRankingPeriod.value) {
      case 'daily':
        return rankingsDaily;
      case 'weekly':
        return rankingsWeekly;
      case 'monthly':
        return rankingsMonthly;
      default:
        return rankingsAllTime;
    }
  }

  Future<void> fetchAuthorSpotlight() async {
    isLoadingAuthorSpotlight.value = true;
    final res = await ApiService.getAuthorSpotlight();
    isLoadingAuthorSpotlight.value = false;
    if (res['success'] && res['data'] is Map) {
      authorSpotlight.value = Map<String, dynamic>.from(res['data'] as Map);
    }
  }

  // ── Genre tab fetch (Werewolf, Billionaire, Short Fics, etc.) ────────────
  Future<void> fetchGenreTab(String tab, {String period = 'all-time'}) async {
    // Already cached — don't re-fetch
    if (genreTabCache.containsKey(tab)) return;
    // Already in-flight
    if (genreTabLoading.contains(tab)) return;

    genreTabLoading.add(tab);
    final res = await ApiService.getExploreTab(tab, period: period);
    genreTabLoading.remove(tab);

    if (res['success'] && res['data'] is Map) {
      genreTabCache[tab] = Map<String, dynamic>.from(res['data'] as Map);
    }
  }

  void invalidateGenreTab(String tab) => genreTabCache.remove(tab);
}
