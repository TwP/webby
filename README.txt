Webby

* {Homepage}[http://webby.rubyforge.org/]
* {Rubyforge Project}[http://rubyforge.org/projects/webby]
* email tim dot pease at gmail dot com

== DESCRIPTION:

Webby is a tool for creating and managing static websites. Web pages
are written using ERB, Textile, Markdown, HAML, etc. The Webby rake tasks
transform the pages into valid HTML, and these pages can be uploaded to a
web server for general consumption.

== FEATURES:

* Provides +webby+ for creating new websites 
* Uses rake for building HTML from the pages and layouts
* Provides templates for quickly creating new pages

== INSTALL:

   gem install webby

== EXAMPLE:

   $ webby my_site
   creating my_site

   $ cd my_site

   $ rake create:page new_page.rhtml
   creating content/new_page.rhtml

   $ rake create:page another/new_page.rhtml
   creating content/another/new_page.rhtml

   $ rake build
   creating output/index.html
   creating output/new_page.html
   creating output/another/new_page.html

== REQUIREMENTS:

* rake
* rspec
* directory_watcher

== LICENSE:

MIT
