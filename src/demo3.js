
/*

API Sandbox Permutation Demo

If you have not yet read the tiny demo (in the file demo1-solo.litcoffee),
you should start there first.  This file is similar to that one, with the
main difference being that this one is written in JavaScript, for those who
prefer that language.  But the general concepts of how to set up an API
Sandbox app are explained in the tiny demo, and anything that file has in
common with this one is not re-explained here.  Note that this file is the
script code, but the page itself is in app/demo2.html in this repository.


    +-----------------------+
    | What's a permutation? |
    +-----------------------+

In this demo, the user can create permutations using cycle notation, and
then multiply them, creating new permutations.  If you're not familiar with
permutations or cycle notation, see Wikipedia:
    https://en.wikipedia.org/wiki/Permutation
    https://en.wikipedia.org/wiki/Permutation#Cycle_notation

Several utility functions for the permutation class are defined at the end
of this file, so that the interesting stuff is at the top.  For now, just
accept the existence of these functions:
    applyPermutation(p,input)
    permutationInverse(p)
    multiplyPermutations(p1,p2)
    cycleNotation(p)
    stringToPermutation(cycleNotation)


    +-----------------------+
    | The Permutation class |
    +-----------------------+

Because this demo is so small, it only has one class, so we can guarantee
that any object in the environment is an instance of this class; thus the
characteristic function can just say yes to everything.

 */

APISandbox.addClass(
    // name of the class
    'permutation',
    // human-readable description of the class
    'A permutation, in the mathematical sense of the word',
    // characteristic function (is the input a member of this class? yes/no)
    function () { return true; }
);

 /*

    +-----------------------------+
    | The Permutation constructor |
    +-----------------------------+

When constructing a permutation, you write it in cycle notation, which is
defined in the link above.  The constructor parses this notation and
converts it internally into an object mapping integers to integers.  Only
permutations of natural numbers are permitted.

 */

APISandbox.addConstructor(
    // human-readable description of the act of constructing one of these
    'Make a new permutation',
    // function that constructs one
    // (what parameters does it take?  see below...)
    function ( name, cycleNotation, environment ) {
        try {
            environment[name] = stringToPermutation( cycleNotation );
            return 'Let ' + name + ' stand for the permutation defined by '
                 + 'the cycle notation ' + cycleNotation + '.';
        } catch ( e ) {
            return '<font color=red><b>' + e
                 + '</b></font>  No permutation constructed.';
        }
    },
    // now we define what parameters the system should prompt the user for,
    // to pass to calls of the constructor function we just defined.
    // parameter 1: what do you want to call your permutation?
    {
        name : 'name for the permutation',
        description : 'a variable to use as the permutation\'s name',
        type : 'string',
        defaultValue : 'p',
        // the following function gives feedback as the user types,
        // and prevents them from using a name like %^&(%(&&)))@#
        validator : function ( maybeAName ) {
            if ( /^[a-zA-Z]+$/.test( maybeAName ) ) {
                return { valid : true };
            } else {
                return { valid : false,
                         message : 'Names must be valid identifiers, '
                                 + 'such as X or Y or myPerm.' };
            }
        }
    },
    // parameter 2: the cycle notation for the permutation
    {
        name : 'the permutation',
        description : 'use cycle notation, such as (1 2)(4 0 5)',
        type : 'string',
        defaultValue : '()',
        // the following function gives feedback as the user types,
        // and reminds them to use cycle notation if they get it wrong
        validator : function ( maybeCycleNotation ) {
            try {
                stringToPermutation( maybeCycleNotation );
                return { valid : true };
            } catch ( e ) {
                return { valid : false, message : e };
            }
        }
    }
);

 /*

    +---------------------+
    | Permutation methods |
    +---------------------+

There are two methods you can do with a permutation.  You can invert it,
and you can compute its product with another permutation.

Each is added here as a "method" of the permutation class.

Inversion:

 */

APISandbox.addMethod(
    // the method can be used on what class?
    'permutation',
    // human-readable description of the action
    'compute its inverse',
    // function that does the action
    function ( name, newName, environment ) {
        environment[newName] = permutationInverse( environment[name] );
        return 'Let ' + newName + ' stand for the inverse of ' + name
             + ', which is ' + cycleNotation( environment[newName] ) + '.';
    },
    // specifications for the parameters this method requires
    // the only parameter is the name under which to store the inverse
    {
        name : 'name for the inverse',
        description : 'a variable name into which to store the inverse',
        type : 'string',
        defaultValue : 'pinv',
        // same validator as given earlier for names
        validator : function ( maybeAName ) {
            if ( /^[a-zA-Z]+$/.test( maybeAName ) ) {
                return { valid : true };
            } else {
                return { valid : false,
                         message : 'Names must be valid identifiers, '
                                 + 'such as X or Y or myPerm.' };
            }
        }
    }
)

 /*

Multiplication:

 */

APISandbox.addMethod(
    // the method can be used on what class?
    'permutation',
    // human-readable description of the action
    'multiply it by another permutation',
    // function that does the action
    function ( name, other, newName, environment ) {
        environment[newName] =
            multiplyPermutations( environment[name], environment[other] );
        return 'Let ' + newName + ' stand for the product of ' + name
             + ' with ' + other + '.<br>In other words, ' + newName + ' = '
             + cycleNotation( environment[name] ) + ' * '
             + cycleNotation( environment[other] ) + ' = '
             + cycleNotation( environment[newName] ) + '.';
    },
    // specifications for the parameters this method requires
    // parameter 1: the permutation to multiply this one by
    {
        name : 'the other factor',
        description : 'the permutation to multiply this one by',
        // the type is interesting here -- we specify that this
        // parameter must be a permutation, and the UI will therefore
        // require the user to pick from a list of permutations in the
        // current environment -- no validator necessary!
        type : 'object:permutation'
    },
    // parameter 2: the name under which to store the product
    {
        name : 'name for the product',
        description : 'a variable name into which to store the product',
        type : 'string',
        defaultValue : 'prod',
        // same validator as given earlier for names
        validator : function ( maybeAName ) {
            if ( /^[a-zA-Z]+$/.test( maybeAName ) ) {
                return { valid : true };
            } else {
                return { valid : false,
                         message : 'Names must be valid identifiers, '
                                 + 'such as X or Y or myPerm.' };
            }
        }
    }
)

 /*

    +-------+
    | Setup |
    +-------+

The setup, permalink, and clear code is the same as it was in the tiny demo.
Refer there for documentation on this code.

 */

APISandbox.setup( document.getElementById( 'main-div' ) );
$( '#title-div' ).append( APISandbox.permalinkElement() );
$( '#title-div' ).append( ' &mdash; ' );
$( '#title-div' ).append( APISandbox.clearElement() );


 /*

    +------------+
    | Miscellany |
    +------------+

Finally, a few utility functions for dealing with permutations.  We will
store permutations as JavaScript objects whose keys and values are natural
numbers, such that the permutation maps i to j if and only if
permutationObject[i] == j.

 */

// not all numbers may be in the permutation object, so this function is
// handy
function applyPermutation ( p, input )
{
    return p.hasOwnProperty( input ) ? p[input] : input;
}

// if r=p1*p2 then for any input i, r(i)=p1(p2(i))
function multiplyPermutations ( p1, p2 )
{
    // start with a deep copy of p1, made using JSON shortucts
    var result = JSON.parse( JSON.stringify( p1 ) );
    for ( var i in p2 ) {
        result[i] = applyPermutation( p1, applyPermutation( p2, i ) );
        if ( result[i] == i ) delete result[i];
    }
    return result;
}

// make a permutation from a single cycle of natural numbers
function cycleToPermutation ( cycleAsArray )
{
    var result = { };
    if ( cycleAsArray.length > 1 )
        for ( var i = 0 ; i < cycleAsArray.length ; i++ )
            result[cycleAsArray[i]] =
                cycleAsArray[(i+1)%cycleAsArray.length];
    return result;
}

// make a permutation from a series of cycles multiplied in order
function cyclesToPermutation ( arrayOfCycles )
{
    var result = { };
    for ( var i = 0 ; i < arrayOfCycles.length ; i++ )
        result = multiplyPermutations( result, arrayOfCycles[i] );
    return result;
}

// make a permutation from cycle notation in a string, like "(1 2)(7 5 3)"
function stringToPermutation ( cycleNotation )
{
    var arrayOfCycles = [ ];
    while ( !/^\s*$/.test( cycleNotation ) ) {
        var nextCycle = /^\s*\(([0-9 ]*)\)/.exec( cycleNotation );
        if ( nextCycle == null )
            throw 'Invalid cycle notation.';
        arrayOfCycles.push( cycleToPermutation(
            /^\s*$/.test( nextCycle[1] ) ? [ ] : nextCycle[1].split( ' ' )
        ) );
        cycleNotation = cycleNotation.substr( nextCycle[0].length );
    }
    return cyclesToPermutation( arrayOfCycles );
}

// this function computes the cycle notation for a permutation
function cycleNotation ( p )
{
    var result = '';
    // work with a copy, so we can mark nodes visited w/o harming the orig.
    p = JSON.parse( JSON.stringify( p ) );
    for ( var i in p ) {
        if ( p.hasOwnProperty( i ) && ( p[i] != 'VISITED' ) ) {
            var walk = i;
            var cycle = [ walk ];
            var next;
            while ( ( next = p[walk] ) != i ) {
                cycle.push( next );
                p[walk] = 'VISITED';
                walk = next;
            }
            p[walk] = 'VISITED';
            result += '(' + cycle.join( ' ' ) + ')';
        }
    }
    return result ? result : '()';
}

// this function inverts a permutation
function permutationInverse ( p )
{
    var result = { };
    for ( var i in p ) if ( p.hasOwnProperty( i ) ) result[p[i]] = i;
    return result;
}
