
# API Sandbox Dice Demo

If you have not yet read [the tiny demo](demo1-solo.litcoffee), you should
start there first.  This file is very similar to that one, and anything they
have in common is not re-explained here.  Note that this file is the script
code, but [the page itself is here](../app/demo2.html).

I repeat here the `nextUnusedLetter` function from the tiny demo; see that
file for more information.

    nextUnusedLetter = ( object ) ->
        letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        index = 0
        suffix = 0
        candidate = ->
            "#{letters[index]}#{if suffix > 0 then suffix else ''}"
        while candidate() of object
            index++
            if index is letters.length
                index = 0
                suffix++
        candidate()

## The `handful` class

In this demo, the user can create "handfuls" of dice, and then roll them
repeatedly, creating histograms of the sums rolled.  Because this demo is
so small, it only has one class, so we can guarantee that any object in the
environment is an instance of this class; thus the characteristic function
can just say yes to everything.

    APISandbox.addClass 'handful', 'A handful of dice',
        ( x ) -> yes

## The `handful` constructor

When constructing a handlful of dice, you simply say how many dice you want
in your handful (an integer from 1 to 20).

    APISandbox.addConstructor 'Take a new handful of dice',
        ( count, environment ) ->
            key = nextUnusedLetter environment
            environment[key] = count
            "Let #{key} represent a handful of #{count} six-sided dice."
    ,
        name : 'how many dice in the handful'
        description : 'an integer number of dice, from 1 to 20'
        type : 'integer'
        min : 1
        max : 20
        defaultValue : '3'

## The `handful` methods

There are two methods you can do with a handful of dice.  You can look at
them, and you can roll them.  Both return SVGs showing pictures, the former
of a set of dice, the latter of a histogram of the rolls.  We use
[SnapSVG](http://snapsvg.io/) to create the SVGs.

    APISandbox.addMethod 'handful', 'show a picture of it',
        ( name, environment ) ->

This function, like the member functions in [demo 1](demo1.litcoffee), takes
no parameters other than the object itself and the environment.  But it
differs from functions in [demo 1](demo1.litcoffee) in that it does not
return text (which the system converts into DOM elements) but it returns DOM
elements itself.

We begin by creating a DIV into which we will place a paragraph and an SVG.

            result = document.createElement 'div'
            result.innerHTML = "<p>Your #{environment[name]} dice might look
                like this, if you arranged them neatly.</p>"

You can ignore most of the following code unless you're interested in
learning [SnapSVG](http://snapsvg.io/).  It creates a picture of a row of
dice, storing it in the `Snap` object named `svg`.

            count = environment[name]
            size = 70
            svg = new Snap size*count, size
            r = 0.5*size
            [ c, s ] = [ 0.7071*r, 0.5*r ]
            interp = ( a, b, t ) -> (1-t)*a + t*b
            dots = ( x1, y1, x2, y2, n ) ->
                for j in [1..n]
                    t = j/(n+1)
                    svg.circle( interp( x1, x2, t ),
                                interp( y1, y2, t ), 2 )
                        .attr stroke : 'none', fill : 'black'
            for i in [0...count]
                [ x, y ] = [ size*i+size/2, size/2 ]
                die = svg.polyline x, y, x-c, y-s, x, y-r, x+c, y-s,
                    x+c, y+s, x, y+r, x-c, y+s, x-c, y-s, x, y, x+c, y-s,
                    x, y, x, y+r
                die.attr stroke : 'black', fill : 'none'
                dots x, y, x+c, y+s, 1
                dots x-c, y-s, x, y+r, 2
                dots x-c, y-s, x+c, y-s, 3

Finally, we place that object after the paragraph whose code appears above,
and return the containing DIV.  It will be placed into the document, as the
visible result of the function the user invoked.

            svg.insertAfter result.childNodes[0]
            result

The other method of a handful of dice is to roll them.  This method does
take a parameter, the number of times the user wishes to roll the dice.

    APISandbox.addMethod 'handful', 'roll the dice',
        ( name, numRolls, environment ) ->

Notice the `numRolls` parameter above, between the object name and the
environment.

The following code rolls the dice the specified number of times, creating an
object called `result` that stores the histogram data.

            rollOne = -> 1 + Math.floor Math.random()*6
            numDice = environment[name]
            roll = ->
                result = 0
                result += rollOne() for i in [1..numDice]
                result
            result = { }
            for r in ( roll() for i in [1..numRolls] )
                result[r] = ( result[r] ? 0 ) + 1
            min = numDice
            max = numDice*6
            maxCount = 0
            for own r, count of result
                maxCount = Math.max maxCount, count

The following code creates the SVG of the histogram.  Again, unless you want
to learn this particular graphics toolkit, most of this can be ignored.

            barWidth = 30
            height = 100
            textHeight = 30
            mar = 2
            svg = new Snap barWidth*( max - min + 1 ), height+textHeight*2
            for i in [min..max]
                barHeight = height*( result[i] ? 0 )/maxCount + 1
                x = barWidth*(i-min)
                svg.rect( x+mar, textHeight+height-barHeight,
                    barWidth-2*mar, barHeight ) \
                    .attr fill : '#aaf', stroke : '#00a'
                svg.text x+3*mar, textHeight+height-barHeight-3,
                    result[i] ? '0'
                svg.text x+3*mar, height+textHeight*2, i

Here we create the DIV we will return to the user, place an introductory
paragraph into it, then place the SVG after that paragraph.  Return the DIV.

            div = document.createElement 'div'
            div.innerHTML = "<p>Here is a histogram showing the results of
                all #{numRolls} rolls of the #{numDice} dice in handful
                #{name}.  Each roll was treated as the sum of the #{numDice}
                numbers rolled.</p>"
            svg.insertAfter div.childNodes[0]
            div
        ,

The second, third, fourth, etc. parameters to `addMethod` specify any
parameters the method takes.  In this case, it takes one, how many times
to roll the dice.

            name : 'how many times to roll the dice'
            description : 'an integer number of rolls, from 1 to 1000'
            type : 'integer'
            min : 1
            max : 1000
            defaultValue : 100

## Setup

The setup, permalink, and clear code is the same as it was in
[demo 1](demo1.litcoffee).  Refer there for documentation on this code.

    APISandbox.setup document.getElementById 'main-div'
    ( $ '#title-div' ).append APISandbox.permalinkElement()
    ( $ '#title-div' ).append ' &mdash; '
    ( $ '#title-div' ).append APISandbox.clearElement()
