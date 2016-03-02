
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

        constructor : ( @objectName, @method, @parameters... ) ->
            # no other actions necessary

Apply the command to a state with the following function, which creates a
new state.  (The `State` class is defined below.)

        apply : ( state ) =>

Verify that the object on which we're supposed to run the command exists
(if such an object was specified by name).

            if command.objectName and \
               command.objectName not of state.environment
                throw "Cannot invoke the command, because there is no object
                    with this name: #{command.objectName}"

Duplicate the old state, then modify it by using the method stored in this
command.  Return the result.  Note that the last parameter passed is always
the environment, so that the method may choose to ignore it, or use it if it
needs to modify it (which most won't).

            result = state.copy()
            result.command = @
            if result.environment is null
                result.environment = state.environment
                state.environment = null
            command.method.apply result.environment[command.objectName],
                command.parameters..., state.environment

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

        constructor : ( @command = null ) ->
            @environment = { }
            @element = null

Copying a state does not copy the command that generated it nor the DOM
element that represents it (leaving both null), but attempts to copy the
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
            @states = [ new State() ]

The easiest operation we can do is append an action to the history, which
creates a new state based on the last one.

        appendAction = ( action ) ->
            @states.push action @states[@states.length-1]

This central function (considered a private function) returns the history to
state `i` and then changes the history going forward from `i`.  It does so
by handing to the function `f` the array of commands that used to follow
after `i`, letting `f` return a modified version of that history, and then
applying those commands in order to regenerate the remainder of the history.

        rewriteHistory = ( i, f ) ->

Remove and store the portion to be rewritten.

            toRewrite = ( state.command for state in @states.splice i+1 )

If environments are not stored, re-run all history up to `i` to regenerate
those environments.

            if @states[i].environment is null
                for j in [1..i]
                    @states[j] = @states[j].command.apply @states[j-1]

Continually apply items from the modified command list to rewrite history.

            last = @states[i]
            for action in f toRewrite
                @states.push last = action.apply last

Now we can define several convenience functions that rewrite history.

        changeAction = ( i, action ) ->
            rewriteHistory ( oldActions ) -> [action,oldActions[1...]...]
        deleteAction = ( i ) ->
            rewriteHistory ( oldActions ) -> oldActions[1...]
        duplicateAction = ( i ) ->
            rewriteHistory ( oldActions ) -> [oldActions[0],oldActions...]
