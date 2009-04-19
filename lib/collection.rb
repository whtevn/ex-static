class Collection
  attr_accessor :name, :attrs, :base, :listing, :entries, :contents, :unpublished
  include FileBase
  def initialize base, where, name
    set_home where
    @base = base
    @name = name
    @attrs = []
    @listing = []
    @entries = []
    @unpublished = []
    setup_location 'collections'
    set_home path+name
  end

  def file_name
    name.as_file
  end

  def self.start base, where, name, attrs
    return nil if self.collection_exists?(base, where, name)
    c = self.new base, where, name
    c.attrs << attrs
    c.attrs.flatten!
    c.write_attribute_file 
    c.load_attributes
    c.write_display_file rescue puts $!
    c.write_feed_file
    copy base+'.templates/disco/link_list', c.home
    c.write_paginate_file
    c.write '', c.home+'listing'
    c.mkdir c.home+'entries'
    c
  end

  def display_file
    home+'display'
  end
  def self.collection_exists?(base, where, name)
    exists?(:folder, base) && exists?(:folder, where+'collections/'+name) && exists?(:file, where+"collections/#{name}/attributes")
  end
  def self.load base, where, name
    return nil unless self.collection_exists?(base, where, name)
    c = self.new base, where, name
    c.load_attributes
    c.load_listing
    c.sanitize_listing
    c.load_entries
    c
  end

  def save_listing
    File.open(home+'listing',  'w') { |yf| YAML.dump(@listing,  yf) }
    @listing
  end

  def sanitize_listing
    tmp = []
    @listing.each { |item|
      entry = load_entry(item)
      add = false
      attrs = File.open( home+'attributes' ) { |yf| @attrs = YAML::load( yf )[name] }
      entry.each { |key, value|
        if attrs.include? key
          add = true if value and not attrs[key]
        end
      }
      item[:publish] = false unless add or item[:publish] 
      tmp << item 
    }
    @listing = tmp
    save_listing
  end

  def write_attribute_file
    write_template base+'.templates/disco/attributes', home+'attributes'
  end
  def write_display_file
    write_template base+'.templates/disco/display', home+'display'
  end
  def write_feed_file
    write_template base+'.templates/disco/feed', home+'feed'
  end
  def write_paginate_file
    write_template base+'.templates/disco/paginate', home+'paginate'
  end
  def write_link_list_file
    write_template base+'.templates/disco/link_list', home+'link_list'
  end
  def load_attributes
    File.open( home+'attributes' ) { |yf| @attrs = YAML::load( yf )[name] }
  end
  def load_listing
    File.open( home+'listing' ) { |yf| @listing = YAML::load( yf ) }
    @listing ||= []
    @listing = @listing.sort{|x, y| x[:id] <=> y[:id]}.reverse
  end
  def save_entry(id)
    File.open( home+'entries/'+id, 'w' ) {|yf|
      tmp={}
      tmp[name] = find_entry id
      tmp[name] = tmp[name].reject{|key, value| key.kind_of? Symbol }
      YAML::dump( tmp, yf)
    } 
    find_entry id
  end
  def load_entries
    @entries = []
    @unpublished = []
    listing.each {|entry|
      if entry[:publish]
        @entries <<  load_entry(entry) 
      else
        @unpublished << load_entry(entry)
      end
      }
    entries
  end
  def delete entry
    listing.delete_if{|e| e[:id] == entry }
    save_listing
  end
  def load_entry(file)
    tmp = nil
    File.open( home+'entries/'+file[:id].to_s ) {|yf| tmp = YAML::load( yf )[name].merge(file)} rescue puts "loading entry -- #{$!}"
    tmp
  end
  def add_entry title=nil
    timestamp = Time.now.to_i.to_s 
    title ||=  timestamp
    listing.unshift({:id => timestamp})
    save_listing
    write_template home+'attributes', home+'entries/'+timestamp
    load_entries
    return {:id => timestamp, :file => home+'entries/'+timestamp}
  end
  def publish
    tmp = {}
    listing.each {|e|
      if e[:publish] and not e[:publish].kind_of? String
        e[:publish] = Time.now.to_s
      end
    }
    save_listing
  end

  def set_to_publish entry
    listing.find{|e| e[:id] == entry}[:publish] = true
    save_listing
  end

  def find_entry entry
    tmp = entries.find{|e| e[:id] == entry}
    tmp ||= unpublished.find{|e| e[:id] == entry}
    tmp
  end

  
end


