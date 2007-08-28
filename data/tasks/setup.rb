
require 'ostruct'

SITE = OpenStruct.new

SITE.content_dir   = 'content'
SITE.output_dir    = 'output'
SITE.layout_dir    = 'layouts'
SITE.template_dir  = 'templates'
SITE.exclude       = %w[tmp$ bak$ ~$ CVS \.svn]
  
SITE.page_defaults = {
  'extension' => 'html',
  'layout'    => 'default'
}

SITE.host       = 'user@hostname.tld'
SITE.remote_dir = '/not/a/valid/dir'
SITE.rsync_args = %w(-av --delete)

FileList['tasks/*.rake'].each {|task| import task}

%w(heel).each do |lib|
  Object.instance_eval {const_set "HAVE_#{lib.upcase}", try_require(lib)}
end

# EOF
