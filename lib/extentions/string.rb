

class String
  def as_file; self.gsub(/([!?,]|[^a-zA-Z0-9\.]$)/, '').gsub(/[^a-zA-Z0-9\.\/~]/, '_').downcase end
  def as_folder; self.as_file+((self.as_file=~/\/$/||self=='') ? '' : '/') end
  def as_ext; self[0,0]='.' unless self[0,1]=='.'|| self==''; self end
  def as_file_title; self.as_file.gsub /_/, ' ' end
  def filename_as_symbol; self.as_file.to_sym end
  def as_http; self =~ /^http\:\/\// ? "http://#{self.gsub(/^http\:\/\//, '').as_folder}" : "http://#{self.as_folder}" end
end

