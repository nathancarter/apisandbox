
# API Sandbox Dice Demo

This function finds the first letter not used as a key in a given object.

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

Words are strings of characters in the range a-z.

    APISandbox.addClass 'handful', 'A handful of dice',
        ( x ) -> yes # it's the only class in this demo so x is an instance!
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
    APISandbox.addMethod 'handful', 'show a picture of it',
        ( name, environment ) ->
            result = document.createElement 'div'
            result.innerHTML = "<p>Your #{environment[name]} dice might look
                like this, if you arranged them neatly.</p>"
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
            svg.insertAfter result.childNodes[0]
            result
    APISandbox.addMethod 'handful', 'roll the dice',
        ( name, numRolls, environment ) ->
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
            div = document.createElement 'div'
            div.innerHTML = "<p>Here is a histogram showing the results of
                all #{numRolls} rolls of the #{numDice} dice in handful
                #{name}.  Each roll was treated as the sum of the #{numDice}
                numbers rolled.</p>"
            svg.insertAfter div.childNodes[0]
            div
        ,
            name : 'how many times to roll the dice'
            description : 'an integer number of rolls, from 1 to 1000'
            type : 'integer'
            min : 1
            max : 1000
            defaultValue : 100

Set the whole system up, using the data above.

    APISandbox.setup document.getElementById 'main-div'

Append permalink and clear buttons to the title div.

    ( $ '#title-div' ).append APISandbox.permalinkElement()
    ( $ '#title-div' ).append ' &mdash; '
    ( $ '#title-div' ).append APISandbox.clearElement()
