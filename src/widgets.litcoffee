
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

    APISandbox.inputWidget = ( index, paramIndex, type ) ->
        # This does not yet add interactivity (event listeners), just the
        # widgets themselves.  Also, does not yet support name/description
        # members.  More to come later.
        typeName = type.type
        if typeName is 'string'
            typeName += if type.long then '+' else '-'
        id = "id='input-#{index}-#{paramIndex}'"
        right = switch typeName
            when 'integer', 'float', 'string-'
                "<input type='text' #{id} width=40
                    value='#{type.defaultValue ? ''}'/>"
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
        result = @div.ownerDocument.createElement 'tr'
        result.innerHTML = "<td>#{type.name}</td><td>#{right}</td>"
        result

The following function creates the DOM element containing all the input
widgets (and their labels) for an entire sequence of parameters to a given
function.  The index is an integer index into the history, which is passed
on to the `inputWidget` function, to ensure unique IDs.  The `className` and
`funcName` parameters distinguish the function whose parameters we're
creating widgets for.  If it is a constructor, leave `className` null and
provide as `funcName` the phrase describing the constructor.  The result is
a two-column table.

    APISandbox.tableForFunction = ( index, className, funcName ) ->
        console.log index, className, funcName, @data
        data = if className then @data.methods?[className]?[funcName] \
            else @data.constructors?[funcName]
        result = @div.ownerDocument.createElement 'div'
        table = @div.ownerDocument.createElement 'table'
        table.style.borderSpacing = '10px'
        table.style.borderCollapse = 'separate'
        result.appendChild table
        for parameter, i in data.parameters
            table.appendChild @inputWidget index, i, parameter
        result

Creates a DIV containing a drop-down list from which you can choose the
phrase describing a constructor, and then fill out the appropriate parameter
table below that choice.

    APISandbox.createCommandUI = ( index ) ->
        # interactivity not yet built; still to come
        result = @div.ownerDocument.createElement 'div'
        result.innerHTML = "<select id='ctor-select-#{index}'></select>"
        firstPhrase = null
        for phrase, data of @data.constructors
            firstPhrase ?= phrase
            option = @div.ownerDocument.createElement 'option'
            option.setAttribute 'value', option.innerHTML = phrase
            result.childNodes[0].appendChild option
        if firstPhrase
            result.childNodes[0].childNodes[0]?.setAttribute 'selected', yes
            result.appendChild @tableForFunction index, null, firstPhrase
        result
