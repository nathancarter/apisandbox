
# API Sandbox Tiny Demo

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

    APISandbox.addClass 'Word', 'A string of characters',
        ( x ) -> typeof( x ) is 'string' and /^[a-zA-Z]*$/.test x
    APISandbox.addConstructor 'Add a word',
        ( word, environment ) ->
            key = nextUnusedLetter environment
            environment[key] = word
            "Let #{key} stand for the word \"#{word}.\""
    ,
        name : 'the word to add'
        description : 'the word to add (e.g., "red" or "hamster")'
        type : 'string'
        defaultValue : 'example'
        validator : ( string ) ->
            if string.length is 0
                valid : no
                message : 'Words must have at least 1 letter.'
            else if /^[a-zA-Z]+$/.test string
                valid : yes
            else
                valid : no
                message : 'Only the letters a-z are allowed.'

Numbers are like words, but using characters from 0-9.

    APISandbox.addClass 'Number', 'A string of digits',
        ( x ) -> typeof( x ) in [ 'string', 'number' ] and /^[0-9]+$/.test x
    APISandbox.addConstructor 'Add a number',
        ( number, environment ) ->
            key = nextUnusedLetter environment
            environment[key] = parseInt number
            "Let #{key} stand for the number #{number}."
    ,
        name : 'the number to add'
        description : 'the number to add (e.g., 0 or 43782)'
        type : 'integer'
        min : 0
        defaultValue : 1
    APISandbox.addMethod 'Number', 'compute its square',
        ( name, environment ) ->
            "Squaring #{name} gives #{environment[name]*environment[name]}."

This is rather a silly class, mostly for testing purposes, but I leave it
here to show how to use object-type parameters.

    APISandbox.addClass 'Number copy', 'A copy of a number',
        ( x ) -> typeof( x ) is 'string' and /^copy of [0-9]+$/.test x
    APISandbox.addConstructor 'Copy a number',
        ( name, environment ) ->
            key = nextUnusedLetter environment
            environment[key] = environment[name]
            "Let #{key} be a copy of #{name}, which is the number
             #{environment[name]}."
    ,
        name : 'the existing number to copy'
        description : 'this must be a number you\'ve already created'
        type : 'object:Number'

Set the whole system up, using the data above.

    APISandbox.setup document.getElementById 'main-div'
