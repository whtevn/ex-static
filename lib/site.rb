class Site
  include FileBase

  attr_accessor :name, :map, :info, :pages, :main_links, :site_loc

  def initialize(where, name, generate_to, templates=nil)
    set_home where+name
    @name = name
    @pages = []
    @main_links = []
    mkdir generate_to unless exists? :folder, generate_to
    @site_loc = generate_to + name
  end

  def self.load(where, name, generate_to, templates)
    return nil unless self.site_exists?(where, name)
    s = self.new(where, name, generate_to, templates)
    s.load_info
    s.load_pages
    s
  end

  def self.site_exists?(where, name)
    (exists?(:folder, where+name) && exists?(:folder, where+name+'/project_info'))
  end
  def self.start where, name, generate_to, templates
    return nil if self.site_exists?(where, name)
    site = Site.new(where, name, generate_to, templates)
    site.mkdir(site.home+'project_info')
    site.copy(templates+'helpers', site.home) rescue puts $!
    site.setup_location 'project_info'
    site.write_template templates+'site.map', site.path+'site.map'
    site.write_template templates+'site.info', site.path+'site.info'
    site.load_info
    site
  end

  def load_info(file=nil)
    File.open(home+ 'project_info/site.map') { |yf| @map  = YAML::load( yf ) } unless file=='site.info'
    File.open(home+'project_info/site.info') { |yf| @info = YAML::load( yf ) } unless file=='site.map'
  end

  def save_info(file=nil)
    File.open(home+'project_info/site.map',  'w') { |yf| YAML.dump(@map,  yf) } unless file=='site.info'
    File.open(home+'project_info/site.info', 'w') { |yf| YAML.dump(@info, yf) } unless file=='site.map'
  end

  def set_layout(name, address)
    copy address+name, home+'layout/' unless exists? :folder, home+'layout' rescue puts $! 
    info['layout'] = {'name' => name, 'address' => address}
  end
  
  def load_pages
    gather_pages
    make_breadcrumbs
  end
  def gather_pages(page=nil, first_time=true, parent=nil)
    index = nil
    if first_time
      reset_location
      @pages = []
      page ||= map
    else
      index = true if @pages.empty?
    end
    case page
    when String : pages << Page.new(page, home, location, site_loc, parent, index)
    when Array then
      tmp = page.dup
      gather_pages(tmp.shift, false, parent) while(tmp.size > 0)
    when Hash then
      page.each { |page_name, sub_pages|
        unless first_time 
          set_location(pages.empty? ? location : location+page_name )
          pages << Page.new(page_name, home, location, site_loc, sub_pages, index) 
        else
          page_name = nil
        end
        gather_pages(sub_pages, false, page_name)
        set_location location.sub(page_name.as_file+'/', '') if page_name
      }
    else
      return nil
    end
  end

  def make_breadcrumbs
    pages.each do |page|
      page.breadcrumbs << page.name.as_file
      page.subs.each { |p|
        if p.kind_of?(Hash)
          p.each{ |k, v|
            tmp = Page.find(k)
            tmp.breadcrumbs << page.breadcrumbs }
        else
          tmp = Page.find(p).breadcrumbs << page.breadcrumbs  
        end
      } if page.has_subs? && page.subs.kind_of?(Array)
      page.breadcrumbs.flatten!
    end
  end
  
  def load_main_links
    map['site_map'].each { |page|
      case page
      when String
        main_links << page
      when Hash
        page.each { |name, subs| main_links << name }
      end
    }
  end

  def build_header
    write_template home+"layout/page_head.erbml", home+'base/page_head.rbml'
    write_template home+"layout/main_navigation.erbml", home+'base/main_navigation.rbml'
  end

  def build(type)
    setup_location(type.to_s)
    if type == :blueprint
      @main_links = []
      copy home+'layout/structure', home+'base'
      begin
        copy home+'layout/stylesheets', home+'base/stylesheets'
        puts 'copied stylesheets'
      rescue
        puts "There are no stylesheets associated with this layout"
      end
      copy home+'layout/resources', home+'base/resources' rescue puts "There are no resources associated with this layout"
      copy home+'layout/scripts', home+'base/scripts' rescue puts "There are no scripts associated with this layout"
      load_main_links 
      build_header 
    end
    pages.each{|page|  page.make(type)}
  end

  def generate
    mkdir site_loc unless exists? :folder, site_loc
    copy home+'base/stylesheets', site_loc rescue puts $!
    copy home+'base/resources', site_loc rescue puts $!
    copy home+'base/scripts', site_loc rescue puts $!
    pages.each do |page|
      page.stylesheets = []
      Generator.load(page)
      page.load_contents
      page.stylesheets << info['stylesheets'] if info['stylesheets']
      page.generate info['paginate'] ? info['paginate'][page.file_name] : nil rescue puts "site generator -- #{$!}"
      Generator.unload
    end
  end
end

