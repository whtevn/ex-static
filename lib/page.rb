  class Page
    include FileBase

    cattr_accessor :pages
    @@pages=[]
    attr_accessor :name, :subs, :page_location, :contents, :stylesheets, :index, :site_location, :site_base, :breadcrumbs
    @@templates = {}
    
    def initialize(name, home, location, generate_to, subs=nil, index=nil)
      @home = home
      @page_location = location
      @name = name
      @subs = subs
      @site_base = generate_to.as_folder
      @index = index
      @breadcrumbs = []
      @stylesheets = []
      pages << self
    end

    def included_in? page_name, all_levels=false
      ans = (file_name == page_name.to_s or Page.find(page_name).subs.include? name)
      subs.each { |sub| ans = Page.find(sub.as_file).included_in?(page_name, all_levels) } if all_levels and !ans
      ans
    end

    def file_name
      name.as_file
    end
    def to_s
      name.downcase
    end
    def self.find(name)
      item = nil
      name = name.to_s
      self.pages.each{ |p| item = p if p.file_name==name.as_file}
      item
    end

    def index?; @index end

    def generate collection_name
      stylesheets << contents['stylesheets'] if contents['stylesheets']
      mkdir in_site_location unless exists?(:folder, in_site_location) or index?
      collection = load_collection(collection_name) if collection_name
      if collection
        Generator.class_eval { cattr_accessor :include_text } 
        Generator.include_text = File.read home+"blueprint/#{page_location}_#{collection_name}_for_#{file_name}/#{collection.first}"
        write ::Rbml::Processor.new.instance_eval(File.read(home+'base/default.rbml')), in_site_location+'index.html' 
  puts 'writing the index'
        collection.each { |col|
        Generator.include_text = File.read home+"blueprint/#{page_location}_#{collection_name}_for_#{file_name}/#{col}"
        write ::Rbml::Processor.new.instance_eval(File.read(home+'base/default.rbml')), in_site_location+col+'.html'
  puts "writing the entry for #{col}"
        } 
        Generator.class_eval { @include_text = nil } 
      else
        write ::Rbml::Processor.new.instance_eval(File.read(home+'base/default.rbml')), in_site_location+'index.html'
      end
      puts "writing #{in_site_location}index.html"
    end

    def load_collection name
      stuff = nil
      File.open(home+ 'blueprint/'+page_location+"_#{name}_for_#{file_name}/page.list") { |yf| stuff  = YAML::load( yf ) }
      stuff
    end

    def in_site_location
      (index? ? site_base : ( has_subs? && subs.kind_of?(Array) ? site_base+page_location : site_base+page_location+name.as_file )).as_folder
    end
    def in_site_link
      in_site_location.sub(site_base, '')
    end
    def level
      tmp = (index? || has_subs? && subs.kind_of?(Array)) ? '' : '../' 
      tmp+page_location.gsub(/\w+\//, '../')
    end

    def menu_title
      case subs
      when Array : name
      when String : subs
      else
        nil
      end
    end
    
    def load_contents
      File.open(home+ 'contents/'+page_location+name.as_file+'.copy') { |yf| @contents  = YAML::load( yf ) } rescue puts $!
    end
    def save_contents
      File.open(home+ 'contents/'+page_location+name.as_file+'.copy',  'w') { |yf| YAML.dump(@contents,  yf) }
    end

    def extentions
      {
        :contents  => '.copy',
        :blueprint => '.rbml',
        :page      => '.html'
      }
    end

    def make(type)
      page_path =  home+type.to_s+'/'+page_location
      mkdir page_path unless exists? :folder, page_path
      template_file = case type
      when :contents : {:main => home+'layout/copy/page.copy', :sub => home+'layout/copy/submenu.copy'}
      when :blueprint : {:main => home+'layout/contents.erbml', :sub => home+'layout/submenu.erbml'}
      end

      if subs && subs.kind_of?(Array) 
        unless exists?(:file, page_path+'submenu'+extentions[type])
          unless type == :contents
            write_template template_file[:sub], page_path+'_submenu'+extentions[type] 
            puts "writing #{page_path}submenu#{extentions[type]}"
          end
        else
          puts "#{page_path}submenu#{extentions[type]} already exists"
        end
      end
      unless exists?(:file, page_path+name.as_file+extentions[type])
      write_template template_file[:main], page_path+name.as_file+extentions[type]
      puts "writing #{page_path}#{name.as_file}#{extentions[type]}"
      else
        puts "#{page_path}#{name.as_file}#{extentions[type]} already exists"
      end
    end

    def has_subs?
      subs && !subs.empty? 
    end
  end


