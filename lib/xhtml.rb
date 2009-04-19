
module Inclusion
  def find_file_name page, what
    tmp = nil
    case what
    when Hash
      what.each { |desc, item| tmp = "#{page.file_name}_#{desc}_#{item}" }
    else
      tmp = what==:contents ? page.file_name : what.to_s
    end
    tmp+'.rbml'
  end
  def partial from, what
    get from, "_#{what}"
  end
  def get from, what
    case from
    when :base
      run_file  Generator.act_on.home+"base/#{what}.rbml"
    when :page
      run_file Generator.act_on.home+"blueprint/#{Generator.page_location}#{find_file_name(Generator.act_on, what)}"
    else
      $active_site.pages.each { |page| run_file page.home+'blueprint/'+page.page_location+find_file_name(page, what) if page.name.as_file == from.to_s }
    end
  end

  def display how_many, collection, entry_bank=nil, &blk
    col = load_collection(collection.to_s)
    level = Generator.level
    how_many = col.entries.size if how_many == :all
    entry_bank ||= col.entries.dup
    Generator.load col
    Generator.act_on.instance_eval { def level; @level end; def level=(what); @level=what end }
    Generator.act_on.level = level
    how_many.times { 
      break if entry_bank.empty?
      Generator.act_on.contents = entry_bank.shift
      block_given? ? run_block(&blk) : run_file(Generator.act_on.display_file) rescue puts $!
    }
    Generator.act_on.instance_eval { @level = nil; undef :level; undef :level=}
    Generator.unload
  end

  def include_partial
    i Generator.include_text 
    Generator.include_text 
  end
end

module Rbml
  module Language
    module Doc
      module Rss
        def address_for what, options={}
          where = options[:page] ? options[:page]+'.html' : ''
          say = $active_site.info['server']['link']
          $active_site.pages.each { |page|
            if page.name.as_file == what.to_s 
              text ||= page.name
              say += "#{page.in_site_link}#{where}"
            end
          }
          say
        end

        def process_cdata what
          what = what.to_s
          exp = /\<\[.+?\]\>/
          while(what =~ exp) do
            what.sub!(exp) { |match|
               eval(match.sub(/^\<\[/,'').sub(/\]\>$/, ''))
            }
          end
          "<![CDATA[#{what}]]>"
        end
        def link_to where, text='', options={}
          say=''
          $active_site.pages.each { |page|
            if page.name.as_file == where.to_s 
              text ||= page.name
              say = "\"#{text}\":#{$active_site.info['server']['link']}#{page.in_site_link}"
            end
          }
          say
        end
      end
    end
  end
end

module Rbml
  module Language
    module Doc
      module Xhtml
        def put_title
          title(Generator.contents['title'])
        end
        def use_stylesheets *sheets
          tmp = []
          sheets.each { |s| tmp << s.to_s }
          stylesheets Generator.level+'stylesheets/', tmp
        end
        alias :use_stylesheet :use_stylesheets

        def image which, alt=nil
          i "< image src='#{place}/#{which.to_s}' alt='#{alt||which.to_s}' />"
          "<image src='#{Generator.level}resources/#{which.to_s}' alt='#{alt||which.to_s}' />"
        end
        def resource_address which
          i "#{Generator.level}resources/#{which.to_s}"
          "#{Generator.level}resources/#{which.to_s}"
        end
        def script_address which
          i "#{Generator.level}scripts/#{which.to_s}"
          "#{Generator.level}scripts/#{which.to_s}"
        end

        def put_stylesheets
          styles = []
          Generator.stylesheets.each{|style| styles << style if style}
         styles.empty? ? '' : stylesheets(Generator.level+'stylesheets/', styles)
        end
        def breadcrumbs(join_by=nil)
          join_by ||= " >> "
          links = []
          Generator.breadcrumbs.each {|b| links << (Generator.act_on.name.as_file==b.to_s ? Generator.act_on.name : link_to(b)) }
          links.join(join_by)
        end
        def main_link_for what
          link_to what
        end
        def feed name, title=nil
          "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"#{title||name.to_s}\" href=\"#{Generator.act_on.level}#{name.to_s}.rss\" />"
        end
        def link_to what, text=nil, options={}
          where = options[:page] ? options[:page]+'.html' : ''
          say=''
          $active_site.pages.each { |page|
            if page.name.as_file == what.to_s 
              text ||= page.name
              say << "<a href='#{Generator.level}#{page.in_site_link}#{where}'>#{text}</a>"
            end
          }
          say
        end
        def put what, options={}
          t find_contents(what, options)
        end
        def plain_put what, options={}
           find_contents(what, options)
        end
        def truncate what, how_many, options={}
          options[:trail] ||= '...'
          contents = find_contents(what)
          contents = contents.size > how_many ? contents[0, how_many] + options[:trail] : contents
          options[:textile] ? t(contents) : i(contents)
        end
        def find_contents what, options={}
           parse_context(Generator.contents[what.to_s] || '')
        end

        def parse_context(what)
          what = what.to_s
          exp = /\<\[.+?\]\>/
          while(what =~ exp) do
            what.sub!(exp) { |match|
               eval(match.sub(/^\<\[/,'').sub(/\]\>$/, ''))
            }
          end
          exp = /\<!\[.+?\]\>/
          while(what =~ exp) do
            what.sub!(exp) { |match|
               match.sub!(/^\<!\[/,'<[')
            }
          end
          what
        end

        def site_map(options={}, item=nil, first_time=true)
          pages = first_time ? "<ul>" : ''
          item ||= $active_site.map['site_map']
          case item
          when String
            pages << "<li>#{link_to(item.as_file)}</li>"
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
      end
    end
  end
end
