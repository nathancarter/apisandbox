
Set up the demo.

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
    APISandbox.setup document.getElementById 'main-div'
