import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/screen/book_preview/controller/book_preview_controller.dart';

BookPreviewController controller = Get.put(BookPreviewController());

class BookDetails extends StatefulWidget {
  final List<Map> novels; // List of all novels
  final int initialIndex; // Starting index

  const BookDetails({super.key, required this.novels, this.initialIndex = 0});

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(BookDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update page when carousel changes
    if (widget.initialIndex != oldWidget.initialIndex) {
      _pageController.animateToPage(
        widget.initialIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentIndex = widget.initialIndex;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 100 * 120,
      child: PageView.builder(
        // scrollDirection: Axis.vertical,
        scrollBehavior: MaterialScrollBehavior(),
        controller: _pageController,
        itemCount: widget.novels.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
            controller.initIndex.value = index;
          });
          print(controller.initIndex.value);
        },
        itemBuilder: (BuildContext context, int index) {
          final novel = widget.novels[index];

          return SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //SizedBox(height: 20),

                // Novel Title
                Text(
                  novel["title"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                // Subtitle/Category
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    novel["subtitle"] ?? "",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  novel["author"] ?? "Daniel Ekwere | updated 10 hours ago",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

                SizedBox(height: 20),

                // Stats Container
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        topWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              novel["rating"]?.toString() ?? "4.5",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.star, color: Colors.yellow, size: 10),
                          ],
                        ),
                        bottomText: "${novel["comments"] ?? 0} Comments >",
                      ),
                      _buildDivider(),
                      _buildStatColumn(
                        topText: novel["status"] ?? "Ongoing",
                        bottomText: "${novel["chapters"] ?? 0} Chapters",
                      ),
                      _buildDivider(),
                      _buildStatColumn(
                        topText: "${novel["views"] ?? 0}",
                        bottomText: "Views",
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // Summary Section
                Text(
                  'Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 10),

                // Categories (if available)
                if (novel["categories"] != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      (novel["categories"] as List?)?.length ?? 0,
                      (catIndex) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color(0xFF2A2A2A),
                          ),
                          child: Text(
                            novel["categories"][catIndex] ?? '',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                ],

                // Book Description
                ReadMoreText(
                  text:
                      novel["description"] ??
                      'An exciting novel filled with drama, action, and unexpected twists. Follow the journey of our protagonist as they navigate through challenges and discover their true destiny.',
                  maxLines: 3,
                ),

                Divider(color: Colors.grey, height: 30),
                SizedBox(height: 10),

                // Chapter Title
                Text(
                  novel["chapterTitle"] ?? 'Chapter 1: ${novel["title"]}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                SizedBox(height: 10),

                // Chapter Content
                Text(
                  novel["content"] ?? _getDefaultContent(novel["title"] ?? ""),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                SizedBox(height: 30),

                // Page indicator
                Center(
                  child: Text(
                    'Swipe to see other books (${currentIndex + 1}/${widget.novels.length})',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDefaultContent(String title) {
    return '''The story begins in a bustling city where our protagonist discovers an extraordinary secret that will change their life forever.

As they delve deeper into this mystery, they encounter unexpected allies and formidable enemies. Each chapter reveals new truths and challenges that test their resolve.

Will they overcome the obstacles in their path? Only time will tell as their journey unfolds...

This is just the beginning of an epic adventure that will keep you on the edge of your seat!''';
  }

  Widget _buildStatColumn({
    Widget? topWidget,
    String? topText,
    required String bottomText,
  }) {
    return Expanded(
      child: Column(
        children: [
          topWidget ??
              Text(
                topText ?? "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          SizedBox(height: 4),
          Text(
            bottomText,
            style: TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey,
      height: 30,
      width: 0.5,
    );
  }
}

// ReadMoreText Widget
class ReadMoreText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ReadMoreText({super.key, required this.text, this.maxLines = 3});

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: isExpanded ? null : widget.maxLines,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Text(
            isExpanded ? 'Read less' : 'Read more',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
