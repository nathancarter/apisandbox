
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
