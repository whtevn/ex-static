=== static
    by evan short

== DESCRIPTION:
  
static is a command line environment for creating static websites.
it uses a yaml site map to produce a blueprint with decoupled copy
and structure.  uses rbml for html processing. static incorporates
arbitrary collections that can be displayed both within a page and
paginated over a page. this allows such features as news, faqs,
blogs and other galleries.

== FEATURES:

- command line interface
- multiple site management
- yaml site map
- decoupled copy and structure
  - flexible, sectioned copy
  - html in block-syntax
- collections
  - inner-page, such as news on a home page
  - paginated, a blog, for instance
- plain ol' css for style

== PROBLEMS:

- cli needs some work
  - prompt context
  - tab completion
  - termios integration (or otherwise implemented command history)
  - better error messaging
- documentation
  - how layouts work
  - how blueprints work
- there are no specs
- ready for a re-factor

if i had to guess i would say that this will not work on windows. it
is organized for a mac, but works fine, im sure, under unix in general
i don't know that much about cygwin.  i don't anticipate fixing this myself
(or even look into it) without some incentive. i will happily take patches.

== TODO:

- deal with resources (e.g. images, movies, etc)
- allow +display+ to take a block describing the layout
- command to preview in browser 
- give better program hooks in the static home
- allow pages to override the default layout
- allow collections to override the default layout
- give a method to display the site map
- rename partials with underscores
- option to turn links off if current
- stop css from being overwritten when re-generating the blueprint
- simple site versioning
- css versioning
- page splitting in copy

== USAGE NOTES:

so, first thing's first open up a terminal and run static. the first
time it is run a folder called +static+ will be created in your <tt>~/</tt>.
in this folder your layouts and projects will be kept, along with a
few template files in <tt>.templates</tt> that will be used when
creating a site.

=== site generation

you will see a prompt: <tt>-></tt>

  -> start sample site
  starting a site map for sample

at this point the footprint of your site (named sample in this example) 
has been created. a sitemap is generated from the site.map template
in the static home (~/static). initially this is populated with an
example map, but can be re-formatted or emptied if you choose.

  -> edit site.map

this will open the previously mentioned site map in vi. there is a
variable to change editors but, currently, no place to actually do
it. sue me. i'll get to it soon.

after the site map has been exited the pages are loaded into memory
and you can then begin to build your site.

  -> build

or
  
  -> build copy

will generate the .copy yaml files that will hold the contents of each
page in your site map. you may then run

  -> edit copy

to edit the contents of those pages. more desireably, perhaps, you may
zip this folder up and send it off to someone more suited to edit copy.

some things to note when editing copy:

- this must be a properly formatted yaml file
  - use <tt>: |</tt> followed by an indented block of text to use multiline text in yaml
  - use *s instead of -s to indicate list elements underneath <tt>: |</tt>s

if it is not a properly formatted yaml file, generate will simply fail. you will hardly
be given an error message, and certainly nothing helpful. it is for this reason i 
suggest you check your contents files twice before sending them through the grinder.
definitely some robustness or something needed here.
given no me you will simp

anyway, next you must choose a layout. 

  -> layout

will give you a choice of the possible layouts. by default there is only
one layout available. you may copy the default layout in the static home
to create new layouts. there are plans to incorporate some of this into
the cli. not yet, however.

because there is only one layout available by default, running +layout+
will choose it for you. if there were more than one you could run +layout+
with a regex for the layout you would like to choose (or  not) and then
make a choice from the resulting list. choices in lists may be made by
regex or number selection. no word on what happens if there are numbers
in your possible selections.

as an example, because the word 'regex' can be frightening to some, i might
use <tt>layout def</tt> to find the default layout in a long list of selections.

once a layout is chosen it is possible to make edits to it before building
the basic structure of the site, called the blueprint. you may run

  -> edit layout

to make changes to the layout you have chosen.

once the layout is satisfactory, running

  -> build blueprint

will put the blueprint folder in place.

  -> edit blueprint

will take you there to edit. 

to build the copy, choose a layout, and build the blueprint in one go:

  -> build all

it is worth noting that the edit commands may be used at any time, not only 
directly after building that particular section.

either way you get here, at this point you may generate your site by running

  -> generate

you may edit your site and generate as many times as you like.
by default (not easily changable at the moment) your site will be
generated to ~/Sites/static/name_of_site. 

use
  
  -> load site

(which uses the choice module) to load a site or make a different 
site active. you may simply use +load+ if there is not already an
active site.

== collection managment

once a site has been started that site will be active. once there is
an active site you may begin dealing with collections. to start a 
collection 

  -> start faq collection with question answer

this will start a collection named faq with the attributes question and
answer.

because there is already an active site, the +collection+ key 
is assumed and therefore sugar. +with+ is purely sugar.

the faq collection is now active (as it was just started and no other
collection has been loaded). you may run

  -> edit attributes

to edit the yaml file describing the attributes

  -> edit display

to edit the default way a member of the collection is displayed

and

  -> add

to add an item to the collection. it is worth noting that the attribute
files are processed by erb before they make it to your editor. so in the
event you had a +date+ attribute in a collection, using +edit attributes+
to make <tt>date: <%= Date.today.to_s.inspect %></tt> will start each
added item with today's date ready for yaml.

to show a collection within a page add a line like

  display 5, :faq

on the blueprint of the desired page. display also responds to :all in place
of the number.

to paginate a collection over a particular page you must assign the 
collection to the page. 

  -> assign

will ask you first which collection you would like to choose and then which
page. because each page is only allowed to be paginated once your choices
will be limited to those that have not already been paginated. you may use
-c or --collection to regex for a desired collection.
likewise with -p and --page.

you may also run +assign paginate+ with the same possible flags to paginate
the collection automatically after the association.

after associating the collection and the page you may use

  -> paginate

and then

  -> generate

to update the pages. in the future there should probably be a more direct
way to generate over only paginated pages.

in order to see the paginated items on the desired page simply add the line

  include_partial

where you would like the paginated section of your collection to be included.
to use the link list generated include the line

  get :page, :collection_name => :links

<tt>:page</tt> is short for 'this page that we are in'. if you would like to
be moroe explicit (or use the list elsewhere) simply put in the file name of
the page (which would be the page name you gave it in the site map formatted
as a lower-case symbol) as such:

  get :page_name, :collection_name => :links

== A Note from the Author

there is much more to say, and there is no doubt that this is a first release,
but a lot of what is going on can be gleaned by looking at the stuff that is
generated by default. any questions may be directed to

  evan.short @ pleasedontspam. gmail.please

suggestions and criticisms are welcome. i am aware that when things go sour
there is often no word as to what actually went wrong. you can tell me 
about them if you feel so inclined, but i am of the opinion that some more
reasonable error messaging needs to happen in rbml rather than too much 
more effort going into my dilligence at writing horribly nested if statements
in the cli script.

== REQUIREMENTS:

rbml v. 0.0.5.9.4.1

== INSTALL:

i looked into it briefly but found nothing about actually making a dependency
in a gem. if anyone knows how to do this, please let me know. 

  sudo gem install rbml
  sudo gem install static

== LICENSE:

(The MIT License)

Copyright (c) 2007 Evan Short

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
