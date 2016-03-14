
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

    APISandbox.addClass 'Handful', 'A handful of dice',
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
    APISandbox.addMethod 'Handful', 'show a picture of it',
        ( name, environment ) ->
            "This is a placeholder message.  Later there will be a picture
             here of the #{environment[name]} dice in handful #{name}."
    APISandbox.addMethod 'Handful', 'roll the dice',
        ( name, iterations, environment ) ->
            "This is a placeholder message.  Later there will be a
             histogram showing the results of all the #{iterations} rolls
             of the #{environment[name]} dice in handful #{name}."
        ,
            name : 'how many times to roll the dice'
            description : 'an integer number of rolls, from 1 to 1000'
            type : 'integer'
            min : 1
            max : 1000
            defaultValue : 20

Set the whole system up, using the data above.

    APISandbox.setup document.getElementById 'main-div'

Append permalink and clear buttons to the title div.

    ( $ '#title-div' ).append APISandbox.permalinkElement()
    ( $ '#title-div' ).append ' &mdash; '
    ( $ '#title-div' ).append APISandbox.clearElement()
