

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'yaml'
require 'erb'
require 'singleton'

require 'extentions/string'
require 'extentions/class'

require 'filebase'

require 'site'
require 'page'

require 'collection'
require 'generator'


require 'rubygems'
require 'rbml'

require 'xhtml'

$ENV = {}

module Static
  VERSION = '0.1.3'
  include FileBase

  def setup_home
    $ENV['EDITOR'] = 'vi'
    $ENV['STATIC_HOME'] = "#{ENV['HOME']}/static/"
    $ENV['STATIC_VIEWING'] = "#{ENV['HOME']}/Sites/static/"
    $ENV['REPO_HOME'] = $ENV['STATIC_HOME']+'/repos/'
    $ENV['SITE_BANK'] = $ENV['STATIC_HOME']+'projects/'
    $ENV['TEMPLATE_HOME'] = $ENV['STATIC_HOME']+'.templates/'
    $ENV['LAYOUT_HOME'] = $ENV['STATIC_HOME']+'layouts/'
    $ENV['SCRIPT_HOME'] = $ENV['STATIC_HOME']+'lib/'
    $ENV['TEMPLATE_BANK'] = File.dirname(__FILE__)+'/../templates'
  end

  def start_site name
    site = Site.start($ENV['SITE_BANK'], name, $ENV['STATIC_VIEWING'], $ENV['TEMPLATE_HOME'])
    site
  end

  def load_site name
    Site.load($ENV['SITE_BANK'], name, $ENV['STATIC_VIEWING'], $ENV['TEMPLATE_HOME']) if name
  end

  def set_layout which, force
    return nil unless which
    destroy $active_site.home+'layout/' if force
    $active_site.set_layout(which, $ENV['LAYOUT_HOME']) unless exists? :folder, $active_site.home+'layout/'
    $active_site.save_info('site.info')
  end

  def start_collection name, attrs=[]
    Collection.start $ENV['STATIC_HOME'], $active_site.home, name, attrs
  end
  def load_collection name
    Collection.load $ENV['STATIC_HOME'], $active_site.home, name.to_s
  end

  def assign_pagination collection, page
    collection = collection.to_s
    page = page.to_s
    $active_site.info['paginate'] ||= {}
    $active_site.info['paginate'].merge!({page => collection}) unless $active_site.info['paginate'].include?({page => collection})
    $active_site.save_info
  end

  def paginate page, publishing_to=nil
    return nil unless page
    @page = Page.find(page)
    Generator.load(load_collection($active_site.info['paginate'][@page.file_name]))
    Generator.class_eval {
      def self.entry_bank
        if @tmp_entries and @tmp_entries.empty?
          @tmp_entries = nil
          return @tmp_entries
        end
        @tmp_entries ||= self.act_on.entries.dup
        @tmp_entries
      end
      def self.entry_bank= what
        @tmp_entries = what
      end
    }
    publishing_to ||= "#{@page.home}blueprint/#{@page.page_location}_#{Generator.act_on.name}_for_#{@page.file_name}/"
    mkdir publishing_to, :force 
    @page_list = []
    Generator.act_on.instance_eval { def level; @level end; def level=(what); @level=what end }
    Generator.entry_bank 
    while(Generator.entry_bank)
      rbml = ::Rbml::Processor.new
      #Generator.contents = {:id => entry_bank.first[:id]}
      publish_file = File.read(Generator.act_on.home+'paginate')
      id = Generator.entry_bank.first[:id]
      puts "writing partial for #{id}"
      hold = Generator.entry_bank.dup
      begin
        write rbml.render('xhtml', rbml.load_language('xhtml'), :partial => true) { eval(publish_file) }, publishing_to+id
      rescue
        Generator.entry_bank = hold
        write rbml.render('xhtml', rbml.load_language('xhtml'), :format => false, :partial => true) { eval(publish_file) }, publishing_to+id rescue puts $!
      end
      @page_list << id
      File.open(publishing_to+'page.list',  'w') { |yf|  YAML.dump(@page_list,  yf) }
      write_template Generator.act_on.home+'link_list', "#{@page.home}blueprint/#{@page.page_location}/_#{@page.file_name}_#{Generator.act_on.name}_links.rbml" rescue puts "writing template -- #{$!}"
      puts "writing link list _#{@page.file_name}_#{Generator.act_on.name}_links"
    end
    @page_list = nil
    Generator.act_on.instance_eval { @level = nil; undef :level; undef :level=}
    Generator.unload
  end
  
  def publish_feeds blank = nil
    $active_site.info['feeds'].each do |name|
      col = load_collection(name) #Generator.load(name).inspect
      col.load_entries
      col.publish
      Generator.load col
      Generator.act_on.instance_eval {
        def level; @level end; def level=(what); @level=what end
        def last_built
          date = ''
          listing.each {|item| date = item[:publish] if item[:publish] and not date}
          date
        end
      }
      write ::Rbml::Processor.run(col.home+'feed'), $active_site.site_loc.as_folder+name+'.rss'  rescue puts $!
      puts $active_site.site_loc.as_folder+name+'.rss' 
      Generator.act_on.instance_eval { @level = nil; undef :level; undef :level=}
      Generator.unload
    end if $active_site.info['feeds']

    unless blank
      puts "rsync -avz #{$active_site.site_loc}/* #{$active_site.info['user_name']}@#{$active_site.info['server']['address']}:#{$active_site.info['server']['directory']}"
      system "rsync -avz #{$active_site.site_loc}/* #{$active_site.info['user_name']}@#{$active_site.info['server']['address']}:#{$active_site.info['server']['directory']}"
    end
  end
end

