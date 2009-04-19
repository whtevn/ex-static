
require 'camping'
require 'static'

include Static
Camping.goes :Content

@home = File.dirname(__FILE__)+'/..' 
File.open("#{@home}/project_info/site.info") { |yf| $info  = YAML::load( yf ) }
Static::setup_home

$active_site = load_site $info['working_name']

module Content::Controllers
  class Static < R '/resource_bank/(.+)'
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', '.jpg' => 'image/jpeg'}
    PATH = File.expand_path(File.dirname(__FILE__))

    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include?("..") 
        @headers['X-Sendfile'] = "#{PATH}/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end

  class GenerateSite < R '/site/generate'
    def get
      $active_site.destroy $active_site.site_loc
      $active_site.info['paginate'].each { |page, collection| paginate page } if $active_site.info['paginate']
      $active_site.generate
      publish_feeds :local
    end
  end

  class PublishSite < R '/site/publish'
    def get
      $active_site.destroy $active_site.site_loc
      $active_site.info['paginate'].each { |page, collection| paginate page } if $active_site.info['paginate']
      $active_site.generate
      publish_feeds 
    end
 
  end
  
  class HideCollection < R '/collection/hide/(.+)'
    def get name
      @headers['Content-Type'] = 'text/javascript'
      @name = name
      render :_hide_collection
    end
  end

  class ListCollection < R '/collection/list/(.+)'
    def get name
      @headers['Content-Type'] = 'text/javascript'
      @name = name
      @collection = load_collection name
      render :_list_collection
    end
  end

  class ViewEntry < R '/collection/(.+)/entry/(.+)'
    def get collection, entry
      @headers['Content-Type'] = 'text/javascript'
      @name = collection
      @collection = load_collection collection
      @collection.load_entries
      @entry = @collection.find_entry entry 
      render :_view_entry
    end
  end
  
  class ReloadEntrySection < R '/reload/collection/(.+)/entry/(.+)/section/(.+)'
    def get collection, entry, key
      @headers['Content-Type'] = 'text/javascript'
      @name = collection
      @collection = load_collection collection
      @collection.load_entries
      @entry = @collection.find_entry entry 
      @section = key
      render :_reload_entry_section
    end
  end

  class PublishEntry < R '/publish/collection/(\w+)/entry/(\w+)'
    def get collection, entry
      @headers['Content-Type'] = 'text/javascript'
      @name = collection
      @collection = load_collection collection
      @collection.set_to_publish entry
      @collection.load_entries
      render :_list_collection
    end
  end

  class DeleteEntry < R '/delete/collection/(.+)/entry/(.+)'
    def get collection, entry
      @headers['Content-Type'] = 'text/javascript'
      @name = collection
      @collection = load_collection collection
      @collection.delete entry
      @collection.load_entries
      render :_list_collection
    end
  end

  class EditEntry < R '/edit/collection/(.+)/entry/(.+)/section/(.+)'
    def get collection, entry, key
      @headers['Content-Type'] = 'text/javascript'
      @name = collection
      @collection = load_collection collection
      @collection.load_entries
      @entry = @collection.find_entry entry 
      @section = key
      render :_edit_entry_section
    end

    def post collection, entry, key
      @headers['Content-Type'] = 'text/javascript'
      
      @name = collection
      @collection = load_collection collection
      @collection.load_entries
      @collection.find_entry(entry)[key] = input["#{key}_value"]
      @entry = @collection.save_entry entry
      @section = key
      render :_reload_entry_section
    end
  end
  class Index < R '/'
    def get
      render :index 
    end
  end

  class Content < R '/(\w+)'
    def get page_name
      @page = Page.find page_name.as_file
      @page.load_contents
      render :_content
    end
  end

  class Reload < R '/reload/(\w+)/(\w+)'
    def get page_name, section
      @page = Page.find page_name.as_file
      @page.load_contents
      @key = section
      @value = @page.contents[section]
      render :_section
    end
  end

  class AddEntry < R '/add_entry/collection/(\w+)'
    def get collection
      @name = collection
      @collection = load_collection collection
      @collection.load_entries
      @entry = @collection.add_entry
      @entry = @collection.load_entry @entry
      @collection.load_entries
      render :_view_entry
    end
  end

  class Edit < R '/edit/(\w+)/(\w+)'
    def get page_name, section
      page = Page.find page_name.as_file
      page.load_contents
      @page_name = page_name.as_file
      @text = page.contents[section]
      @title = section
      render :_edit_section
    end

    def post page_name, section
      @headers['Content-Type'] = 'text/javascript'
      @page = Page.find page_name.as_file
      @page.load_contents
      @old_key = section
      @key = input["#{section}_key"]
      @value = input["#{section}_value"]
      if @key == section
        @page.contents[section] = @value
      else 
      @page.contents[section] = nil
      @page.contents[@key] = @value
      end
      @page.save_contents
      @page.load_contents

      render :_reload_section
    end
  end
end

module Content::Views
  def site_map(options={}, item=nil, first_time=true)
    pages = first_time ? "<ul>" : ''
    item ||= $active_site.map['site_map']
    case item
    when String
      pages << "<li>#{link_to(item)}</li>"
    when Array : item.each {|i| pages << site_map(options, i, false)}
    when Hash
      item.each do |key, value|
        pages << site_map(options, key, false)
        pages << "<ul>#{site_map(options, value, false)}</ul>"
      end
    end
    pages << "</ul>" if first_time
    pages
  end

  def link_to page, name=nil; name||=page; a name, :href=>'#', :onclick => "new Ajax.Updater('main', '/#{page.as_file}',{asynchronous:true, evalScripts:true, method:'get'}); return false;" end

  def layout
    html do
      head{
        title { 'Content Editing For Static' }
        script :src => "resource_bank/prototype.js", :type => "text/javascript"
      }
      body {
        table {
          ul{
            li{
           self << a('generate site locally', :href => '#', :onclick => "new Ajax.Request('site/generate', {asynchronous:true, evalScripts:true, method:'get'}); return false;")
            }
            li{
           self << a('local preview', :href => $active_site.info['local']['link'], :target => 'blank')
            } if $active_site.info['local'] and $active_site.info['local']['link']
            li{
           self << a('publish site', :href => '#', :onclick => "new Ajax.Request('site/publish', {asynchronous:true, evalScripts:true, method:'get'}); return false;")
            } if $active_site.info['server'] and $active_site.info['server']['link'] and $active_site.info['server']['address'] and $active_site.info['server']['directory'] and $active_site.info['user_name']
            li{
           self << a('go to live site', :href => $active_site.info['server']['link'], :target => 'blank' )
            } if $active_site.info['server'] and $active_site.info['server']['link']
          }
          tr{
            td(:id => 'page_select', :valign=>'top', :width=> '250px'){
              self<< site_map({}, $active_site.map['site_map'])
                $active_site.info['feeds'].each do |f|
                  div(:id=>"#{f}_collection"){self << a(f, :href=>'#', :onclick => "new Ajax.Request('collection/list/#{f}', {asynchronous:true, evalScripts:true, method:'get'}); return false;")}
                end if $active_site.info['feeds']
            }
            td(:id=>'main', :valign =>'top'){ self << yield }
          }
        }
      }
    end
  end

  def index
    p 'there are no instructions. do what feels right.'
  end

  def _content
    h4 "copy for #{@page.name}"
    if @page.contents['title']
      span(:id => 'title'){
      h4 {
        self << a('title', :href=>"#", :onclick => "new Ajax.Updater('title', 'edit/#{@page.file_name}/title', { asynchronous:true, method:'get' });")
      }
      pre @page.contents['title']
      }
    end
    @page.contents.each do |key, value|
      unless key == 'title' or key == 'stylesheets'
        span(:id => key){
        h4 {
          self << a(key, :href=>"#", :onclick => "new Ajax.Updater('#{key}', 'edit/#{@page.file_name}/#{key}', { asynchronous:true, method:'get' });")
        }
          pre value
        }
      end
    end
  end

  def _edit_section
    form(:onsubmit => "new Ajax.Request('/edit/#{@page_name}/#{@title}', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;"){
    
    if @title == 'title'
      h4 'title'
      input :type => 'hidden', :value => @title, :name =>"#{@title}_key"
      input :type => 'text', :name =>"#{@title}_value", :value => @text
    else
      input :type => 'text', :value => @title, :name =>"#{@title}_key"
      textarea(:cols => '90', :rows => '30', :name => "#{@title}_value"){
        self << @text 
      }
    end
    input :type => 'submit', :value => 'submit', :name => 'submit'
    a 'cancel', :href=> "#", :onclick => "new Ajax.Updater('#{@title}', '/reload/#{@page_name}/#{@title}', {asynchronous:true, method:'get'}); return false;"
    }
  end

  def _edit_entry_section
    form(:onsubmit => "new Ajax.Request('/edit/collection/#{@name}/entry/#{@entry[:id]}/section/#{@section}', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;"){
      if @section == "title"
        input :type => 'text', :name =>"title_value", :value => @entry[@section]
      else
        textarea(:cols => '90', :rows => '30', :name => "#{@section}_value"){
          self << @entry[@section]
        }
      end
      input :type => 'submit', :value => 'submit', :name => 'submit'
      a 'cancel', :href=> "#", :onclick => "new Ajax.Updater('#{@section}_attribute', '/reload/collection/#{@name}/entry/#{@entry[:id]}/section/#{@section}', {asynchronous:true, method:'get'}); return false;"
    }
  end

  def _reload_entry_section
    self << _list_collection if @section == 'title'
    self << "$('attribute_#{@section}').replace("
    if @section =="title"
      h4(:id => "attribute_title"){self<< a(@entry["title"]||@entry[:id], :href=>'#', :onclick => "new Ajax.Updater('attribute_title', 'edit/collection/#{@name}/entry/#{@entry[:id]}/section/title', { asynchronous:true, method:'get' });")}
    else
    span(:id => "attribute_#{@section}"){
      self << a(@section, :href=>"#", :onclick => "new Ajax.Updater('attribute_#{@section}', 'edit/collection/#{@name}/entry/#{@entry[:id]}/section/#{@section}', { asynchronous:true, method:'get' });")
      pre(@entry[@section])
    }
    end
    self << ")"
  end

  def _section
    span(:id => @key){
        h4 {
          self << a(@key, :href=>"#", :onclick => "new Ajax.Updater('#{@key}', 'edit/#{@page.file_name}/#{@key}', { asynchronous:true, method:'get' });")
        }
        pre @value
    }
  end

  def _reload_section
    self << "$('#{@old_key}').replace("
      _section
    self << ")"
  end

  def _hide_collection
    self << "$('#{@name}_collection').replace("
      div(:id=>"#{@name}_collection"){self << a(@name, :href=>'#', :onclick => "new Ajax.Request('collection/list/#{@name}', {asynchronous:true, evalScripts:true, method:'get'}); return false;")}
    self << ")"
  end

  def _list_collection
    self << "$('#{@name}_collection').replace("
    div(:id => "#{@name}_collection"){
     a(@name, :href=>'#', :onclick => "new Ajax.Request('collection/hide/#{@name}', {asynchronous:true, evalScripts:true, method:'get'}); return false;")
     a("+add+", :href=>'#', :onclick => "new Ajax.Updater('main', 'add_entry/collection/#{@name}', {asynchronous:true, evalScripts:true, method:'get'}); return false;")
     ul{
     li "unpublished"
        @collection.unpublished.each do |e|
          li{
            self << a(e['title']||e[:id], :href=>'#', :onclick=>"new Ajax.Updater('main', 'collection/#{@name}/entry/#{e[:id]}',{asynchronous:true, evalScripts:true, method:'get'}); return false; ")
            self << a('publish', :href => '#', :onclick=>"new Ajax.Request('publish/collection/#{@name}/entry/#{e[:id]}',{asynchronous:true, evalScripts:true, method:'get'}); return false; ")
            self << a('delete', :href => '#', :onclick=>"new Ajax.Request('delete/collection/#{@name}/entry/#{e[:id]}',{asynchronous:true, evalScripts:true, method:'get'}); return false; ")
          }
        end
      }
     ul{
     li "published"
        @collection.entries.each do |e|
          li{
            self << a(e['title']||e[:id], :href=>'#', :onclick=>"new Ajax.Updater('main', 'collection/#{@name}/entry/#{e[:id]}',{asynchronous:true, evalScripts:true, method:'get'}); return false; ")
            unless e[:publish]
              self << a('publish', :href => '#', :onclick=>"new Ajax.Request('publish/collection/#{@name}/entry/#{e[:id]}', {asynchronous:true, evalScripts:true, method:'get'}); return false; ")
              self << a('delete', :href => '#', :onclick=>"new Ajax.Request('delete/collection/#{@name}/entry/#{e[:id]}',{asynchronous:true, evalScripts:true, method:'get'}); return false; ")
            end
          }
        end
      }
    }
    self << ");"
  end

  def _view_entry
      h4(:id => "attribute_title"){self<< a(@entry["title"]||@entry[:id], :href=>'#', :onclick => "new Ajax.Updater('attribute_title', 'edit/collection/#{@name}/entry/#{@entry[:id]}/section/title', { asynchronous:true, method:'get' });")}
      @entry.each {|key, value|
         unless key=='title' or key.kind_of? Symbol
           span(:id => "attribute_#{key}"){
              self << a(key, :href=>"#", :onclick => "new Ajax.Updater('attribute_#{key}', 'edit/collection/#{@name}/entry/#{@entry[:id]}/section/#{key}', { asynchronous:true, method:'get' });")
              pre(@entry[key])
            }
        end
      }
  end
end

