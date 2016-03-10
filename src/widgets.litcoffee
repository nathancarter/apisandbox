
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
        typeName = type.type
        id = "input-#{index}-#{paramIndex}"
        idexpr = "id='#{id}'"

Create the HTML code for the input widget, based on the data type.  Include
the CSS ID just created above.

        right = switch typeName
            when 'integer', 'float', 'string', 'short string'
                "<input type='text' #{idexpr} width=40
                    value='#{type.defaultValue ? ''}'/>"
            when 'boolean'
                onoff = if type.defaultValue then 'selected' else ''
                "<input type='checkbox' #{idexpr} #{onoff}/>"
            when 'choice', 'object'
                choices = if typeName is 'choice'
                    type.values
                else
                    [ 'cannot', 'yet', 'populate', 'object', 'lists',
                      '...', 'come', 'back', 'later' ]
                choices = ( "<option value='#{c}'>#{c}</option>" \
                    for c in choices )
                "<select #{idexpr}>#{choices.join ''}</select>".replace \
                    "value='#{type.defaultValue}'",
                    "value='#{type.defaultValue}' selected"
            when 'JSON', 'long string'
                "<textarea rows=6 cols=40
                    #{idexpr}>#{type.defaultValue}</textarea>"

Create a table row and put the widget and its label inside it.  We will
return this table row, to be placed in a table by the caller.

        result = @div.ownerDocument.createElement 'tr'
        result.innerHTML = "<td align='right' width='35%'>#{type.name}</td>
            <td width='65%'>#{right} &nbsp;
            <span id='#{id}-notifications'></span></td>"

Now, if the type is integer or float, we need to wrap the existing validator
function (if any) in a check to be sure that the data is even in the right
format in the first place (an integer or a float).

        validator = type.validator
        if typeName in [ 'integer', 'float' ]
            oldValidator = validator
            if typeName is 'integer'
                re = /^[+-]?[0-9]+$/
                func = parseInt
                phrase = 'an integer'
            else
                re = /^[+-]?[0-9]*\.?[0-9]+|[+-]?[0-9]+\.[0-9]*$/
                func = parseFloat
                phrase = 'a float'
            validator = ( input ) ->
                if not re.test input
                    valid : no
                    message : "This is not #{phrase}."
                else
                    value = func input
                    if type.min? and type.min > value
                        valid : no
                        message : "The minimum is #{type.min}."
                    else if type.max? and type.max < value
                        valid : no
                        message : "The maximum is #{type.max}."
                    else
                        oldValidator? value

We now create the event handler which applies that validator to the
content of the input widget whenever it changes, and updates the output
message, if any, in the DOM.

        input = $ "##{id}", result
        notify = $ "##{id}-notifications", result
        validate = =>
            validation = validator? ( $ input ).val()
            if validation?.valid is no
                notify.get( 0 ).innerHTML =
                    "<font color=red>#{validation?.message ? ''}</font>"
                input.get( 0 ).setAttribute 'data-invalid',
                    validation?.message ? '--'
            else
                notify.get( 0 ).innerHTML = validation?.message ? ''
                input.get( 0 ).removeAttribute 'data-invalid'

Install that event handler and run it as soon as we're done here.

        input.change validate
        input.keyup validate
        setTimeout validate, 0

Install the default value and be done.

        if type.defaultValue? then input.val type.defaultValue
        result

To read data from a widget created with the above function, we use the
following routine.  Right now this is very simple, but it will be upgraded
in the future.

    APISandbox.readDataFrom = ( widget ) -> ( $ widget ).val()

To read data from all widgets for a given index, use the following routine.

    APISandbox.readAll = ( index ) ->
        result = [ ]
        i = 0
        while ( next = ( $ "#input-#{index}-#{i}" ) ).length > 0
            if message = next.get( 0 ).getAttribute 'data-invalid'
                throw message
            result.push next.val()
            i++
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
        data = if className then @data.methods?[className]?[funcName] \
            else @data.constructors?[funcName]
        result = @div.ownerDocument.createElement 'div'
        table = @div.ownerDocument.createElement 'table'
        table.style.borderSpacing = '10px'
        table.style.borderCollapse = 'separate'
        table.setAttribute 'width', '100%'
        result.appendChild table
        for parameter, i in data.parameters
            table.appendChild @inputWidget index, i, parameter
        result

Creates a DIV containing a drop-down list from which you can choose the
phrase describing a constructor, and then fill out the appropriate parameter
table below that choice.

    APISandbox.createCommandUI = ( index ) ->

Build the drop-down menu listing all the constructors.

        result = @div.ownerDocument.createElement 'div'
        result.innerHTML = "<select id='ctor-select-#{index}'></select>"
        select = $ "#ctor-select-#{index}", result
        firstPhrase = null
        for phrase, data of @data.constructors
            firstPhrase ?= phrase
            option = @div.ownerDocument.createElement 'option'
            option.setAttribute 'value', option.innerHTML = phrase
            result.childNodes[0].appendChild option

If there were no constructors, stop here as a corner case.

        if not firstPhrase then return result

Create the function input table for the first (and selected) constructor.

        result.childNodes[0].childNodes[0]?.setAttribute 'selected', yes
        table = @tableForFunction index, null, firstPhrase
        table.setAttribute 'id', "parameters-for-#{index}"
        result.appendChild table

If the user chooses a different constructor from the list, we'll need to
swap that parameter table out for a new one.

        select.change =>
            newTable = @tableForFunction index, null, select.val()
            ( $ table ).replaceWith newTable
            newTable.setAttribute 'id', "parameters-for-#{index}"

Now we append the "Apply" button.

        result.appendChild row = @div.ownerDocument.createElement 'div'
        row.innerHTML = "<input type='button' value='Apply'
            id='apply-button-#{index}'/>"
        row.style.textAlign = 'right'

Here is the action that "Apply" performs.

        ( $ "#apply-button-#{index}", row ).click =>

Find which constructor is currently selected and try to get all of its
parameters.  This may fail if a validator fails, and if so, stop here.

            choice = ( $ "#ctor-select-#{index}", result ).val()
            if not ctorData = @data.constructors[choice]
                return console.log 'Error: no such constructor:', choice
            try
                parameters = @readAll index
            catch e
                return alert "Fix the errors, starting with:\n\n#{e}"

Construct a new command and run it on the last state in the history, thus
creating a new state, whose DOM representation we append to the page.

            command = new @Command null, ctorData.call, parameters...
            @history.appendAction command
            ( $ "#apply-button-#{index}", row ).hide()
            @div.appendChild \
                @history.states[@history.states.length-1].element
            @div.appendChild @createCommandUI @history.states.length

Return the DOM that contains all the stuff created above.

        result
