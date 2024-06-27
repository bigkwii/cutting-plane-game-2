# Notes

I'm kinda forgetful, so this is to save my thoughts and headspace into secondary storage.

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
- Just so i don't forget, the order of execution is: load(), _init(), _ready(), _draw().

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
