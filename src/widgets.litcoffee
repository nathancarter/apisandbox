
This file adds to the APISandbox namespace members for creating, writing to,
and reading from DOM form elements.  These will be used to allow users to
enter parameters for functions in the API they're calling.

The `inputWidget` function creates a DOM element permitting input of the
given type.  The index is an integer index into the sandbox history, but the
`paramIndex` indicates which position this widget's parameter has among the
full list for this command.  Together these are used to make sure element
IDs are unique. The type must be one of the type-defining objects used to
specify parameters when calling functions like
`APISandbox.addConstructor()`, defined in
[apisandbox.litcoffee](apisandbox.litcoffee).

    APISandbox.inputWidget = ( index, paramIndex, type, optionalArgs ) ->
        # This does not yet add interactivity (event listeners), just the
        # widgets themselves.  Also, does not yet support name/description
        # members.  More to come later.
        result = @div.ownerDocument.createElement 'div'
        typeName = type.type
        if typeName is 'string'
            typeName += if type.long then '+' else '-'
        id = "id='input-#{index}-#{paramIndex}'"
        result.innerHTML = switch typeName
            when 'integer', 'float', 'string-'
                "<input type='text' #{id}
                    width=40>#{type.defaultValue}</input>"
            when 'boolean'
                onoff = if type.defaultValue then 'selected' else ''
                "<input type='checkbox' #{id} #{onoff}/>"
            when 'choice', 'object'
                choices = if typeName is 'choice'
                    type.values
                else
                    [ 'cannot', 'yet', 'populate', 'object', 'lists',
                      '...', 'come', 'back', 'later' ]
                choices = ( "<option value='#{c}'>#{c}</option>" \
                    for c in choices )
                "<select #{id}>#{choices.join ''}</select>".replace \
                    "value='#{type.defaultValue}'",
                    "value='#{type.defaultValue}' selected"
            when 'JSON', 'string+'
                "<textarea rows=6 cols=40
                    #{id}>#{type.defaultValue}</textarea>"

    # DOM element, a two-column table of key-value pairs/widgets
    tableForFunction : ( className, fname ) ->
        # not yet built

    # same as previous, but for constructors
    tableForConstructor : ( className ) ->
        # not yet built

    # partial command UI as shown below, not yet interactive
    createCommandUI : ( index ) ->
        # not yet built
