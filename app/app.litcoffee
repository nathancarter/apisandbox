
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

        if typeName?[...7] is 'object:'
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
