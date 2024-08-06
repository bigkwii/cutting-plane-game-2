# Notes

I'm kinda forgetful, so this .md is here for me to save my thoughts and headspace into secondary storage.

## WED 2024-06-12

First things first, I need to figure out how to draw the lattice points and polygons. Godot has a _draw_polygon() function that can be used inside the _draw() function, so start experimenting with that when I get into actually implementing stuff.

So far, I've got the entire development environment set up, repo is up, kanban bakclog is... getting in shape. My goal at the moment is at the very, very least, implement bullet point 1 from the preliminar work plan, so being able to render a polygon and slice it with the different types of cutting planes from the original demo.

It doesn't *have* to look good yet, just be functional. That being said, I have a broad idea of the aesthetic I want to go for. **Vector graphics inspired**. Somewhere inbetween a 3blue1brown video and Superhexagon or Tempest.

I have until 2024-07-8 (final report deadline). Ideally, that report should be in a presentable shape by 2024-07-01.

Also, I know I'm pretty late to this, but this past month has been ROUGH. Hopefully I can keep up the pace.

Thankfully next week's recess. I'll have more time then. Even so, I should really get to implementing ASAP. Not today though, I'm very tired.

## THU 2024-06-13

As much as I would like to stay up late today doing research, I have a lot of work to do tomorrow morning, so I'll just mess around with Godot for a bit and then go to bed.

I've been messing around with the Godot draw functions and figured out some kinks already. Since I'm going for a vector graphics aesthetic I need to move away from rasterized images and use draw functions and SVG's. Luckily Godot 4 supports SVG's. I'm guessing any logos would have to be made with that in mind. Hell, I may end up making the logo in Godot itself.

...On second thought maybe I can work something out with shaders. I'll get there when I get there. For now, I need to focus on the basics. I'll see if I can programatically make the lattice points.

I need to start thinking about how to structure what a Polygon is. Naturally, A polygon will be a Node2D, right? I'm thinking that the list of points that make it up will all be children of that node. That way, I can make a Point Scene that will have it's own _draw() function in which I can draw a little circle. Seems like a good idea.

I'll start with that tomorrow. I'm going to do a bit of exercise now and then go to bed. I have important work to do in the morning.

## TUE 2024-06-18

So, it's been a few days. I haven't made much actual implementation, but I have decided a bunch of other stuff, such as art direction, and how I'm going to structure the project.

Also, The clock is ticking until 8th of July for the draft of the final report. I need to show the draft to my supervisor at that date at the very latest. The final report is due on the 15th of July. Lots to do. As for the actual game, on the report, I need to have *something* to show. This work should bw roughly equivalent to 35 hours of work. This means that I more or less need to work 2 hours a day on this project on average. I can totally do that. See you tomorrow.

## WED 2024-06-19

A few things of note:

- The original demo is 1024x768. For the first iteration, I'll keep that exact resolution, however, I have to make sure that other resolutions are supported in the future. I'll keep this in mind, but my goal right now is to replicate the original demo first, and then start changing things.
- Since we're dealing with 2 different types of coordinates (the in-game coords determined by the lattice grid, and the game coordinates, measured in pixels), I need to make sure that I have a way to convert between the two. A singleton could be a good idea? I could hard-code the conversions for now since I'm not going to change the resolution, but this is something to keep in mind for the future.
- Speaking of lattice points, how should those coords be layed out? i.e: where should (0,0) be? The player will never see the exact values for the lattice points, these is all eyeballed, and it ultimately doesn't matter, but a choice need to be made. The most intuitive place for (0,0) would probably be the bottom left corner, but Godot 2D coordinates have (0,0) at the top left corner. For simplicity, I'll keep it in the top left (y increasing downwards).
- I'm having second thoughts about the current stucture of things and the way I chose to draw things. Specifically for the lattice points. The Polygon and the Lattice grid must share the same coordinate system. Those nodes being siblings of the same parent node would be a good way to ensure that.
- Should the polygon itself have data about the points that make it up? Or should I go fetch that data from the child Point scenes? The ladder seems cleaner.

It's getting late, I'll continue tomorrow.

## THU 2024-06-20

A better name for the in-game coordinates would be good. I've been using simply `pos`. Maybe `lattice_position`? As in the position of a point relative to the lattice grid's origin? Seems about right.

I made a Debug autoload script so I don't have to look at the console everytime. I'll use it a lot, probably.

In order to change things that were drawn with the _draw() function, I need to call the queue_draw() function to reflect the changes. Keep that in mind.

I've also adjusted the spacing of the grid to match the demo. I probably won't keep it this way forever, but for the first iteration, again, I want to replicate the original demo as closely as possible (save for the aesthetic).

## FRI 2024-06-21

I'm starting super late today. I'm not planning to do much today, but I'll mess around with the Polygon. Let's see if I can build a Polygon from a list of points.

The experiment was a success. There are a few things of note:

- The lattice grid DIMENSION, SCALE_FACTOR and OFFSET may be better off as global constants. It would be a good idea to move them to an autoload script.
- Just so i don't forget, the order of execution is: load, init, ready, draw.

That's all for today. I'll be more productive tomorrow.

## SUN 2024-06-23

I didn't do any coding yesterday, but I did do some other miscellaneous stuff, such as taking a look at the way levels are structured in the original demo. I notices that the original's first column of lattice points actually corresponded to x=-1 for some reason. I'll have to keep that in mind when porting the levels, to +1 the x coordinate of each point.

Other than that, My system for creating polygons works as intended. Now it's time to cut them. I've been reading up on how to do this and there's about a gazillion ways I could go about it.

I'll continue tomorrow.

## MON 2024-06-24

What a day... I'll only be able to mess around for a bit today, it's already 2 AM. I'll try to make the simples possible slice of the polygon.

Also, I've been thinking, In the future, I may want to have levels with more lattice points. So, in order to accomodate for that, first of all, DIMENTIONS, SCALING_FACTOR and OFFSET should absolutely be in an autoload (or maybe, since this should be on a level per level basis, on the level scene?). Second, I need to be able to calculate the SCALING_FACTOR and OFFSET based on DIMENTIONS and the resolution of the game. I'll keep that in mind.

As for cutting... I have some ideas for experimenting. Note to self: Finish implementing them tomorrow.

## TUE 2024-06-25

First of all, for testing purposes, I implemented a way to calculate the polygon's centroid.

I've taken note that Godot has a bunch of functions for doing geometry, including calculating convex hulls and what not. The thing is, they don't use Arrays of Vector2's, they use PackedVector2Array. However, PackedVector2Array's are not too friendly for initializing a polygon from the editor. So, I'll have an export var Array of Vector2's for initializing, and a normal var PackedVector2Array that gets initialized on _ready(). I'll rename the vars accordingly (I needed to rename them anyway, the names were getting confusing).

I ended up not doing anything in regards to cutting the polygon. But, I did manage to calculate the convex hull of the polygon!

A lot was learned today.

For starters, the reason this was relatively easy to do was thanks to the Geometry functions Godot provides. But that raises some problems.

All the Geometry functions expect PackedVector2Array's. This isn't bad, I mean, the _draw functions expect this too, but, they come with a few limitations.

For example, I can't simply multiply a PackedVector2Array by a float or add (+) a Vector2 to it. This messes with the way I'm scaling things up from lattice coords to game coords. As a result, I need to convert to packed and unpacked depending on the operation.

Because of this, I'm starting to debate whether or not it's worth it to keep a packed copy of the polygon's points. It may be better to just convert to packed when needed. On the other hand, thay may lead to messier code. I'll have to think about it.

## WED 2024-06-26

I'm so eepy. So very eepy. I wanna go to bed. I'll just implement a node for the convex integer hull and the centroid, update the kanban, and go to bed.

It went well. REMEMBER TO MAKE THAT AUTOLOAD FOR THE CONSTANTS!!!

## MON 2024-07-01

It's been a while. This is the "final" week. As in, it may as well be the final week. Hoo boy...

First up, I'll make that autoload. I'll call it defaults.gd, since these constants will probably change at some point. For now, they get set on the variable definition. Change this to be done on _ready(), along with a check to see if a value was given on the editor (i.e: if set to -1, set to default value). !!! REMEMBER TO DO THIS LATER !!!

For now, let's take a look at that cutting logic.

Since this is all very experimental still, I'll use a test scene called test.tscn. After all of this goes well, I'll move on to actually making this in a way that makes sense and is scalable. This is why I'm not worrying about the way I'm setting the default values yet.

First up, let0's try to do a very simple cut. Let's click on the polygon and perform a horizontal split.

In order to do that, I started messing around with input events to get the mouse working. It's going well. Good thing I autoloaded those vars.

Also: consider changing the name of that autoload. Currently it's called defaults.gd, it may be better to call it utils.gd or simply global.gd, since I'm thinking I may need to add functions to it in the future.

Continuing tomorrow.

## TUE 2024-07-02

Time to cut. I'll try to click on the screen and make a horizontal cut at that height.

First of all, I need to be able to get the intersection between 2 lines. Godot's Geometry2D class has the function `line_intersects_line()`, however, it doesn't take start and end points, but a start point and a direction. I'll have to wrap this.

NEVERMIND! `segment_intersects_segment()` is what I need. I'm using that instead.

Not going well. The intersection is easy. But, rebuilding polygons correctly... I'll need to rethink this. The problems seems to be that some Geometry2D functions expect a polygon to be a closed loop, i.e: repeating the first point at the end. It seems some do, and other don't? It's very weird, I feel like I'm missing something. I'll continue tomorrow.

## WED 2024-07-03

Having a hard time concentrating right now. Lots of things to do and so little time.

There's lots to rethink. This will be my mission for tonight.

Good think I took a nap, my brain is working now. I found out that the issue I was having was that I wasn't getting rid of child nodes properly.

I can make cuts now, let's move on to better cuts.

Note: the code is starting to get ugly, but i'll just keep going as is for now. I'll make a big refactor after turning in the draft. I'm still doing everything in the "testing" folder after all.

Next, up, I've been using line segments this entire time, I'm I'm thinking that it would be better to use lines instead. Segments are determined by 2 points, while lines are determined by a point and a direction. Segments are generally better behaved, but lines are easier to work with in this case, since I get the point for free as any intersection point and the direction will can be determined more directly than choosing 2 arbitrary points. I'll try to make the switch.

One thing that's kinda annoying in Godot is that static return types can't be asigned as something that could be null (something like Vector2? or Vector2 | void). This could be a cool new feature in the future, but I've read that it's not currently planned. What a shame. Anyways, you can get around this by returning a Vector2 with an imposible value or just removing the return type. I'll do the latter for these kind of functions. Although I should rethink this, too.

Back to the changing to lines thing, it was a success. I'll continue tomorrow. G'night!

## THU 2024-07-04

I added a camera and added zooming and panning. I needed this to aid is testing precision when cutting. Speaking of, I found a bug, a cut won't be perfomed when the line is perfectly on top of a lattice line. ...Or so it seems. I'll investigate this further. I fixed it, I had a check to validate the amound of intersections a cut would make, and I was checking for exactly 2, when I should've been checking for != 0 and modulo 2 != 0. Actually, i'm not sure if the 2nd condition is necessary, but it's there for now.

With this, I should have a good base for implementing the types of cuts from the original demo. I'll start with the horizontal cut. I'll continue tomorrow morning.

Also, now that I can zoom in, I think the convex hull is slightly off (?) I'll have to investigate this further.

## FRI 2024-07-05

Alright, time to implement those cuts. Hopefully I can get them all done before sunday, that way I can brag about them on the draft.

It occurred to me that i still needed a bunch of stuff to aid in debugging and testing. I added a simple HUD, including a button for each cut, plus a debug cut button and line edit to choose a cut direction. I also added a button to show/hide the convex hull. That last one is in the original demo, of course. I ran into some issues when clicking the buttons, since clicking them also registered as clicking the screen, thus making a cut, I managed to patch this by checking if the pouse just clicked on top of the button container before making a cut. I'm honestly not to happy with that, all this has been implemented very hastily, but no worries, a big refactor is underway after the draft.

That's enough for today. Night!

## SAT 2024-07-06

Time to implement those cuts. Look, there's very little time left, and I probably won't have them all working by tomorrow, but I'll try to get as much work done as possible.

I got distracted and made an animation for the cut. It looks pretty good. I think this is a good way of making animations. I expect to make most if not all animations the same way in the future.

I'm starting to think what I have is impressive enough for a draft. I'll keep going for a little bit anyways, it would be cool to at least have the horizontal and vertical cuts done. Gomory is considerably more difficult to implement, anyways, since, for one, the implementation is pretty confusing, and for two, I need to implement clickable hitboxes for the vertices of the polygon.

Ok so i found a strange bug, if you keep spamming the click button at the same exact spot, weird things start happening. A cut keeps being made on each click even tho we're right on the edge of the polygon, the centroid starts shifting away, and sometimes the cut (which is usually a cut that doesn't do anything) will actually cut the polygon diagonally for no apparent reason. Very strange. Grantes, this shouldn't be a problem if you only use the actual cuts, the only way this could happen is with the debug cut, since that's the only one that allows you to click on the same spot multiple times, but this merits being fixed. I'll look into it.

I managed to patch this by being less strict when checking the number of intersections. Instead of checking for exactly 0 when determining when not to cut, I'm checking for <= 2. Apparently, when a cut is colinear, `line_intersects_line()` will spit out exactly 1 intersection point. What is that point? It seems to be kinda unpredictable, probably has something to do with the order in which the lines are passed and there may or may not be funky floating point arithmetic badness going on. Either way, avoiding such cases is good practice regardless. I can still sometimes keep clicking on the same spot and perform multiple cuts that do nothing, seems to be a float thing. I'll see what I can do.

Ok so, whenever this bug happens, split_polygon, which spits out the 2 the same exact polygon, unchanged, plus a polygon that really isn't a polygon at all, but an infinitely small line segment mascarading as a polygon. An area check should fix this.

Easy, tho I needed to implement a function to calculate the area of a polygon. Noted for the refactor.

The cuts themselves... have proven to be pretty difficult. I'll just leave them as TODO's. I need to move on to the draft. Sad day.

## MON 2024-08-05

I'm back. The draft was a success, development has officially resumed. First things first, I need to refactor this mess. There's typos to fix, comments to add, things to move around and directories to reorganize.

The test.gd scene should be used as a base for the level scene. And most of it's logic should be moved to the Polygon scene. That'll be the first step.
