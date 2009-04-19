
require 'erb'
require 'fileutils'

module FileBase
  include FileUtils

  Home = ''
  def home; (@home||Home).as_folder end
  def set_home(here)
    mkdir here unless exists? :folder, here
    @home=here
  end
  
  def location; (@location||'').as_folder end
  def set_location where; @location=where end
  def setup_location where; @location=where; mkdir path unless exists? :folder, path end
  def reset_location; @location='' end
  def has_location?; location!='' end

  def path; home+location end
  def file_path; home+location+filename end
  
  def exists? type, item
    return false unless File.exist? item
    truth = case type
    when :folder
       return(File.directory?(item))
    when :file
       return(!File.directory?(item))
    else
       return(true)
    end
  end

  def items_under(pth, match=nil)
    match||=''
    folders = []
    files = []
    Dir.entries(pth).each { |item| (exists?(:folder, pth.as_folder+item) ? folders << item : files << item) unless item[0,1]=='.' or not item=~/#{match}/}
    {:folders => folders, :files => files}
  end

  
  def move(from, to=home)
    FileUtils.mv from, to
  end

  def copy(from, to=home)
    FileUtils.cp_r from, to
  end

  def mkdir where, force=false
    begin 
      Dir.mkdir where
    rescue
      raise $! unless force
      destroy where
      mkdir where
    end
    where
  end
 
  def make_dir path, force=false
    mkdir path, force
    puts 'creating '+path
  end

  def destroy what
    FileUtils.rm_rf what
    puts 'destroying '+what
  end
  
  def write(contents, where)
    File.open(where, 'w'){ |f| f << contents }
  end
  def write_template what, where
    write ERB.new(File.read(what)).result(binding), where
  end

  alias loc location
  alias loc= set_location
end

