# These are the main configuration options for Webby. Options for specific
# filters and helpers are defined in those files. Even a few of the rake
# tasks in the "examples" folder have their own configuration options
# defined.
#
# The nice thing about Loquacious configurations is that all these options
# can be defined where they are used, but the descriptions can be viewed by
# the user in one handy page.

Loquacious.configuration_for(:webby) {

  desc 'The generated website will be output to this directory.'
  output_dir 'output'

  desc <<-__
    The directory containg the main site content - pages, partials, css
    stylesheets, etc.
  __
  content_dir 'content'

  desc 'The directory containing the layout files.'
  layout_dir 'layouts'

  desc <<-__
    The directory where page templtes can be found. These templates are used
    by the 'webby create' command to define the boiler-plate for new pages
    (things like the meta-data or standard text).
  __
  template_dir 'templates'

  desc <<-__
    This is an array of regular expression patterns that will exclude files
    from webby processing. The patterns will be joined using the regular
    expression OR operator '|'.
  __
  exclude %w{tmp$ bak$ ~$ CVS \.svn}

  desc <<-__
    A set of default meta-data values that are added to every page rendered
    by webby. Specific values in the page override the default values
    defined here. For example, you could define a default set of filters
    |
    |   SITE.page_defaults = {
    |     'layout' => 'default',
    |     'filter' => ['erb', 'textile']
    |   }
    |
    Now, every page will be run through the ERB filter and then the
    Textile filter. Specific pages can override the set of filters or omit
    them altogether as needed.
  __
  page_defaults({
    'layout' => 'default'
  })

  desc <<-__
    Defines the default page attribute that will be used by the
    'link_to_page' method to find other pages in the site. If this value
    is set to :title, then the title found in the page meta-data is
    searched for a match. If this value is set to :filename, then the
    filenames of pages are search for a match.

    This value can be overridden on a case by case basis when the
    'link_to_page' method is called.
  __
  find_by :title

  desc <<-__
    Using the 'webby create' task, new pages can either be created as a
    normal page or as an index page in it's own directory. The latter
    option allows your pages to have "nice" URLs:
    |
    |   foo/bar/my-new-post.html    <-- 'page'
    |   foo/bar/my-new-post/        <-- 'directory'
    |
    The two options supported by the 'create_mode' are either 'page'
    or 'directory'.
  __
  create_mode 'page'

  desc <<-__
    When the 'webby create' task is used to create a new page in your site,
    webby will automatically open your favorite editor. Use this option to
    define which editor webby will start. Set this option to nil if you do
    not want webby to launch an editor when you create new pages.

    The default is taken from the environment as either 'WEBBY_EDITOR' or
    'EDITOR', whichever is defined.
  __
  editor ENV['WEBBY_EDITOR'] || ENV['EDITOR']

  desc <<-__
    This flag determines whether or not the internal web server is launched
    when the autobuild loop is running. The default is to launch the web
    server. Set to false to disable.
  __
  use_web_server true

  desc <<-__
    Defines the port number the internal web server will use when the
    autobuild loop is running.
  __
  web_port 4331

  desc <<-__
    The username that will be used when publishing a site to the remote host.
    Login to the remote host will take the form 'user@host' where both 'user'
    and 'host' are configuration options.

    The default is taken from the environment as either 'USER' or
    'USERNAME', whichever is defined.
  __
  user ENV['USER'] || ENV['USERNAME']

  desc <<-__
    The hostname that will be used when publishing a site to the remote host.
    Login to the remote host will take the form 'user@host' where both 'user'
    and 'host' are configuration options.
  __
  host 'example.com'

  desc <<-__
    The destination directory on the remote host where the site will
    be published.
  __
  remote_dir '/dev/null'

  desc <<-__
    Arguments that will be passed to the rysnc command when deploying the
    site to the remote host. This array of arguments will be joined together
    by spaces.
  __
  rsync_args %w(-av)

  desc <<-__
    The list of URIs that will automatically pass validation when the webby
    validate task is run.
  __
  valid_uris []

  desc <<-__
    The base URL of the site. This value is used by the 'basepath' filter to
    replace leading slashes in URIs with this base value. The URIs to replace
    are identified by the 'xpaths' option.
  __
  base nil

  desc <<-__
    The basepath filter is used to replace leading slashes in URIs with the
    text from the 'base' option. Only those URIs identified by the XPaths
    defined here will be altered. You can add to or remove XPaths from this
    list depending on your needs.
  __
  xpaths %w{
      /html/head//base[@href]
      /html/head//link[@href]
      //script[@src]
      /html/body[@background]
      /html/body//a[@href]
      /html/body//object[@data]
      /html/body//img[@src]
      /html/body//area[@href]
      /html/body//form[@action]
      /html/body//input[@src]
  }
  # other possible XPaths to include for base path substitution
  #   /html/body//object[@usemap]
  #   /html/body//img[@usemap]
  #   /html/body//input[@usemap]

  desc "The default directory where new blog posts will be created."
  blog_dir 'blog'

  desc "The default directory where new tumblog posts will be created."
  tumblog_dir 'blog'
}

# EOF
