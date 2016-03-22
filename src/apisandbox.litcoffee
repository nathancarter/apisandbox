
# API Sandbox

    window.APISandbox = { }

Documentation to come later.

## Command class

    APISandbox.Command = Command = class Command

In the constructor, the object name is a string, matching the name in an
environment, the method is an actual function to call to execute the
command, and the parameters array has entries of one of the following two
forms.
 * `{ name : 'object name' }`
 * `{ value : atomic or JSON }`

For a constructor command, set the object name to null.

        constructor : ( @objectName, @method, @parameters... ) ->
            # no other actions necessary

Apply the command to a state with the following function, which creates a
new state.  (The `State` class is defined below.)

        apply : ( state ) =>

Duplicate the old state, then modify it by using the method stored in this
command.  Return the result.  Note that the last parameter passed is always
the environment, so that the method may choose to ignore it, or use it if it
needs to modify it (which most won't).

            result = state.copy()
            result.command = @
            if result.environment is null
                result.environment = state.environment
                state.environment = null
            parameters = for parameter in @parameters
                if 'name' of parameter
                    state.environment[parameter.name]
                else
                    parameter.value
            parameters.push result.environment
            if @objectName? then parameters.unshift @objectName

If the object we're about to invoke this on doesn't exist anymore, say so.
Otherwise, run the function as expected.

            element = if @objectName and \
                         @objectName not of result.environment
                "This command was formerly run on #{@objectName}, which no
                 longer exists due to changes made up above."
            else
                @method.apply null, parameters

Upgrade the result to an element, if it wasn't one already, and return it.

            if element not instanceof window.Node
                div = APISandbox.div.ownerDocument.createElement 'div'
                div.innerHTML = "#{element}"
                element = div
            div = APISandbox.div.ownerDocument.createElement 'div'
            div.setAttribute 'class', 'command-result'
            div.appendChild element
            result.element = div
            result

Commands can also look themselves up in the global `APISandbox` data
structure, to find out their names, as either methods or constructors.

        constructorName : =>
            for own phrase, data of APISandbox.data.constructors ? { }
                if data.call is @method
                    return phrase
            return null
        methodName : =>
            for own className, bigdata of APISandbox.data.members ? { }
                for own phrase, data of bigdata
                    if data.call is @method
                        return className : className, phrase : phrase
            return null

## State class

    APISandbox.State = State = class State

In the constructor, command is the command that transitioned here to create
this state, an object of type `Command` (or null iff this is the initial
state).

The environment is a map from names to objects.  Only key-value pairs whose
values satisfy some class's characteristic function will be visible to end
users, but that isn't relevant here.  The environment may be null in some
cases, as described later in this file.

The element is the DOM element representing this state.

The `objectsInClass` member is documented in the function that computes it,
`computeObjectsInClass`, below.

        constructor : ( @command = null ) ->
            @environment = { }
            @element = null
            @objectsInClass = null

The `objectsInClass` member maps each class name defined in the `APISandbox`
global to a list of names of objects in this state's `environment` that have
that class.  Although this can be compjuted from a state, that is only true
if the state has a non-null `environment`.  Otherwise, we will want to have
this information cached, so that we can look it up when the `environment` is
unavailable.

        computeObjectsInClass : =>

We cannot do this if the `environment` is null.  We don't have to bother to
do it if we've already done it.

            if @environment is null then return @objectsInClass = null
            if @objectsInClass isnt null then return

Loop through all objects in the environment, applying the characteristic
function for each class to it until you discover which it is, then record
the result.

            @objectsInClass = { }
            for own oname, object of @environment
                for own cname, info of APISandbox.data?.classes ? { }
                    if info.isAnInstance object
                        ( @objectsInClass[cname] ?= [ ] ).push oname
                        break

Copying a state does not copy the command that generated it nor the DOM
element that represents it (leaving both null).  It attempts to copy the
contents of the environment, if they can be copied, either using a `copy`
member function, or by treating the data as JSON.

        copy : =>
            result = new State()
            for own key, value of @environment
                try
                    result.environment[key] = value?.copy?() ? \
                        JSON.parse JSON.stringify value
                catch e
                    result.environment = null
                    break
            result

## History class

A history is essentially an array of states, together with some functions
for modifying them in ways suitable to this application.

    APISandbox.History = History = class History

It starts out as containing one state, which came from nowhere (no command
generated it) and which has no environment or DOM elements showing it.
(But DOM elements could be inserted later if desired.)

        constructor : ->
            @states = [ APISandbox.initialState() ]

The easiest operation we can do is append an action to the history, which
creates a new state based on the last one.  Here we assume that `action` is
an instance of class `Command`, defined above.

        appendAction : ( action ) =>
            @states.push action.apply @states[@states.length-1]

This central function (considered a private function) returns the history to
state `i` and then changes the history going forward from `i`.  It does so
by handing to the function `f` the array of commands that used to follow
after `i`, letting `f` return a modified version of that history, and then
applying those commands in order to regenerate the remainder of the history.

        rewriteHistory : ( i, f ) =>

We cannot rewrite command 0, which is always null.

            if i <= 0 then return

Remove and store the portion to be rewritten.

            toRewrite = ( state.command for state in @states.splice i )

If environments are not stored, re-run all history up to `i` to regenerate
those environments.

            if @states[i-1].environment is null
                @states[0] = APISandbox.initialState()
                for j in [1...i]
                    @states[j] = @states[j].command.apply @states[j-1]

Continually apply items from the modified command list to rewrite history.

            last = @states[i-1]
            for action in f toRewrite
                @states.push last = action.apply last

Now we can define several convenience functions that rewrite history.

        changeAction : ( i, action ) =>
            @rewriteHistory i, ( olds ) -> [action,olds[1...]...]
        deleteAction : ( i ) =>
            @rewriteHistory i, ( olds ) -> olds[1...]
        duplicateAction : ( i ) =>
            @rewriteHistory i, ( olds ) -> [olds[0],olds...]

Histories can also serialize themselves, into a string, for use when making
permalinks.  (The result of this should be passed through
`encodeURIComponent` if you plan to use it in a query string.  See
`APISandbox.permalink`, below.)

        serialize : =>
            array = for state in @states[1..]
                if state.command.objectName?
                    mn = state.command.methodName()
                    [ "m #{state.command.objectName}", mn.className,
                      mn.phrase, state.command.parameters... ]
                else
                    [ "c #{state.command.constructorName()}",
                      state.command.parameters... ]
            JSON.stringify array

Histories can do the inverse as well, taking a serialized set of states and
conforming themselves to that history.  This means obliterating everything
in the history at present, and replacing it with the serlialized record.
This involves a complete recomputation of everything from the history, which
is only stored as the commands that were run, not as their results.

        deserialize : ( encoded ) =>
            @states = [ APISandbox.initialState() ]
            for encodedState in JSON.parse encoded
                command = if encodedState[0][...2] is 'm '
                    objectName = encodedState[0][2..]
                    className = encodedState[1]
                    methodPhrase = encodedState[2]
                    parameters = encodedState[3..]
                    new Command objectName,
                        APISandbox.data.members[className][methodPhrase] \
                            .call, parameters...
                else
                    constructorName = encodedState[0][2..]
                    parameters = encodedState[1..]
                    new Command null,
                        APISandbox.data.constructors[constructorName].call,
                        parameters...
                @appendAction command

## API Sandbox Namespace

The following function should be called after the page loads, to let the
API Sandbox know in which DIV of the DOM it should place its output.  You
can also provide the visual representation of the initial state of the
sandbox, as an HTML string.

    APISandbox.setup = ( @div, initialHTML = '' ) ->
        @data ?= { }
        init = ( @history = new History() ).states[0]
        init.DOM = @div.ownerDocument.createElement 'div'
        init.DOM.innerHTML = initialHTML
        while @div.hasChildNodes()
            @div.removeChild @div.lastChild
        @div.appendChild init.DOM
        @div.appendChild @createCommandUI 1

We then call the following function, which is defined in
`widgets.litcoffee`.  This is a bit of a hack, sorry.

        @handlePermalink()

Call this function to inform the API Sandbox about a new class.  Provide its
name and description as strings, and a characteristic function `chi` that
can take any datum as input and return true iff that input is an instance
of the class, and false otherwise.  (Note that these need not be objects
and instances in the JavaScript sense; they can be any data and any
characteristic function.)

    APISandbox.addClass = ( name, desc, chi ) ->
        ( ( @data ?= { } ).classes ?= { } )[name] =
            description : desc
            isAnInstance : chi

Call this function to inform the API Sandbox about a new constructor.  Give
the user-visible phrase that describes the construction (e.g., "Make a new
employee record" or "Create a new random number"), the function to be called
when the construction needs to be done, and the types of the parameters it
takes.

Each argument must be an object with the following attributes.
 * name (a string)
 * description (a string)
 * type (a string that's one of these: integer, string, boolean, choice,
   object:C, float, JSON, short string, long string), with short string the
   same as string, and long string just meaning a string that gets a big
   input box, and C the name of any class, as in object:Employee or
   object:Widget
 * defaultValue (any value of the appropriate type)
 * validator (an optional function that returns an object with two fields,
   "valid," which is a boolean, and "message," which can explain why, and
   is optional)
 * min (if the type is integer or float, optional)
 * max (if the type is integer or float, optional)
 * values (an array of legal values, used only for choice types)

    APISandbox.addConstructor = ( phrase, func, parameters... ) ->
        ( ( @data ?= { } ).constructors ?= { } )[phrase] =
            call : func
            parameters : parameters

The following function works just like the previous, but it's for adding
member functions for a class, rather than the class's constructor.  The
first parameter is the name of the class given in the call to `addClass`,
defined above.  The other three parameters work just like those for
`addConstructor`.

    APISandbox.addMethod = ( className, phrase, func, parameters... ) ->
        ( @data ?= { } ).members ?= { }
        ( @data.members[className] ?= { } )[phrase] =
            call : func
            parameters : parameters

The following function permits the insertion of global objects into the
environment, which means that they exist before any commands have been run;
they are part of the initial state.

    APISandbox.addGlobal = ( name, description, object ) ->
        ( ( @data ?= { } ).globals ?= { } )[name] =
            description : description
            value : object

We therefore provide the following convenience function for constructing an
initial state, which will include the globals.

    APISandbox.initialState = ->
        result = new State()
        for own key, value of @data?.globals ? { }
            result.environment[key] = value.value
        result

Fetch a permalink to the current computation history with this method.

    APISandbox.permalink = ->
        currentURL = window.location.href.split( '?' )[0]
        "#{currentURL}?#{encodeURIComponent @history.serialize()}"
