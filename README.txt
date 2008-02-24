Webby

* {Homepage}[http://webby.rubyforge.org/]
* {Rubyforge Project}[http://rubyforge.org/projects/webby]
* email tim dot pease at gmail dot com

== DESCRIPTION:

Webby is a super fantastic little website management system. It would be
called a _content management system_ if it were a bigger kid. But, it's
just a runt with a special knack for transforming text. And that's really
all it does - manages the legwork of turning text into something else, an
*ASCII Alchemist* if you will.

Webby works by combining the contents of a *page* with a *layout* to
produce HTML. The layout contains everything common to all the pages -
HTML headers, navigation menu, footer, etc. - and the page contains just
the information for that page. You can use your favorite markup language
to write your pages; Webby supports quite a few.

Install Webby and try it out!

== FEATURES:

* choose your templating language: *eRuby*, *Textile*, *Markdown*, *HAML*
* support for {CodeRay}[http://coderay.rubychan.de/] syntax highlighting
* quick and speedy - only builds pages that have changed
* deploy anywhere - it's just HTML, no special server stuff required
* happy {rake}[http://docs.rubyrake.org/] tasks for deploying your website to a server
* build new pages from templates for quicker blog posts and news items

But Wait! There's More!

Webby has a great _autobuild_ feature that continuously generates HTML whenever
the *pages* or *layouts* change. The HTML is served up via
{heel}[http://copiousfreetime.rubyforge.org/heel/], a static file webserver
based on mongrel. Whenever you change a page, you can immediately see those
changes without having to run any commands.

   $ rake autobuild
   heel --root output --daemonize
   -- starting autobuild (Ctrl-C to stop)
   - started at 10:21:26
   creating output/index.html
   - started at 10:22:57
   creating output/index.html

Webby is not limited to producing HTML. By no means! Do you ever get tired of
repeating the same color code <b>#D3C4A2</b> in your CSS files? Webby can help.
Need some customized JavaScript for your website. Webby can help. Anytime you
find yourself repeating the same bit of text over and over, then you should be
using Webby.

== INSTALL:

   gem install webby

== EXAMPLE:

   $ webby my_site
   creating my_site

   $ cd my_site

   $ rake create:page new_page.txt
   creating content/new_page.txt

   $ rake create:page another/new_page.txt
   creating content/another/new_page.txt

   $ rake autobuild
   heel --root output --daemonize
   -- starting autobuild (Ctrl-C to stop)
   - started at 07:01:30
   creating output/index.html
   creating output/new_page.html
   creating output/another/new_page.html

== REQUIREMENTS:

* directory_watcher
* heel
* hpricot
* logging
* rake
* rspec

== LICENSE:

MIT License
Copyright (c) 2007 - 2008

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sub-license, and/or sell copies of the Software, and to
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
