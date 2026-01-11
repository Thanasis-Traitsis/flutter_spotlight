# Creating Spotlight Tutorials in Flutter: The Complete Guide to Selective Overlays

![Header](https://github.com/Thanasis-Traitsis/flutter_spotlight/blob/main/assets/spotlight_dashboard.png?raw=true)
Hello there, my Flutter friends! Recently, I downloaded an app and, when I opened it for the first time, I noticed this cool feature that many apps use to guide new users through their core functionality. You know what I am talking about: a button gets highlighted, the rest of the screen fades out, and your attention is drawn exactly where the developer wants it to be. This kind of **spotlight onboarding** is everywhere, and that’s when I had my “Eureka” moment!

That’s what this blog is all about. We’ll build this exact effect in Flutter, step by step, and use it as an opportunity to deeply understand how Flutter handles rendering, painting, and widget positioning under the hood.

## The UI Setup
I want to keep the UI as simple as possible. We’ll start with a clean home screen that contains just a few buttons. The ones we’re going to highlight, and one extra button that will trigger the highlight effect. Yes, we’ll manually turn the effect on and off. You don’t expect me to build a full onboarding system from scratch… do you? You can find all the code you need from the github repository at the end of this article.

<img src="https://github.com/Thanasis-Traitsis/flutter_spotlight/blob/main/assets/home_screen.png?raw=true" alt="Home Screen" width="300" height="auto">

## The Highlight Effect
Now it’s time for the interesting part. How do we "remove" the color from the entire screen, while keeping specific widgets fully visible? The answer is simple: **we don’t remove anything**. Instead, we are going to add something on top.

To achieve this effect, we introduce an extra layer that sits above our existing UI. This layer acts as a semi-transparent overlay, covering the whole screen and dimming everything underneath. The key trick, however, is that this overlay is not solid. We intentionally “cut out” specific areas that line up with the widgets we want to highlight.

<img src="https://github.com/Thanasis-Traitsis/flutter_spotlight/blob/main/assets/layers.png?raw=true" alt="Layers" width="450" height="auto">

### How does this effect work?
We add a full-screen overlay on top of our screen and paint it with a dark color and some opacity. This allows the underlying UI to remain visible, but visually de-emphasized. Then, for each widget we want to spotlight, we carve a transparent hole in that overlay, positioned exactly where the widget appears on the screen.

As a result:
- The background content fades into the dark overlay
- The highlighted widgets remain completely clear and untouched
- The user’s attention is naturally drawn to the important elements

![Overlay Steps](https://github.com/Thanasis-Traitsis/flutter_spotlight/blob/main/assets/overlay_steps.png?raw=true)

Nothing from the original UI is modified or removed. The entire effect is purely visual and lives in its own layer, which makes it both powerful and flexible. Now that we have a clear picture of what we want to achieve, it’s time to start building it.

### The Overlay Layer
Before we dive into anything fancy, we need a solid foundation. The first step is to create a reusable screen widget that we can use across the app. Nothing special here, just a simple `Scaffold` with some padding and a `SafeArea` to keep things clean.
```
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
```
At this point, we have a perfectly normal screen. Now comes the important question:
*How do we place something on top of it without touching the existing UI?*

This is where the `Stack` widget comes in. Stack lets us layer widgets on top of each other (like layers in Photoshop). The first child is the bottom layer, subsequent children stack on top. Here’s how our updated `CustomScreen` looks:

```
class CustomScreen extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  final List<GlobalKey>? highlightWidgetKeys;
  final VoidCallback? onOverlayTap;
  final HighlightStyle? highlightStyle;

  const CustomScreen({
    super.key,
    required this.child,
    this.showOverlay = false,
    this.highlightWidgetKeys,
    this.onOverlayTap,
    this.highlightStyle,
  });

  bool get _shouldShowOverlay =>
      showOverlay &&
      highlightWidgetKeys != null &&
      highlightWidgetKeys!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
        if (_shouldShowOverlay)
          Positioned.fill(
            child: _SelectiveOverlay(
              widgetKeys: highlightWidgetKeys!,
              onDarkAreaTap: onOverlayTap,
              style: highlightStyle ?? const HighlightStyle(),
            ),
          ),
      ],
    );
  }
}
```
A few important things are happening here:
- The `Stack` allows us to layer widgets on top of each other
- The `Scaffold` remains untouched and behaves exactly as before
- The overlay is rendered only when needed, controlled by _shouldShowOverlay
- Positioned.fill ensures the overlay covers the entire screen

Now, let’s look at some of the more interesting parts of this implementation.

#### Highlighting specific widgets
You’ll notice that we pass a variable called **highlightWidgetKeys**. This is a list of `GlobalKey`s that correspond to the widgets we want to highlight. Since we may want to spotlight more than one widget at a time, we use a List.

**Why GlobalKeys?**
GlobalKeys are special identifiers in Flutter that let us access a widget's `RenderObject` (the actual painted object on screen) and its position. Without them, we couldn't know where to "cut holes" in the overlay.

#### Styling the highlights
You’ll also notice that we pass a `HighlightStyle` object into our overlay. This is a small but important design choice.

Instead of hardcoding colors, padding, and border radius inside our rendering logic, we extract all styling concerns into a dedicated class. This keeps our code clean, reusable, and much easier to maintain.
```
class HighlightStyle extends Equatable {
  final Color overlayColor;
  final double borderRadius;
  final double padding;

  const HighlightStyle({
    this.overlayColor = Colors.black54, // Opacity for the overlay layer
    this.borderRadius = 12.0, // Rounded corners for highlighted areas
    this.padding = 8.0, // Extra spacing around highlighted widgets
  });

  @override
  List<Object?> get props => [overlayColor, borderRadius, padding];
}
```

At this stage, we’re not drawing anything yet. We’re simply preparing the screen to host a visual layer that can sit above the UI and react to user interactions independently.

In the next section, we’ll see how this overlay actually draws itself and how it knows where to create those transparent “holes” on the screen.

### How does Flutter go from widgets to pixels?

Before we dive into the nitty-gritty of custom painting and hit testing, we need to understand an important bridge in Flutter's architecture. You see, Flutter has a beautiful separation of concerns that says **widgets describe what you want**, while **RenderObjects do the actual work**.

Think of it this way: widgets are like blueprints, and RenderObjects are the construction workers that build from those blueprints. Most of the time, Flutter handles this translation automatically. But when we need custom behavior *'like our selective overlay'* we need to create this bridge ourselves.
```
class _SelectiveOverlay extends SingleChildRenderObjectWidget {
  final List<GlobalKey> widgetKeys;
  final HighlightStyle style;
  final VoidCallback? onDarkAreaTap;
```
**`SingleChildRenderObjectWidget`** is our bridge. It's a special type of widget that says: *"I'm going to create my own custom RenderObject to handle the heavy lifting."* 

Our `_SelectiveOverlay` widget is quite simple. It holds three pieces of configuration:
- **widgetKeys:** The list of GlobalKeys pointing to widgets we want to highlight
- **style:** Our `HighlightStyle` object containing colors, padding, and border radius
- **onDarkAreaTap:** An optional callback for when users tap the dark overlay area

#### The createRenderObject Method
```
@override
RenderObject createRenderObject(BuildContext context) {
  return _RenderSelectiveOverlay(
    widgetKeys: widgetKeys,
    style: style,
    onDarkAreaTap: onDarkAreaTap,
  );
}
```
This is where the magic starts. When Flutter builds our widget tree and encounters `_SelectiveOverlay`, it calls **createRenderObject()**. This method's job is simple: create the RenderObject that will do the actual painting and hit testing.

Think of this like a factory pattern. The widget is the factory, and it produces a worker (the RenderObject) that knows how to do the job. This separation is crucial because **widgets are rebuilt frequently (they're cheap and immutable)**, but RenderObjects stick around and do the **expensive work** like layout, painting, and hit testing.

#### The updateRenderObject Method
Here's where things get interesting. Remember how I said widgets are rebuilt frequently? Well, we don't want to throw away and recreate our RenderObject every time, that would be wasteful. Instead, Flutter is smart! When our widget rebuilds with new data, it calls updateRenderObject() to pass the new configuration to the existing RenderObject.
```
@override
void updateRenderObject(
  BuildContext context,
  _RenderSelectiveOverlay renderObject,
) {
  renderObject
    ..widgetKeys = widgetKeys
    ..style = style
    ..onDarkAreaTap = onDarkAreaTap;
}
```
This is Flutter's optimization in action. We're essentially saying: *"Hey, RenderObject, here's your updated configuration. If anything changed, you'll need to repaint."*

#### Why This Architecture Matters
Now the real question is: "Why do we need all that? Couldn't we just use `CustomPaint` like usual?" Fair question! Well, we could use `CustomPaint` for the drawing part, but we'd still struggle with the hit testing. By going down to the `RenderObject` level, we get complete control over both painting and how taps are handled. This is the secret sauce that lets us create "holes" in our overlay that pass taps through to the buttons underneath.

This widget layer is lightweight and declarative, it just describes what we want. The real heavy lifting happens in the `_RenderSelectiveOverlay` class, which we're about to explore. 

### The Heart of the System: Understanding RenderBox
Now we're getting to the exciting part, the **`_RenderSelectiveOverlay`** RenderBox. This is where all the painting, the hit testing, and the performance optimizations happens, that make our overlay silky smooth. Don't worry if this looks intimidating at first. We'll break it down piece by piece, and by the end, you'll understand exactly how Flutter's rendering engine works under the hood.

#### Setting Up Our RenderBox
```
class _RenderSelectiveOverlay extends RenderBox {
  List<GlobalKey> _widgetKeys;
  HighlightStyle _style;
  VoidCallback? _onDarkAreaTap;

  _RenderSelectiveOverlay({
    required List<GlobalKey> widgetKeys,
    required HighlightStyle style,
    VoidCallback? onDarkAreaTap,
  }) : _widgetKeys = widgetKeys,
       _style = style,
       _onDarkAreaTap = onDarkAreaTap;

  List<GlobalKey> get widgetKeys => _widgetKeys;
  set widgetKeys(List<GlobalKey> value) {
    if (_widgetKeys == value) return;
    _widgetKeys = value;
    markNeedsPaint(); // Trigger the rebuild of the Overlay
  }

  HighlightStyle get style => _style;
  set style(HighlightStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint(); // Trigger the rebuild of the Overlay
  }

  VoidCallback? get onDarkAreaTap => _onDarkAreaTap;
  set onDarkAreaTap(VoidCallback? value) {
    _onDarkAreaTap = value; // No need for visual rebuild
  }
```
Our RenderBox extends Flutter's RenderBox class, which is the base for all 2D rectangular rendering. We store three private fields that hold our configuration. But here's the thing, we need to be smart about how they're updated.

These getters and setters are doing something clever. When **updateRenderObject()** passes new values from the widget layer, these setters spring into action. First, they check: "Is this actually a new value?" If the value hasn't changed, **we bail out early**. There is no point in doing unnecessary work.

But if the value has changed, we update the field and then call **markNeedsPaint()**. This is our way of telling Flutter: "Hey, something visual changed! You need to repaint me on the next frame." Without this call, you could change the highlighted buttons or overlay color, and nothing would happen on screen. The data would update, but the pixels wouldn't!

#### Defining Our Size
```
@override
bool get sizedByParent => true;

@override
Size computeDryLayout(BoxConstraints constraints) {
  return constraints.biggest;
}
```
Here's a cool Flutter optimization. By returning **true** from `sizedByParent`, we're telling Flutter: *"My size depends only on my constraints, not on my children or any other factors."* This allows Flutter to skip some expensive layout calculations.

The `computeDryLayout` method then says: "Give me the biggest size you'll allow." Since we're using `Positioned.fill` in our widget tree, we want to cover the entire screen, so we take up all available space. The term "dry layout" means we're calculating size without any side effects, pure calculation.

#### The Paint Method: Creating Holes in the Darkness
Now for the main event, **the painting logic**. This is where we create that dark overlay with transparent holes for our highlighted widgets.
```
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final size = this.size;

    final paint = Paint()
      ..color = _style.overlayColor
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
```

First, we grab the canvas (our drawing surface) and set up our paint brush. The `Paint` object is like configuring a real paintbrush. We're saying "use this color" and "fill shapes completely" (not just stroke their outlines). Here's where it gets clever. We start by creating a `Path` and adding a rectangle that covers the entire screen. At this point, if we drew this path, we'd have a solid overlay blocking everything. But we're not done yet!

#### Looping through highlighted Widgets
```
for (final key in _widgetKeys) {
  final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  
  if (renderBox == null || !renderBox.attached) continue;
```
Now we loop through each GlobalKey pointing to a widget we want to highlight. For each key, we try to get its **RenderObject**. The null check (`renderBox == null`) handles cases where the widget hasn't been built yet, and the `attached` check prevents crashes if the widget is being removed from the tree. This is defensive programming at its best, we're handling edge cases that could occur during animations, page transitions, or rapid rebuilds.
```
final position = renderBox.localToGlobal(Offset.zero);
  final widgetSize = renderBox.size;

  final widgetRect = Rect.fromLTWH(
    position.dx - (_style.padding / 2),
    position.dy - (_style.padding / 2),
    widgetSize.width + _style.padding,
    widgetSize.height + _style.padding,
  );

  path.addRRect(
    RRect.fromRectAndRadius(
      widgetRect,
      Radius.circular(_style.borderRadius),
    ),
  );
}
```
For each widget we want to highlight, we need to know: "Where is it on the screen?" and "How big is it?" The `localToGlobal(Offset.zero)` call converts the widget's local **top-left corner (0, 0)** to global screen coordinates. Then we create a rectangle that's slightly larger than the widget itself. That's our padding creating a visual "breathing room" around the highlighted area. Finally, we add each highlighted area to our path as a rounded rectangle. 

<img src="https://github.com/Thanasis-Traitsis/flutter_spotlight/blob/main/assets/local_to_global.png?raw=true" alt="Corner Offset" width="600" height="auto">

#### The final touch
```
path.fillType = PathFillType.evenOdd;
canvas.drawPath(path, paint);
```
This is the moment everything comes together! The **`PathFillType.evenOdd`** is the secret that creates our holes. Here's how it works: imagine drawing a line from outside the screen to any point. Count how many times that line crosses a shape boundary. If the count is odd, fill that area. If it's even, leave it empty.

So for our overlay:
- Points outside everything: 1 crossing (the screen rectangle) = odd = filled ✓
- Points inside a highlighted area: 2 crossings (screen + highlight) = even = empty ✓

It's like magic, but it's just clever math! This single line is what creates those transparent "holes" in our dark overlay.

#### Hit Testing: Making the Magic Interactive
The painting makes things look right, but we still need to make them behave right. When a user taps the screen, how do we decide what happens?
```
@override
bool hitTest(BoxHitTestResult result, {required Offset position}) {
  for (final key in _widgetKeys) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox == null || !renderBox.attached) continue;

    final widgetPosition = renderBox.localToGlobal(Offset.zero);
    final widgetSize = renderBox.size;

    final rect = Rect.fromLTWH(
      widgetPosition.dx - (_style.padding / 2),
      widgetPosition.dy - (_style.padding / 2),
      widgetSize.width + _style.padding,
      widgetSize.height + _style.padding,
    );

    if (rect.contains(position)) {
      return false;
    }
  }
```
Flutter's hit testing works from top to bottom in the widget tree. When our overlay's `hitTest` is called, we check: "Did the user tap inside any of our highlighted areas?" Notice we're using the same rectangle calculation as our paint method. **This consistency is crucial.** The visual holes and the interaction holes must match perfectly.
If the tap is inside a highlighted area, we return **false**. This is our way of saying: "Nope, I'm not handling this tap. Let it pass through to the widget underneath!" This is what makes the buttons still work even though there's an overlay on top of them.
```
if (size.contains(position)) {
    _onDarkAreaTap?.call();
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  return false;
}
```
But if the tap is in the dark overlay area (not in any highlighted region), we handle it ourselves. We call the callback (if one was provided), add ourselves to the hit test result, and return **true** to stop the hit test from continuing to widgets below.

The final return **false** is a safety net for taps that somehow fall outside our bounds—though in practice, this shouldn't happen since we fill the entire screen.

## The Conclusion
And that’s pretty much it! We started with a simple UI and gradually built our way up from a basic `Stack` to a fully custom overlay powered by `RenderBox` and `Paint`. Along the way, we explored how Flutter moves from widgets to pixels, how to locate widgets on the screen using **GlobalKeys**, and how to draw directly on the canvas to create that spotlight effect.

More importantly, we took a look under the hood. We didn’t just use Flutter’s rendering system, we learned how it works. From layering widgets, to custom painting, to controlling hit testing, every piece of this solution shows how flexible Flutter can be when you need to go beyond standard widgets. To be honest, this kind of approach isn’t something you’ll need every day, but when you do (like onboarding flows, tutorials, coach marks, or any kind of custom visual effect ), understanding the rendering pipeline makes all the difference. Hopefully, this article gave you both a practical feature you can reuse and a deeper appreciation of how Flutter actually draws things on the screen.

If you enjoyed this article and want to stay connected, feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/thanasis-traitsis/).

If you'd like to dive deeper into the code and contribute to the project, visit the repository on [GitHub](https://github.com/Thanasis-Traitsis/flutter_spotlight).

Was this guide helpful? Consider buying me a coffee!☕️ Your contribution goes a long way in fuelling future content and projects. [Buy Me a Coffee](https://www.buymeacoffee.com/thanasis_traitsis).

As always, feel free to experiment, tweak the code, and make it your own. Happy coding, Flutter friends!