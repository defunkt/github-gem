# The GitHub Gem

This gem works hand-in-hand with GitHub's API to help you out.

Catch us in the #github room on freenode if you want to get involved.  Or just fork and send a pull request.

## Getting started

    $ gem install github

Run it:

    $ github <command> <args>
    $ gh <command> <args>

## Requirements

Only installs pure JSON gem `json_pure` by default. If you are able to install the C-extension `json` gem, it will use that instead.

Try:

    gem install json github


## Pulling Upstream Changes

Let's say you just forked `github-gem` on GitHub from defunkt.

    $ gh clone YOU/github-gem
    $ cd github-gem
    $ gh pull defunkt

This will setup a remote and branch for defunkt's repository at master. 
In this case, a 'defunkt/master' branch.

If defunkt makes some changes you want, simply `github pull defunkt`.  This will
leave you in the 'defunkt/master' branch after pulling changes from defunkt's
remote.  After confirming that defunkt's changes were what you wanted, run `git
checkout master` and then `git merge defunkt/master` to merge defunkt's changes
into your own master branch.  In summary:

    $ gh pull defunkt
    $ gh checkout master
    $ gh merge defunkt/master

If you've already reviewed defunkt's changes and just want to merge them into your 
master branch, use the `merge` flag:

    $ gh pull --merge defunkt

## Fetching and Evaluating Downstream Changes

If you are the maintainer of a project, you will often need to fetch commits
from other developers, evaluate and/or test them, then merge them into the
project.

Let's say you are 'defunkt' and 'mojombo' has forked your 'github-gem' repo,
made some changes and issues you a pull request for his 'master' branch.

From the root of the project, you can do:

    $ gh fetch mojombo master
  
This will leave you in the 'mojombo/master' branch after fetching his commits.
Your local 'mojombo/master' branch is now at the exact same place as mojombo's 
'master' branch. You can now run tests or evaluate the code for awesomeness.

If mojombo's changes are good, you'll want to merge your 'master' (or another
branch) into those changes so you can retest post-integration:

    $ gh merge master
  
Test/analyze again and if everything is ok:
  
    $ gh checkout master
    $ gh merge mojombo/master
  
The latter command will be a fast-forward merge since you already did the
real merge previously.

## Network Patch Queue

The github gem can also show you all of the commits that exist on any fork of your
project (your network) that you don't have in your branch yet.  In order to see
the list of the projects that have commits you do not, you can run:

    $ gh network list

Which will show you all the forks that have changes.  If you want to see what those
changes are, you can run:

    $ gh network commits

which will show you something like this:

    9582b9 (jchris/gist)             kevin@sb.org          Add gist binary                        4 months ago
    c1a6f9 (jchris/gist~1)           kevin@sb.org          Tweak Rakefile spec tasks to be a bi   4 months ago
    d3c332 (jchris/gist~2)           kevin@sb.org          Pull out two helpers into the shared   4 months ago
    8f65ab (jchris/gist~3)           kevin@sb.org          Extract command/helper spec assistan   4 months ago
    389dbf (jchris/gist~4)           kevin@sb.org          Rename ui_spec to command_spec         4 months ago
    670a1a (jchris/gist~5)           kevin@sb.org          Hoist the specs into a per-binary sp   4 months ago
    6aa18e (jchris/gist~6)           kevin@sb.org          Hoist commands/helpers into a per-co   4 months ago
    ee013a (luislavena/master)       luislavena@gmail.com  Replaced STDOUT by $stdout in specs.   2 weeks ago
    d543c4 (luislavena/master~3)     luislavena@gmail.com  Exclude package folder.                8 weeks ago
    a8c3eb (luislavena/master~5)     luislavena@gmail.com  Fixed specs for open under Windows.    5 months ago
    33d003 (riquedafreak/master)     enrique.osuna@gmail.  Make sure it exists on the remote an   5 weeks ago
    157155 (riquedafreak/master~1)   enrique.osuna@gmail.  Updated specs.                         5 weeks ago
    f44e99 (riquedafreak/master~3)   enrique.osuna@gmail.  Only work with a clean branch.         3 months ago

These are all the commits that you don't have in your current branch that have been
pushed to other forks of your project.  If you want to incorporate them, you can use:

    $ gh cherry-pick ee013a

for example to apply that single patch to your branch.  You can also merge a branch, 
if you want all the changes introduced in another branch:

    $ gh merge jchris/gist

The next time you run the 'github network commits' command, you won't see any of the 
patches you have cherry-picked or merged (or rebased).  If you want to ignore a 
commit, you can simply run:
  
    $ gh ignore a8c3eb

Then you won't ever see that commit again. Or, if you want to ignore a range of commits,
you can use the normal Git revision selection shorthands - for example, if you want
to ignore all 7 jchris/gist commits there, you can run:

    $ gh ignore ..jchris/gist

You can also filter the output, if you want to see some subset.  You can filter by project,
author and date range, or (one of the cooler things) you can filter by whether the patch
applies cleanly to your branch head or not.  For instance, I can do this:

    $ ./bin/github network commits --applies

    ca15af (jchris/master~1)         jchris@grabb.it       fixed github gemspecs broken referen   8 weeks ago
    ee013a (luislavena/master)       luislavena@gmail.com  Replaced STDOUT by $stdout in specs.   2 weeks ago
    157155 (riquedafreak/master~1)   enrique.osuna@gmail.  Updated specs.                         5 weeks ago
    f44e99 (riquedafreak/master~3)   enrique.osuna@gmail.  Only work with a clean branch.         3 months ago

    $ ./bin/github network commits --applies --project=riq

    157155 (riquedafreak/master~1)   enrique.osuna@gmail.  Updated specs.                         5 weeks ago
    f44e99 (riquedafreak/master~3)   enrique.osuna@gmail.  Only work with a clean branch.         3 months ago

Pretty freaking sweet.  Also, you can supply the --shas option to just get a list of 
the shas instead of the pretty printout here, so you can pipe that into other 
scripts (like 'github ignore' for instance).


## Issues

If you'd like to see a summary of the open issues on your project:

    $ gh issues open

    -----
    Issue #135 (2 votes): Remove Node#collect_namespaces
    *  URL: http://github.com/tenderlove/nokogiri/issues/#issue/135
    *  Opened 3 days ago by tenderlove
    *  Last updated about 1 hour ago
  
    I think we should remove Node#collect_namespaces.  Since namespace names are not unique, I don't know that this method is very useful.
    -----
    Issue #51 (0 votes): FFI: support varargs in error/exception callbacks
    *  URL: http://github.com/tenderlove/nokogiri/issues/#issue/51
    *  Opened 4 months ago by flavorjones
    *  Last updated about 1 month ago
    *  Labels: ffi, mdalessio
  
    we should open JIRA tickets for vararg support in FFI callbacks
  
    then we should format the libxml error messages properly in the error/exception callbacks
    -----

If you want to additionally filter by time:

    $ gh issues open --after=2009-09-14

Or filter by label:

    $ gh issues open --label=ffi

## Contributors

* defunkt
* maddox
* halorgium
* kballard
* mojombo
* schacon
* drnic

