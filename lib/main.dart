import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Default route
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SquareAnimation(),
        '/dockScreen': (context) => const DockScreen()
      },
    );
  }
}

class SquareAnimation extends StatefulWidget {
  const SquareAnimation({super.key});

  @override
  State<SquareAnimation> createState() {
    return SquareAnimationState();
  }
}

class SquareAnimationState extends State<SquareAnimation> {
  static const _squareSize = 50.0;
  Alignment boxAlignment = Alignment.center;
  bool onLeftEnd = false;
  bool onRightEnd = false;

// Function to check Box position and disable button
  void checkButtonPosition() {
    if (boxAlignment == Alignment.centerLeft) {
      setState(() {
        onLeftEnd = true;
        onRightEnd = false;
      });
    } else if (boxAlignment == Alignment.centerRight) {
      setState(() {
        onRightEnd = true;
        onLeftEnd = false;
      });
    }
  }

  void moveButton(Alignment position) {
    setState(() {
      boxAlignment = position;
      // Disable both buttons when Box is moving
      onRightEnd = true;
      onLeftEnd = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Wrap the container with AnimatedAlign which
        // automatically handle animation of positions.
        AnimatedAlign(
          // Uses a dynamic Alignment, so it can be
          // easily changed based on button clicked
          alignment: boxAlignment,
          // Check what position the box is at the end of the
          // animation, and disable the respective button
          onEnd: checkButtonPosition,
          duration: const Duration(milliseconds: 1000),
          child: Container(
            width: _squareSize,
            height: _squareSize,
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              // Disable To-Left button if [onLeftEnd] is set to true,
              // by setting the onpress callback to a null.
              onPressed:
                  onLeftEnd ? null : () => moveButton(Alignment.centerLeft),
              child: const Text('To Left'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              // Disable To-Right button if [onRightEnd] is set to true,
              // by setting the onpress callback to a null.
              onPressed:
                  onRightEnd ? null : () => moveButton(Alignment.centerRight),
              child: const Text('To Right'),
            ),
          ],
        ),
        const SizedBox(height: 80),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            // Move to Dock task
            onPressed: () => Navigator.pushNamed(context, '/dockScreen'),
            child: const Text('To Go Next Task'),
          ),
        ),
      ],
    );
  }
}

class DockScreen extends StatefulWidget {
  const DockScreen({super.key});

  @override
  State<DockScreen> createState() => _DockScreenState();
}

class _DockScreenState extends State<DockScreen> {
  List<IconData> itemsList = const [
    Icons.person,
    Icons.message,
    Icons.call,
    Icons.camera,
    Icons.photo,
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Dock(
                items: itemsList,
                builder: (
                  icon,
                ) {
                  return _buildIconContainer(icon);
                },
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                ),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData iconName) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 48,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.primaries[iconName.hashCode % Colors.primaries.length],
      ),
      child: Center(child: Icon(iconName, color: Colors.white)),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(
    T,
  ) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items;

  /// Stand in spaces of items that looks like they have been removed
  final emptyPlaceholder = SizedBox.shrink();

  /// Give a gap for spaces that looks open and empty
  final placeholder = SizedBox(
    width: 50,
  );

  /// Index of the widget being dragged
  int? draggedIndex;

  /// Index of the widget or widget area the cursor is pointing to
  int? hoverIndex;

  bool isHovered = false;

  final double dockPadding = 4;

  @override
  void initState() {
    _items = widget.items.toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
        height: isHovered ? 100 : 95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        padding: EdgeInsets.all(dockPadding),
        child: DragTarget<int>(
            onMove: (details) => onMove(details),
            onLeave: (data) {
              setState(() {
                hoverIndex = null;
              });
            },
            onAcceptWithDetails: (draggedIndex) => onAccept(draggedIndex),
            builder: (context, candidateData, rejectedData) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildItemsDisplay(),
              );
            }),
      ),
    );
  }

  List<Widget> _buildItemsDisplay() {
    List<Widget> displayItem = [];

    for (int i = 0; i <= _items.length; i++) {
      /// Check if we are hovering on the current item
      if (i == hoverIndex && draggedIndex != null) {
        /// Add a placeholder to show an empty space in that posiition
        displayItem.add(placeholder);
      }

      if (i < _items.length) {
        final item = _items[i];

        /// Create item widget from the builder provided
        final builtItem = widget.builder(
          item,
        );

        /// check if the current item is not being dragged
        if (i != draggedIndex) {
          /// Add the [builtItem] wrapped in a draggable (normal display widget)
          displayItem.add(
            MouseRegion(
              onEnter: (_) => setState(() => hoverIndex = i),
              onExit: (_) => setState(() => hoverIndex = null),
              child: Draggable<int>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: builtItem,
                ),
                feedbackOffset: Offset(0, -20),

                /// what take the place of an in the dock while it is being dragged
                childWhenDragging: emptyPlaceholder,
                onDragStarted: () => {
                  setState(() {
                    draggedIndex = i;
                  })
                },
                onDragEnd: (details) {
                  if (!details.wasAccepted) {
                    setState(() {
                      draggedIndex = null;
                      hoverIndex = null;
                    });
                  }
                },
                onDraggableCanceled: (velocity, offset) {
                  setState(() {
                    if (draggedIndex != null) {
                      // Move the item back to its original location
                      final item = _items.removeAt(draggedIndex!);
                      _items.insert(draggedIndex!, item);
                    }
                    draggedIndex = null;
                    hoverIndex = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  // Move continer up when hovered on
                  transform: Matrix4.translationValues(
                      0, (hoverIndex == i) ? -8.0 : 0.0, 0),
                  curve: Curves.easeIn,
                  child: builtItem,
                ),
              ),
            ),
          );
        } else {
          /// Current item is being dragged
          /// add an empty space in the result list
          displayItem.add(emptyPlaceholder);
        }
      }
    }

    return displayItem;
  }

  void onAccept(DragTargetDetails<int> details) {
    final draggedIndex = details.data;

    setState(() {
      if (hoverIndex != null) {
        final item = _items.removeAt(draggedIndex);

        int insertIndex = hoverIndex!;

        /// Check if item is being dragged to the left,
        if (insertIndex > draggedIndex) {
          /// Then subtract 1 from the [insertIndex], so the list shifts to the right
          insertIndex--;
        }

        /// Check if the insertIndex is the last index or probably more
        if (insertIndex >= _items.length) {
          /// Add to the end of the list
          _items.add(item);
        } else {
          _items.insert(insertIndex, item);
        }
      } else {
        /// Hover index is null so the item was not dropped in the dragtarget
        final item = _items.removeAt(draggedIndex);

        /// Add item at the end of the list
        _items.add(item);
      }
      this.draggedIndex = null;
      hoverIndex = null;
    });
  }

  void onMove(DragTargetDetails<int> details) {
    final itemWidth = 64;
    // fine the dock (this box) in the screen
    final RenderBox box = context.findRenderObject() as RenderBox;

    /// Get the location of the pointer inside the dock,
    /// using the [details] we get from the onMove function
    final localPosition = box.globalToLocal(details.offset);

    /// Get dock width with content
    /// Add 1 to compensate for the item being dragged so last item gets full hover space

    final totalWidth = (itemWidth * _items.length + 1);

    /// Get starting point of the dock content
    final startX = (box.size.width - totalWidth) / 2;

    /// Get relative horizontal position by subtracting the starting point
    final relativeX = localPosition.dx - startX;

    /// Check if it's pointing before the first item
    if (relativeX < 0) {
      setState(() => hoverIndex = 0);

      /// Else check if it's pointing outside the totalWidth
    } else if (relativeX >= totalWidth) {
      /// Set it to the last item
      setState(() => hoverIndex = _items.length);
    } else {
      /// If not then it's between or on items.
      /// Get what particular item sectionit's on by dividing the
      /// current position of the pointer by the size of a an item.
      int index = (relativeX / itemWidth).floor();

      /// Check if item is going to be added to the left or
      /// to the right of the current item the pointer is pointing at
      final positionInItem = relativeX - (index * itemWidth);
      if (index == _items.length - 1 && positionInItem > itemWidth * 0.3) {
        index = _items.length;
      } else if (positionInItem > itemWidth / 2) {
        index++;
      }

      /// Clamp to valid range, so it is never out of bound
      index = index.clamp(0, _items.length);
      setState(() => hoverIndex = index);
    }
  }
}
