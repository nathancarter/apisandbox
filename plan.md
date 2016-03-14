
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

Add support for descriptions to show up as tooltips over input widgets
and/or their labels.

Push to GitHub.

Share with Ken.

Bigger Examples
 * Mathematical/statistical computations
 * Exploring the API of a JavaScript library
 * Video game calculator/simulator for CoC/VG
