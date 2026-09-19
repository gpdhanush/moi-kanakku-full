import 'package:flutter/material.dart';

/// Shared pagination state for infinite-scroll API lists.
///
/// Mirrors the persons-list / TransactionDashboard contract:
/// `{ count, page, limit, hasMore, responseValue }`.
class PaginatedListState<T> {
  PaginatedListState({this.pageSize = 30});

  final int pageSize;

  int page = 1;
  int totalCount = 0;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  List<T> items = [];

  void prepareReset({required bool showLoading}) {
    if (showLoading) isLoading = true;
    page = 1;
    hasMore = true;
  }

  /// Returns false if a load-more should be skipped.
  bool prepareLoadMore() {
    if (!hasMore || isLoadingMore || isLoading) return false;
    isLoadingMore = true;
    return true;
  }

  int nextPageToLoad({required bool reset}) => reset ? 1 : page + 1;

  void applySuccess({
    required bool reset,
    required List<T> chunk,
    required int total,
    required bool responseHasMore,
    required int pageLoaded,
  }) {
    if (reset) {
      items = chunk;
    } else {
      items = [...items, ...chunk];
    }
    page = pageLoaded;
    totalCount = total;
    hasMore = responseHasMore && chunk.isNotEmpty;
    isLoading = false;
    isLoadingMore = false;
  }

  void applyFailure({required bool reset}) {
    isLoading = false;
    isLoadingMore = false;
    if (reset) {
      items = [];
      totalCount = 0;
      hasMore = false;
      page = 1;
    }
  }

  void clear() {
    items = [];
    totalCount = 0;
    page = 1;
    hasMore = false;
    isLoading = false;
    isLoadingMore = false;
  }
}

/// Parses persons/transactions-style list API responses.
class PaginatedResponseParser {
  static List<Map<String, dynamic>> mapChunk(dynamic responseValue) {
    if (responseValue is! List) return [];
    return responseValue
        .map(
          (e) => e is Map
              ? Map<String, dynamic>.from(e)
              : <String, dynamic>{},
        )
        .toList();
  }

  static int parseTotal(dynamic count, {required int fallback}) {
    if (count is int) return count;
    return int.tryParse(count?.toString() ?? '') ?? fallback;
  }

  static bool parseHasMore({
    required dynamic hasMore,
    required int chunkLength,
    required int pageSize,
    int? total,
    int? offsetAfter,
  }) {
    if (hasMore == true) return true;
    if (hasMore == false) return false;
    if (total != null && offsetAfter != null) {
      return offsetAfter < total;
    }
    return chunkLength >= pageSize;
  }
}

/// Scroll listener helper — triggers [onNearEnd] ~[threshold] px before bottom.
mixin InfiniteScrollMixin<T extends StatefulWidget> on State<T> {
  ScrollController get infiniteScrollController;
  double get infiniteScrollThreshold => 400;

  void attachInfiniteScroll(VoidCallback onNearEnd) {
    infiniteScrollController.addListener(() {
      if (!infiniteScrollController.hasClients) return;
      final position = infiniteScrollController.position;
      if (position.pixels >= position.maxScrollExtent - infiniteScrollThreshold) {
        onNearEnd();
      }
    });
  }
}
