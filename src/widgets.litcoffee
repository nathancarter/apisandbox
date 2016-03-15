
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

        if typeName[...7] is 'object:'
            className = typeName[7..]
            typeName = 'object'
        else
            className = null
        right = switch typeName
            when 'integer', 'float', 'string', 'short string'
                "<input type='text' #{idexpr} width=40 class='form-control'
                    value='#{type.defaultValue ? ''}'/>"
            when 'boolean'
                onoff = if type.defaultValue then 'selected' else ''
                "<input type='checkbox' #{idexpr} #{onoff}
                 class='form-control'/>"
            when 'choice', 'object'
                if typeName is 'choice'
                    choices = type.values
                else
                    state = @history.states[index-1]?.objectsInClass
                    choices = [ ]
                    for own cname, onames of state ? { }
                        if not className? or className is cname
                            choices = choices.concat onames
                choices = ( "<option value='#{c}'>#{c}</option>" \
                    for c in choices )
                "<select #{idexpr} class='form-control'>#{choices.join ''}
                 </select>".replace "value='#{type.defaultValue}'",
                    "value='#{type.defaultValue}' selected"
            when 'JSON', 'long string'
                "<textarea rows=6 cols=40 class='form-control'
                    #{idexpr}>#{type.defaultValue}</textarea>"

Create a table row and put the widget and its label inside it.  We will
return this table row, to be placed in a table by the caller.

        result = @div.ownerDocument.createElement 'tr'
        result.innerHTML = "<td align='right' width='35%'><label
            >#{type.name}</label></td><td width='65%'>#{right} &nbsp;
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

Give the input widget a class for later selection.

        input.addClass 'command-ui-input'

Install the default value and be done.

        if type.defaultValue? then input.val type.defaultValue
        result

To read data from a widget created with the above function, we use the
following routine.  Right now this is very simple, but it will be upgraded
in the future.

    APISandbox.readDataFrom = ( widget ) -> ( $ widget ).val()

The converse of the above operation is this.

    APISandbox.writeDataTo = ( widget, value ) -> ( $ widget ).val value

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

The converse of the above operation is this.

    APISandbox.writeAll = ( index ) ->
        for value, i in @history.states[index].command.parameters
            widget = $ "#input-#{index}-#{i}"
            widget.val value.name ? value.value ? value
            widget.change()

In addition, we'll also want to set the initial one or two drop-down menus
back to the state they were when the command stored in the history was
invoked.  This command does so.

    APISandbox.restoreSelects = ( index ) ->
        command = @history.states[index].command

First, show the buttons in the top right of the command UI iff it is not the
last command UI.

        if index < @history.states.length
            ( $ "#delete-command-#{index}" ).show()
            ( $ "#duplicate-command-#{index}" ).show()
        else
            ( $ "#delete-command-#{index}" ).hide()
            ( $ "#duplicate-command-#{index}" ).hide()

For the first drop-down, if the function was invoked on an object, select
the object's name in the drop-down.

        choices = $ "#ctor-select-#{index}"
        methods = $ "#method-select-#{index}"
        if command.objectName?
            for option in choices.get( 0 ).childNodes
                if option.getAttribute( 'data-object-name' ) is \
                   command.objectName
                    choices.val option.getAttribute 'value'
                    choices.change()
                    break

Also, since this was a method invoked on an object, we must select the
method from the second drop-down.  Also, show the second drop-down.

            methods.show()
            if ( methName = command.methodName() )?
                methods.val methName.phrase
                methods.change()
                return

Otherwise look for the command's function among the list of constructors.
If you find it, choose that constructor from the list.  Then hide the
methods drop-down.

        choices.val command.constructorName()
        choices.change()
        methods.hide()

The following function creates the DOM element containing all the input
widgets (and their labels) for an entire sequence of parameters to a given
function.  The index is an integer index into the history, which is passed
on to the `inputWidget` function, to ensure unique IDs.  The `className` and
`funcName` parameters distinguish the function whose parameters we're
creating widgets for.  If it is a constructor, leave `className` null and
provide as `funcName` the phrase describing the constructor.  The result is
a two-column table.

    APISandbox.tableForFunction = ( index, className, funcName ) ->
        data = if className then @data.members?[className]?[funcName] \
            else @data.constructors?[funcName]
        result = @div.ownerDocument.createElement 'div'
        table = @div.ownerDocument.createElement 'table'
        table.style.borderSpacing = '10px'
        table.style.borderCollapse = 'separate'
        table.setAttribute 'width', '100%'
        result.appendChild table
        for parameter, i in data?.parameters ? { }
            table.appendChild @inputWidget index, i, parameter
        result

Creates a DIV containing a drop-down list from which you can choose the
phrase describing a constructor, and then fill out the appropriate parameter
table below that choice.

    APISandbox.createCommandUI = ( index ) ->

First, ensure that the previous state has the relevant data pre-computed, so
that we can populate drop-down menus in widgets for this action.

        @history.states[index-1]?.computeObjectsInClass?()

Build the drop-down menu listing all the constructors and objects.

        result = @div.ownerDocument.createElement 'div'
        result.setAttribute 'class', 'command-ui'
        result.setAttribute 'id', "command-ui-#{index}"
        result.innerHTML = "<select id='ctor-select-#{index}'
            class='form-control' style='width: 80%;'></select>"
        select = $ "#ctor-select-#{index}", result
        for cname, objects of @history.states[index-1]?.objectsInClass ? { }
            for object in objects
                option = @div.ownerDocument.createElement 'option'
                option.setAttribute 'value', cname
                option.setAttribute 'data-object-name', object
                option.innerHTML = "With the #{cname} #{object},"
                result.childNodes[0].appendChild option
        for phrase, data of @data.constructors
            option = @div.ownerDocument.createElement 'option'
            option.setAttribute 'value', option.innerHTML = phrase
            result.childNodes[0].appendChild option

If that drop-down menu is empty, stop here as a corner case.

        if select.get( 0 ).childNodes.length is 0 then return result

Create a second drop-down list next to the first, for use when an object is
selected in the first.  The second drop-down list will allow the user to
choose the method within that object that they wish to invoke.

        methods = @div.ownerDocument.createElement 'select'
        methods.setAttribute 'id', "method-select-#{index}"
        methods.setAttribute 'class', 'form-control'
        methods.style.width = '80%'
        select.after methods
        hideMethods = -> ( $ methods ).hide()
        showMethods = -> ( $ methods ).show()
        hideMethods()

Here's a method for populating the methods list with all the members of a
given class.

        fillMethods = ( className ) =>
            while methods.childNodes.length > 0
                methods.removeChild methods.childNodes[0]
            for phrase, data of ( @data.members ? { } )[className] ? { }
                option = @div.ownerDocument.createElement 'option'
                option.setAttribute 'value', option.innerHTML = phrase
                methods.appendChild option
                if methods.childNodes.length is 1
                    ( $ methods ).val phrase
            if methods.childNodes.length is 0
                option = @div.ownerDocument.createElement 'option'
                option.setAttribute 'value', ''
                option.innerHTML = 'there is nothing you can do'
                methods.appendChild option
                ( $ methods ).val ''

Create the function input table for the first (and selected) constructor.
For now, this is an empty DIV, but we will run a routine below that
populates it.

        table = @div.ownerDocument.createElement 'div'
        table.setAttribute 'id', "parameters-for-#{index}"
        result.appendChild table

Now we append the "Apply" button.

        result.appendChild row = @div.ownerDocument.createElement 'div'
        row.innerHTML = "<input type='button' value='Apply'
            class='btn btn-default btn-primary' id='apply-button-#{index}'/>
            <input type='button' value='Cancel'
            class='btn btn-default btn-warning'
            id='cancel-button-#{index}'/>"
        row.style.textAlign = 'right'
        showApply = -> ( $ "#apply-button-#{index}", result ).show()
        hideApply = -> ( $ "#apply-button-#{index}", result ).hide()
        showCancel = -> ( $ "#cancel-button-#{index}", result ).show()
        hideCancel = -> ( $ "#cancel-button-#{index}", result ).hide()
        hideCancel()

If the user chooses a different constructor from the list, we'll need to
swap that parameter table out for a new one.  Here's the method for doing
so, and we run it once now, to initially populate the parameter table.

        updateParameterTable = ( newTable ) =>
            ( $ table ).replaceWith newTable
            newTable.setAttribute 'id', "parameters-for-#{index}"
            table = newTable
            ( $ '.command-ui-input', result ).change =>
                showApply()
                if @history.states[index]?.command? then showCancel()
            ( $ '.command-ui-input', result ).keyup =>
                showApply()
                if @history.states[index]?.command? then showCancel()
        ( $ methods ).change =>
            method = ( $ methods ).val()
            updateParameterTable @tableForFunction index, select.val(),
                method
            if method isnt ''
                showApply()
                if @history.states[index]?.command? then showCancel()
            else
                hideApply()
                hideCancel()
        select.change =>
            choice = select.val()
            if @data.constructors?[choice]?
                hideMethods()
                updateParameterTable @tableForFunction index, null, choice
                showApply()
                if @history.states[index]?.command? then showCancel()
            else
                fillMethods choice
                showMethods()
                ( $ methods ).change()
        select.change()

The apply and delete functions both use the following function to update the
list of DIVs representing the whole series of computations from some point
onward.

        updateViewAfter = ( deleteThis = no ) =>

Clear out any content following the newly changed state.

            while result.nextSibling?
                result.parentNode.removeChild result.nextSibling
            if deleteThis then result.parentNode.removeChild result

Show the results of this action, plus any others that follow it later in the
history.

            n = @history.states.length
            start = if deleteThis then index-1 else index
            for i in [start...n]
                if i > 0
                    @div.appendChild @history.states[i].element
                @div.appendChild @createCommandUI i+1
                if i+1 < n
                    @restoreSelects i+1
                    @writeAll i+1
            for i in [start+1...n]
                ( $ "#apply-button-#{i}", @div ).hide()
                ( $ "#cancel-button-#{i}", @div ).hide()

Insert into this result DIV a floating X in the top-right corner, for
deleting the command.  Also add a duplicate button.

        float = @div.ownerDocument.createElement 'div'
        float.style.float = 'right'
        float.innerHTML = "<button type='button'
            id='delete-command-#{index}'
            class='btn btn-danger btn-sm'><span class='glyphicon
            glyphicon-remove'></span></button><button type='button'
            id='duplicate-command-#{index}'
            class='btn btn-default btn-sm'><span class='glyphicon
            glyphicon-plus'></span></button>"
        result.insertBefore float, result.childNodes[0]
        deleteX = float.childNodes[0]
        ( $ deleteX ).click =>
            @history.deleteAction index
            updateViewAfter yes
            @updatePermalinkElement()
        ( $ deleteX ).hide()
        duplicate = float.childNodes[1]
        ( $ duplicate ).click =>
            @history.duplicateAction index
            updateViewAfter()
            @updatePermalinkElement()
        ( $ duplicate ).hide()

Here is the action that "Apply" performs.

        ( $ "#apply-button-#{index}", result ).click =>

Find which object or constructor is currently selected.

            choice = select.val()
            className = objectName = null
            if not funcData = @data.constructors[choice]
                objectName = select.find( ':selected' ).get( 0 ). \
                    getAttribute 'data-object-name'
                funcData = @data.members[choice][( $ methods ).val()]

Try to get all the function's parameters.  If a validator fails, stop here.

            try
                parameters = @readAll index
            catch e
                return alert "Fix the errors, starting with:\n\n#{e}"

Construct a new command to run.

            encodedParameters = for paramData, i in funcData.parameters
                if paramData.type is 'object'
                    name : parameters[i]
                else
                    value : parameters[i]
            command = new @Command objectName, funcData.call,
                encodedParameters...

Run that command on the appropriate state in the history.

            if index is @history.states.length
                @history.appendAction command
            else
                @history.changeAction index, command
            hideApply()
            hideCancel()
            updateViewAfter()
            @updatePermalinkElement()

Once this command has been applied, it can be deleted or duplicated.

            ( $ deleteX ).show()
            ( $ duplicate ).show()

Thus ends the handler for the Apply button.  The Cancel button just puts the
UI back to the state it was in before it was last Applied.

        ( $ "#cancel-button-#{index}", result ).click =>
            @restoreSelects index
            @writeAll index
            hideApply()
            hideCancel()

So return the DOM that contains all the stuff created above.

        result

If the user navigated to this page via a permalink, we can set up the UI
in response to that permalink now.  This should only be called by
`APISandbox.setup`, not after any computation has been done.

    APISandbox.handlePermalink = ->
        queryString = window.location.href.split( '?' )[1]
        if queryString is '' or queryString is null then return
        queryString = decodeURIComponent queryString
        if queryString is '' or queryString is null then return
        try
            JSON.parse queryString
        catch e
            return
        @history.deserialize queryString
        for state, index in @history.states
            if index > 0
                @div.appendChild state.element
                @div.appendChild @createCommandUI index+1
            if index < @history.states.length - 1
                @restoreSelects index+1
                @writeAll index+1
            ( $ "#apply-button-#{index}", @div ).hide()
            ( $ "#cancel-button-#{index}", @div ).hide()
        @updatePermalinkElement()

Convenience function for creating a permalink element.

    APISandbox.permalinkElement = ->
        if not @_permalinkElement?
            result = @div.ownerDocument.createElement 'a'
            result.setAttribute 'href', ''
            result.innerHTML = 'Permalink'
            ( $ result ).click => window.location.href = @permalink()
            @_permalinkElement = result
        @_permalinkElement

This function keeps permalink elements up-to-date.

    APISandbox.updatePermalinkElement = ->
        @permalinkElement().setAttribute 'href', APISandbox.permalink()

Convenience function for creating a "clear" element.

    APISandbox.clearElement = ->
        result = @div.ownerDocument.createElement 'a'
        result.setAttribute 'href', window.location.href.split( '?' )[0]
        result.innerHTML = 'Clear'
        result
