
# Build process definitions

This file defines the build processes in this repository. It is imported by
the `Cakefile` in this repository, the source code of which is kept to a
one-liner, so that most of the repository can be written in [the literate
variant of CoffeeScript](http://coffeescript.org/#literate).

We keep a set of build utilities in a separate module, which we now load.

    build = require './buildutils'

## Easy way to build all

If you want to build and test evertything, just run `cake all`. It simply
invokes all the other tasks, defined below.

    build.task 'all', 'Build app and run tests', ->
        build.enqueue 'app'

## Requirements

Verify that `npm install` has been run in this folder, then import other
modules we'll need later (which were installed by npm install).

    build.verifyPackagesInstalled()
    fs = require 'fs'
    exec = require( 'child_process' ).exec

## Constants

These constants define how the functions below perform.

    p = require 'path'
    srcdir = p.resolve __dirname, 'src'
    srcorder = [
    ]
    srcout = 'app.litcoffee'
    appdir = 'app'

## The `app` build process

    build.asyncTask 'app', 'Build the main app', ( done ) ->

Before building the app, ensure that the output folder exists.

        fs.mkdirSync appdir unless fs.existsSync appdir

Compute size of folder prefix, for showing relative paths later, for
brevity.

        L = __dirname.length + 1

Next concatenate all `.litcoffee` source files into one.  We also respect
the ordering in `srcorder` to put some of the files first on the list.

        all = build.dir srcdir, /.litcoffee$/
        moveup = [ ]
        for file in srcorder
            moveup = moveup.concat ( fullpath for fullpath in all \
                when RegExp( "/#{file}$" ).test fullpath )
        all = ( file for file in all when file not in moveup )
        all = moveup.concat all
        build.concatFiles all, '\n\n', p.resolve appdir, srcout

Run the compile process defined in [the build utilities
module](buildutils.litcoffee).  This compiles, minifies, and generates
source maps.  We run it on the source files.

        build.compile p.resolve( appdir, srcout )

## The `pages` build process

After changes are made to the master branch of this repository in git, we
eventually want to propagate them to the gh-pages branch, because that
branch is the one that github uses as the basis for the project web pages
(hence the name, short for "github pages"). Usually you should do this
before pushing commits to github, so that the website on github reflects the
latest state of the repository.

This build task switches to the gh-pages branch, merges in all changes from
master, re-runs all other build tasks, commits the resulting documentation
changes, and switches branches back to master.  It's just what you should
run before pushing to github.

It's an asynchronous task because it uses `exec`.  We begin with switching
to gh-pages and merging in changes.

    build.asyncTask 'pages',
    'Update gh-pages branch before pushing', ( done ) ->
        console.log '''
            In case any step of this lengthy process goes wrong,
            here are the commands that are about to be run, so
            that you can complete the process:
                git checkout gh-pages
                git merge master --no-commit
                cake app submodules
                git commit -a -m 'Updating gh-pages with latest app build'
                git checkout master
            '''.yellow
        build.runShellCommands [
            description : 'Switching to gh-pages branch...'.green
            command : 'git checkout gh-pages'
        ,
            description : 'Merging in changes...'.green
            command : 'git merge master --no-commit'
        ], ->
            console.log 'Building app and submodules in gh-pages...'.green
            build.enqueue 'app', 'submodules', ->
                build.runShellCommands [
                    description : 'Committing changes... (which may fail if
                        there were no changes to the app itself; in that
                        case, just git checkout master and push.)'.green
                    command : "git commit -a -m 'Updating gh-pages with
                        latest generated docs'"
                ,
                    description : 'Going back to master...'.green
                    command : 'git checkout master'
                ], ->
                    console.log 'Done.'.green
                    console.log '''
                    If you're happy with the results of this process, just \
                    type "git push" to publish them.
                    '''

We report that we're done with this task once we enqueue those things, so
that the build system will then start processing what we put on the queue.

            done()
