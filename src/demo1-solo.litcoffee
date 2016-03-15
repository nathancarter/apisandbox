
# API Sandbox Tiny Demo

This demo is "tiny" in the sense that the classes it defines are simple and
mostly uninsteresting.  They're only interesting if you're here to learn how
to define your own API Sandbox apps.  Note that this is the script code, but
[the page itself is here](../app/demo1.html).

[See the demo in action here.](
http://nathancarter.github.io/apisandbox/app/demo1.html)

This file assumes you've read [the intro](../README.md).  If you don't like
[CoffeeScript](http://www.coffeescript.org), you can see [this file's
JavaScript translation](
http://github.com/nathancarter/apisandbox/blob/gh-pages/app/demo1-solo.js),
but it does not contain these comments.

## Utility

In this tiny demo, we name objects with the names `A`, `B`, `C`, ..., `Z`,
`A1`, `B1`, ..., ad infinitum.  In more complex apps, you could allow the
user to choose their own naming convention.  But in this example, we keep it
simple for the user by assigning names when objects are created.  Thus we
need a function for auto-generating new names.  The following function finds
the first letter not used as a key in a given object.  This is not the most
interesting/relevant function in this demo; it's simply a necessity.

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

## The `Word` Class

Words are strings of characters in the range a-z.  We define a new class
by calling the `APISandbox.addClass` method.  It takes three parameters, the
class name, a short description of it, and a function that can detect
whether or not an object is in the class.  (The formal name for such a thing
is the "characteristic function" for the class.)

In this demo, we use plain old JavaScript strings as our objects, and
they're members of the `Word` class if they contain only upper and lower
case Roman letters.

    APISandbox.addClass 'Word', 'A string of characters',
        ( x ) -> typeof( x ) is 'string' and /^[a-zA-Z]*$/.test x

### The `Word` Constructor

In order for users to be able to create instances of our new class, we must
give them access to a constructor.  We register a constructor with the
`APISandbox` using the `addConstructor` method.  It takes two or more
parameters, the first being a phrase describing the action of constructing
the new thing (in this case "add a word") and the second being the function
that will be invoked when the user chooses this action and clicks "Apply."
Additional parameters to `addConstructor` define what kind of parameters the
constructor itself expects; more on this below.

That function you provide can take any number of parameters, and you get to
choose what those parameters are when registering the constructor.  The
`APISandbox` will automatically create a table in the UI into which the user
can enter the values of the parameters.  In this case, we'll ask the user
for just one parameter, the word itself.  We'll explain below how we specify
that.

Each constructor gets one additional parameter, the "environment."  This is
a (sort of) global object that is a dictionary from object names to objects
themselves.  You can manipulate it, and in fact constructors are expected
to, because they're making new objects, which better show up in the
environment.  It is this environment that the user is interactively
manipulating.

Constructors should return an HTML response that the user will see.  This
can be as simple as plain text, or as complex as a big DOM element with tons
of inner parts, events and event handlers, and so on.  In this case, we just
return a string saying we defined the new word.

    APISandbox.addConstructor 'Add a word',
        ( word, environment ) ->
            key = nextUnusedLetter environment
            environment[key] = word
            "Let #{key} stand for the word \"#{word}.\""
    ,

The remaining parameters to `addConstructor` are shown below, and in this
case there is only one.  Each is an object defining a parameter that the
constructor expects, and for which the UI must prompt the user.  These
parameter definitions take a name, description, type, and default value,
all of which are self-explanatory in the example below.

        name : 'the word to add'
        description : 'the word to add (e.g., "red" or "hamster")'
        type : 'string'
        defaultValue : 'example'

You can also optionally provide a validator, which is a function that will
be run every time the user tweaks the parameter in the input form.  This
validator must return an object with a "valid" member that's a boolean,
indicating whether the input is acceptable.  Optionally, it can also have a
"message" member that will be shown next to the input widget.  This is
essential for times when the input is invalid, to explain to the user what
they should fix.

In this example, we require words to be nonempty and use only the specific
character range mentioned earlier.

        validator : ( string ) ->
            if string.length is 0
                valid : no
                message : 'Words must have at least 1 letter.'
            else if /^[a-zA-Z]+$/.test string
                valid : yes
            else
                valid : no
                message : 'Only the letters a-z are allowed.'

One interesting thing to note about the `addConstructor` method:  You do not
need to say which class you're creating an instance of.  The system will
figure it out, using each class's characteristic function.

### `Word` Members

In order for a class to be interesting to interact with, it has to have some
methods, that is, things you can do with it.  You define these in exactly
the same way that you define constructors, with the exception that you must
specify the class in which the method belongs.  Thus you provide three
parameters, the class name, a phrase describing what the method does, and
the function that takes the action.

In the case of member functions, unlike constructors, the first parameter to
the function you provide will always be the string name of the object in
which the user is invoking the member function.  You can get the object
itself by looking it up, `environment[name]`, as shown below.  Other
parameters (if any) come after the object name and before the final
parameter, which is still the environment, as it was in the case of
constructors.

The following example member function takes no parameters, and just reverses
the word, altering its value in the environment, and reporting to the user
that it has done so.

    APISandbox.addMethod 'Word', 'reverse it',
        ( name, environment ) ->
            string = environment[name]
            reverse = ( string[string.length-1-i] \
                for i in [0...string.length] ).join ''
            environment[name] = reverse
            "Reversing #{name} gives #{reverse}.  Thus #{name} now stands
             for #{reverse}."

The following example member function takes no parameters, and just sorts
the letters the word into alphabetical order, altering its value in the
environment, and reporting to the user that it has done so.

    APISandbox.addMethod 'Word', 'sort its letters into alphabetical order',
        ( name, environment ) ->
            string = environment[name]
            array = ( string[i] for i in [0...string.length] )
            array.sort()
            environment[name] = array.join ''
            "Sorting the letters of #{name} into alphabetical order gives
             #{environment[name]}.  Thus #{name} now stands for
             #{environment[name]}."

The following example member function takes no parameters, and does not
alter the environment.  It just provides the user a link that her or she can
follow to look for a Wikipedia article with the word as its title.

    APISandbox.addMethod 'Word', 'look it up on Wikipedia',
        ( name, environment ) ->
            "Click <a target='_blank'
             href='http://en.wikipedia.org/wiki/#{environment[name]}'
             >here</a> to look up #{environment[name]} on Wikipedia."

## The `Number` Class

We create a second class, much like the first, except that it is for
non-negative whole numbers, instead of words.

    APISandbox.addClass 'Number', 'A string of digits',
        ( x ) -> typeof( x ) in [ 'string', 'number' ] and /^[0-9]+$/.test x

You can construct them by providing the number in ordinary base-10 arabic
numerals.  Note that "integer" is a built in type, and the system will
respect the "min" we provide.  It will provide feedback messages to the user
if he or she tries to enter a non-integer, or an integer less than zero.

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

We just provide one tiny method you can do with integers, squaring.  Note
that, unlike the destructive edits in the `Word` class, here we've elected
to just report the square rather than alter the environment.

    APISandbox.addMethod 'Number', 'compute its square',
        ( name, environment ) ->
            "Squaring #{name} gives #{environment[name]*environment[name]}.
             (But #{name} still continues to mean #{environment[name]}.)"

## Miscellany

It's also possible to pre-install some objects in the environment.  I call
them "globals" because they're always there.  I do not do so in this demo
app, but here is code you could use to install a global number named
`TheAnswer`, with value 42.  The second parameter is its description.

    # APISandbox.addGlobal 'TheAnswer', 'The answer to life, the universe,
    #     and everything', 42

Functions can also take object-type parameters.  Those parameters will be
passed, like the object itself, just as names.  You then look the object up
in the environment under the given name.  Although this demo app does not
have any such parameters, here is some example code that shows them in
action.  It defines a "Number copy" class that takes a number object as
input and creates a copy.

    # APISandbox.addClass 'Number copy', 'A copy of a number',
    #     ( x ) -> typeof( x ) is 'string' and /^copy of [0-9]+$/.test x
    # APISandbox.addConstructor 'Copy a number',
    #     ( name, environment ) ->
    #         key = nextUnusedLetter environment
    #         environment[key] = environment[name]
    #         "Let #{key} be a copy of #{name}, which is the number
    #          #{environment[name]}."
    # ,
    #     name : 'the existing number to copy'
    #     description : 'this must be a number you\'ve already created'
    #     type : 'object:Number'

## Setup

It is essential, after you define your classes and their methods, to call
the `APISandbox.setup` function.  Provide as its one parameter the DOM
element into which you want the UI placed.

    APISandbox.setup document.getElementById 'main-div'

The system also provides you DOM elements for creating permalinks and for
clearing the session.  If you want to place them anywhere, you can get them
with the `APISandbox.permalinkElement` and `APISandbox.clearElement`
functions.  Here, I place them in my title DIV.

    ( $ '#title-div' ).append APISandbox.permalinkElement()
    ( $ '#title-div' ).append ' &mdash; '
    ( $ '#title-div' ).append APISandbox.clearElement()

[See the demo in action here.](
http://nathancarter.github.io/apisandbox/app/demo1.html)
