
Set up the demo.

Words are strings of characters in the range a-z.

    APISandbox.addClass 'Word', 'A string of characters',
        ( x ) -> typeof( x ) is 'string'
    APISandbox.addConstructor 'Add a word',
        ( word, environment ) ->
            environment[word] = word
            "Created this new word: #{word}."
    ,
        {
            name : 'the word to add'
            description : 'the word to add (e.g., "red" or "hamster")'
            type : 'string'
            validator : ( string ) ->
                if /^[a-zA-Z]+$/.test string
                    valid : yes
                else
                    valid : no
                    message : 'Only the letters a-z are allowed.'
        }

Numbers are like words, but using characters from 0-9.

    APISandbox.addClass 'Number', 'A string of digits',
        ( x ) -> typeof( x ) in [ 'string', 'number' ]
    APISandbox.addConstructor 'Add a number',
        ( number, environment ) ->
            environment[number] = parseInt number
            "Created this new number: #{number}."
    ,
        {
            name : 'the number to add'
            description : 'the number to add (e.g., 0 or 43782)'
            type : 'integer'
            min : 0
        }

    APISandbox.setup document.getElementById 'main-div'
