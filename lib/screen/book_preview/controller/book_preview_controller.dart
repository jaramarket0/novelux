import 'package:flutter/material.dart';
import 'package:get/get.dart';


class BookPreviewController extends GetxController {
  var isLoading = true.obs;
  var bookPreviewList = <Container>[].obs;

  Rx<int> initIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBookPreviews();
  }

  void fetchBookPreviews() async {
    try {
      isLoading(true);
      // Simulate a network call
      await Future.delayed(Duration(seconds: 2));
      var previews = List.generate(
        10,
        (index) => Container(),
      ); // BookPreview()); // Replace with actual data fetching
      bookPreviewList.assignAll(previews);
    } finally {
      isLoading(false);
    }
  }
}
