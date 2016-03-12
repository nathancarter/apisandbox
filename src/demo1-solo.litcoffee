
Set up the demo.

Words are strings of characters in the range a-z.

    APISandbox.addClass 'Word', 'A string of characters',
        ( x ) -> typeof( x ) is 'string' and /^[a-zA-Z]*$/.test x
    APISandbox.addConstructor 'Add a word',
        ( word, environment ) ->
            environment[word] = word
            "Created this new word: #{word}."
    ,
        name : 'the word to add'
        description : 'the word to add (e.g., "red" or "hamster")'
        type : 'string'
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
            environment[number] = parseInt number
            "Created this new number: #{number}."
    ,
        name : 'the number to add'
        description : 'the number to add (e.g., 0 or 43782)'
        type : 'integer'
        min : 0
        defaultValue : 1

This is rather a silly class, mostly for testing purposes, but I leave it
here to show how to use object-type parameters.

    APISandbox.addClass 'Number copy', 'A copy of a number',
        ( x ) -> typeof( x ) is 'string' and /^copy of [0-9]+$/.test x
    APISandbox.addConstructor 'Copy a number',
        ( number, environment ) ->
            environment["copy of #{number}"] = "copy of #{number}"
            "Copied this number: #{number}."
    ,
        name : 'the existing number to copy'
        description : 'this must be a number you\'ve already created'
        type : 'object:Number'

Set the whole system up, using the data above.

    APISandbox.setup document.getElementById 'main-div'
