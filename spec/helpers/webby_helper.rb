
# Add a datapath method to webby
module Webby
  DATAPATH = ::Webby.path(%w[spec data])
  def self.datapath( *args )
    args.empty? ? DATAPATH : ::File.join(DATAPATH, args.flatten)
  end
end

module WebbyHelper
  def webby_site_setup
    before(:all) do
      @pwd = Dir.pwd
      Dir.chdir Webby.datapath('site')
      FileUtils.mkdir_p Webby.datapath('site', ::Webby.site.output_dir)
    end

    after(:all) do
      FileUtils.rm_rf(Webby.datapath('site', ::Webby.cairn))
      FileUtils.rm_rf(Dir.glob(Webby.datapath(%w[site output *])))
      Dir.chdir @pwd
    end
  end
end
