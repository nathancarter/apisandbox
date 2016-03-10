
Make it so that choosing a new constructor re-populates the parameter UI
table.

Enhance Apply so that for commands that are not the last, it does this:
 * Use `replaceAction` instead of `appendAction`.
 * Remove from the DOM all the stuff after the changed state.
 * Alternate between appending DOM objects and `createCommandUI` results,
   from the altered state onward.
Verify that this works for any command UI on the list.

Add a Cancel button on the bottom right that's visible iff Apply has been
clicked, but then things have been modified.  What Cancel does is it
reverses all those modifications, then hides the Apply and Cancel buttons.

Add support for object types.

Make APISandbox able to fill in default values by implementing this function
and using it.
```coffee
writeDataToWidget : ( index, value ) ->
    # use getElementById() to find widget in page
```

Extend the APISandbox namespace to permit registering member functions for
classes.
```coffee
addMember : ( className, phrase, func, args... ) ->
```

Extend the State class with
 * a member that's a mapping from class names to the list of object names
   that have those classes in this state, even if its environment is null.
   This is JSON.
 * a member function that computes this mapping and stores it, provided that
   the environment is non-null.
Call that member function from `createCommandUI` so that, below, it will be
able to use the resulting mapping to know how to populate drop-down lists.

Extend the command UI to permit running member functions in this form.
```
[Use OBJECT-NAME] [MEMBER-FUNC-PHRASE]
    [PARAM-NAME-1]  [PARAM-VALUE-1]
    [PARAM-NAME-2]  [PARAM-VALUE-2]
    ...             ...
```

Extend the demo with these functions.
```
w.reverse() # changes w to its reverse
w.sort() # sorts the letters of w alphabetically
w.facts() # prints facts/links about w
```

Ensure that Command instances are correctly created from this new UI.
Verify that everything therefore runs correctly, even with member functions.

Extend the APISandbox namespace to permit registering global objects.
```coffee
addGlobal : ( name, desc, object ) ->
    # can detect its class using chi for each class
```
Test by adding an example global to the Words demo.  E.g., the word
"example."

Extend each command UI with an X in the top right that deletes the command,
by calling `deleteAction` and then repopulating the view DIV, much like
`changeAction` does.

Extend each command UI with a "duplicate" button in the top right that
duplicates the command, by calling `duplicateAction` and then repopulating
the view DIV, much like the previous task.

Extend the History class with these two members
 * `encode()` serializes the list of commands to a query string, without any
   environments or anything else (they would need to be recomputed)
 * `decode()` deserializes a query string into a history object and runs all
   the commands to regenerate everything else
Extend the APISandbox namespace with two corresponding functions.
 * `permalink()` that creates a link to the current page, but with the query
   string encoding the results of `history.encode()`.
 * Extend the `setup()` function so that it checks the query string and, if
   it contains content that passes successfully through `history.decode()`,
   fill the view DIV with the representations of all the history's states.
Create a Permalink button that navigates to the permalink.  Probably it
belongs in the title bar.

Create a Clear button that clears the contents of the page.

Add a medium Example, using an SVG toolkit like [Snap](http://snapsvg.io),
in a new demo page, `demo2.html`.
```coffee
HandfulOfDice(n) # constructor
h.roll(m) # list of sums, with histogram
h.show() # picture of n dice
```

Push to GitHub.

Share with Ken.

Bigger Examples
 * Mathematical/statistical computations
 * Exploring the API of a JavaScript library
 * Video game calculator/simulator for CoC/VG
