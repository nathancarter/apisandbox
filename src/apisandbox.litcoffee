
# API Sandbox

Documentation to come later.

    window.Command = Command = class

In the constructor, the object name is a string, matching the name in an
environment, the method is an actual function to call to execute the
command, and the parameters array has entries of one of the following two
forms.
 * `{ name : 'object name' }`
 * `{ value : atomic or JSON }`

        Command : ( @objectName, @method, @parameters... ) =>
            # no other actions necessary
