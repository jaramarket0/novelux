import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/bookdetails.dart';
import 'package:novelux/screen/book_preview/controller/book_preview_controller.dart';
import 'package:novelux/screen/reading_interface/reading_interface.dart';

BookPreviewController controller = Get.put(BookPreviewController());

class BookPreview extends StatefulWidget {
  int? index;
  final List? bookList;
  BookPreview({super.key, this.index, this.bookList});

  @override
  State<BookPreview> createState() => _BookPreviewState();
}

class _BookPreviewState extends State<BookPreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: 20,
              offset: Offset(-1, -1),
              color: Color(0xFF1a1a1a),
            ),
          ],
          color: Color(0xFF1a1a1a),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 240,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  print('Reading....');
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => NovelUpReadingInterface(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: depperBlue),
                child: Text(
                  'Read',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            //  SizedBox(width: 10,),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    print('Adding to library....');
                  },
                  icon: Icon(Icons.bookmark_add),
                ),
                Text(
                  'Add to library',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1a1a),
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.more_vert, color: Colors.white),
          //   onPressed: () {
          //     // Implement more options functionality here
          //   },
          // ),
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            color: Color(0xFF1a1a1a),
            itemBuilder:
                (context) => [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Row(
                      children: [
                        Text('Share', style: TextStyle(color: Colors.white)),
                        Spacer(),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Row(
                      children: [
                        Text('Report', style: TextStyle(color: Colors.white)),
                        Spacer(),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Row(
                      children: [
                        Text(
                          'Copyright',
                          style: TextStyle(color: Colors.white),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                  // PopupMenuItem<int>(
                  //   value: 3,
                  //   child: Center(
                  //     child: Text(
                  //       'Log Out',
                  //       style: TextStyle(color: Colors.red),
                  //     ),
                  //   ),
                  // ),
                ],
            onSelected: (value) {
              // Handle menu selection
              print(value);
              if (value == 0) {
                //  Get.toNamed(AppRoutes.attendanceLogScreen);
              } else if (value == 1) {
                //    Get.toNamed(AppRoutes.registerCardScreen);
              } else if (value == 2) {
                // Get.toNamed(AppRoutes.changeSchoolCodeOneScreen);
                // Get.dialog(
                //   AlertDialog(
                //     backgroundColor: Colors.transparent,
                //     insetPadding: EdgeInsets.zero,
                //     contentPadding: EdgeInsets.zero,
                //     content: ChangeSchoolCodeDialog(
                //       Get.put(ChangeSchoolCodeController()),
                //     ),
                //   ),
                // );
              } else {
                showDialog(
                  context: Get.context!,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm Logout"),
                      content: Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            //  controller.logout();
                          },
                          child: Text("Logout"),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
        centerTitle: true,
      ),
      backgroundColor: Color(0xFF1a1a1a),
      body: ListView(
        children: [
          // Display book previews here
          // You can use widget.index and widget.bookList to customize the content
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: CarouselSlider.builder(
              itemCount: (widget.bookList?.length ?? 0) + 1,
              itemBuilder: (context, index, realIndex) {
                if (index >= (widget.bookList?.length ?? 0)) {
                  return Container(
                    width: 80,
                  ); // Return an empty widget if index is out of bounds
                }
                final book = widget.bookList![index];
                final bool isActive = index == (widget.index ?? 0);

                return Padding(
                  padding:
                      isActive
                          ? const EdgeInsets.only(top: 20)
                          : EdgeInsets.zero,
                  child: AnimatedScale(
                    scale:
                        isActive
                            ? 1.1
                            : 0.75, // Scale up active, scale down others
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      //padding: EdgeInsets.only(left: ),
                      margin: EdgeInsets.zero,
                      child: Container(
                        width: 120,
                        margin: EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 200,
                              height:
                                  210, // Fixed height, scaling handles the size difference
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    isActive
                                        ? Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        )
                                        : Border.all(
                                          color: Colors.transparent,
                                          width: 2,
                                        ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.book,
                                  color: isActive ? Colors.blue : Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                clipBehavior: Clip.none,
                //enlargeFactor: 0.75,
                disableCenter: true,
                aspectRatio: 12 / 5,
                viewportFraction: 0.45,
                initialPage: widget.index ?? 0,
                enableInfiniteScroll: false,
                reverse: false,
                height: 250, // Increased to accommodate scaling
                enlargeCenterPage: false,
                padEnds: false,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    widget.index = index;
                  });
                },
              ),
            ),
          ),

          // Dots Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children:
                  widget.bookList!.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => setState(() => widget.index = entry.key),
                      child: Container(
                        width: widget.index == entry.key ? 10.0 : 6.0,
                        height: widget.index == entry.key ? 10.0 : 6.0,
                        margin: EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              widget.index == entry.key
                                  ? depperBlue
                                  : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          SizedBox(height: 5),

          //    Book Details
          BookDetails(
            novels: widget.bookList!.cast<Map>(),
            initialIndex: widget.index ?? 0,
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';

// class BookCarouselScreen extends StatefulWidget {
//   @override
//   _BookCarouselScreenState createState() => _BookCarouselScreenState();
// }

// class _BookCarouselScreenState extends State<BookCarouselScreen> {
//   int currentIndex = 0;

//   final List<BookItem> books = [
//     BookItem(
//       title: "Bloody Friendship",
//       author: "Anlhpermy",
//       imageUrl: "assets/bloody_friendship.jpg",
//       rating: 3.0,
//       status: "Ongoing",
//       chapters: 12,
//       views: 1200,
//     ),
//     BookItem(
//       title: "The Disgraced Doctor's Revenge",
//       author: "Author Name",
//       imageUrl: "assets/doctors_revenge.jpg",
//       rating: 4.2,
//       status: "Ongoing",
//       chapters: 15,
//       views: 1500,
//     ),
//     BookItem(
//       title: "Super Bill Techno System",
//       author: "Tech Author",
//       imageUrl: "assets/tech_system.jpg",
//       rating: 4.5,
//       status: "Ongoing",
//       chapters: 17,
//       views: 1700,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // App bar
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Icon(Icons.arrow_back, color: Colors.white),
//                   Spacer(),
//                   CircleAvatar(
//                     backgroundImage: AssetImage("assets/profile.jpg"),
//                   ),
//                 ],
//               ),
//             ),

//             // Carousel Slider
//             CarouselSlider.builder(
//               itemCount: books.length,
//               itemBuilder: (context, index, realIndex) {
//                 return BookCard(book: books[index]);
//               },
//               options: CarouselOptions(
//                 height: 400,
//                 aspectRatio: 0.7,
//                 viewportFraction: 0.65,
//                 initialPage: 0,
//                 enableInfiniteScroll: true,
//                 reverse: false,
//                 autoPlay: false,
//                 enlargeCenterPage: true,
//                 enlargeFactor: 0.2,
//                 scrollDirection: Axis.horizontal,
//                 onPageChanged: (index, reason) {
//                   setState(() {
//                     currentIndex = index;
//                   });
//                 },
//               ),
//             ),

//             SizedBox(height: 20),

//             // Dots Indicator
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: books.asMap().entries.map((entry) {
//                 return GestureDetector(
//                   onTap: () => setState(() => currentIndex = entry.key),
//                   child: Container(
//                     width: currentIndex == entry.key ? 12.0 : 8.0,
//                     height: currentIndex == entry.key ? 12.0 : 8.0,
//                     margin: EdgeInsets.symmetric(horizontal: 4.0),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: currentIndex == entry.key
//                           ? Colors.yellow
//                           : Colors.grey,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),

//             SizedBox(height: 30),

//             // Book Details
//             BookDetails(book: books[currentIndex]),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class BookCard extends StatelessWidget {
//   final BookItem book;

//   const BookCard({Key? key, required this.book}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 15,
//             offset: Offset(0, 8),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             // Background image
//             Image.asset(
//               book.imageUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey[800],
//                   child: Icon(Icons.book, size: 50, color: Colors.white54),
//                 );
//               },
//             ),

//             // Gradient overlay
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.7),
//                   ],
//                   stops: [0.6, 1.0],
//                 ),
//               ),
//             ),

//             // Text content
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     book.title.toUpperCase(),
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 2,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     book.author.toUpperCase(),
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 16,
//                       letterSpacing: 3,
//                       fontWeight: FontWeight.w300,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';

// class BookDetails extends StatelessWidget {
//   final Map novel; // Single novel map instead of list

//   const BookDetails({super.key, required this.novel});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(height: 20),

//           // Novel Title
//           Text(
//             novel["title"] ?? "",
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           SizedBox(height: 8),

//           // Subtitle/Category
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: Color(0xFF2A2A2A),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               novel["subtitle"] ?? "",
//               style: TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//           ),

//           SizedBox(height: 8),

//           Text(
//             novel["author"] ?? "Daniel Ekwere | updated 10 hours ago",
//             style: TextStyle(color: Colors.grey, fontSize: 10),
//           ),

//           SizedBox(height: 20),

//           // Stats Container
//           Container(
//             padding: EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Color(0xFF2A2A2A),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildStatColumn(
//                   topWidget: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         novel["rating"]?.toString() ?? "4.5",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(width: 4),
//                       Icon(Icons.star, color: Colors.yellow, size: 16),
//                     ],
//                   ),
//                   bottomText: "${novel["comments"] ?? 0} Comments >",
//                 ),
//                 _buildDivider(),
//                 _buildStatColumn(
//                   topText: novel["status"] ?? "Ongoing",
//                   bottomText: "${novel["chapters"] ?? 0} Chapters",
//                 ),
//                 _buildDivider(),
//                 _buildStatColumn(
//                   topText: "${novel["views"] ?? 0}",
//                   bottomText: "Views",
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: 15),

//           // Summary Section
//           Text(
//             'Summary',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),

//           SizedBox(height: 10),

//           // Categories (if available)
//           if (novel["categories"] != null) ...[
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: List.generate(
//                 (novel["categories"] as List?)?.length ?? 0,
//                 (catIndex) {
//                   return Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       color: Color(0xFF2A2A2A),
//                     ),
//                     child: Text(
//                       novel["categories"][catIndex] ?? '',
//                       style: TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 10),
//           ],

//           // Book Description
//           ReadMoreText(
//             text:
//                 novel["description"] ??
//                 'An exciting novel filled with drama, action, and unexpected twists. Follow the journey of our protagonist as they navigate through challenges and discover their true destiny.',
//             maxLines: 3,
//           ),

//           Divider(color: Colors.grey, height: 30),
//           SizedBox(height: 10),

//           // Chapter Title
//           Text(
//             novel["chapterTitle"] ?? 'Chapter 1: ${novel["title"]}',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),

//           SizedBox(height: 10),

//           // Chapter Content
//           Text(
//             novel["content"] ?? _getDefaultContent(novel["title"] ?? ""),
//             style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
//           ),

//           SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   String _getDefaultContent(String title) {
//     return '''The story begins in a bustling city where our protagonist discovers an extraordinary secret that will change their life forever.

// As they delve deeper into this mystery, they encounter unexpected allies and formidable enemies. Each chapter reveals new truths and challenges that test their resolve.

// Will they overcome the obstacles in their path? Only time will tell as their journey unfolds...

// This is just the beginning of an epic adventure that will keep you on the edge of your seat!''';
//   }

//   Widget _buildStatColumn({
//     Widget? topWidget,
//     String? topText,
//     required String bottomText,
//   }) {
//     return Expanded(
//       child: Column(
//         children: [
//           topWidget ??
//               Text(
//                 topText ?? "",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//           SizedBox(height: 4),
//           Text(
//             bottomText,
//             style: TextStyle(color: Colors.grey, fontSize: 10),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 8),
//       color: Colors.grey,
//       height: 30,
//       width: 0.5,
//     );
//   }
// }

// // ReadMoreText Widget
// class ReadMoreText extends StatefulWidget {
//   final String text;
//   final int maxLines;

//   const ReadMoreText({super.key, required this.text, this.maxLines = 3});

//   @override
//   State<ReadMoreText> createState() => _ReadMoreTextState();
// }

// class _ReadMoreTextState extends State<ReadMoreText> {
//   bool isExpanded = false;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           widget.text,
//           maxLines: isExpanded ? null : widget.maxLines,
//           overflow: isExpanded ? null : TextOverflow.ellipsis,
//           style: TextStyle(color: Colors.white70, fontSize: 12),
//         ),
//         SizedBox(height: 4),
//         GestureDetector(
//           onTap: () {
//             setState(() {
//               isExpanded = !isExpanded;
//             });
//           },
//           child: Text(
//             isExpanded ? 'Read less' : 'Read more',
//             style: TextStyle(
//               color: Colors.blue,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

class BookItem {
  final String title;
  final String author;
  final String imageUrl;
  final double rating;
  final String status;
  final int chapters;
  final int views;

  BookItem({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.status,
    required this.chapters,
    required this.views,
  });
}

class ReadMoreText1 extends StatelessWidget {
  final String text;
  final int maxLines;

  const ReadMoreText1({Key? key, required this.text, this.maxLines = 3})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: text,
          style: const TextStyle(color: Colors.black),
        );
        final tp = TextPainter(
          text: span,
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflow = tp.didExceedMaxLines;

        return Stack(
          children: [
            Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            if (isOverflow)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color.fromARGB(
                          255,
                          48,
                          47,
                          47,
                        ).withValues(alpha: .9),
                        Color(0xFF1a1a1a),
                      ],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return DraggableScrollableSheet(
                            expand: false,
                            builder: (context, scrollController) {
                              return Column(
                                children: [
                                  SingleChildScrollView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Text(
                                          text,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text(
                      "    View all",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
