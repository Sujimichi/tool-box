files = []
d = Dir.open("./").each {|item| files << item unless item =~/^\./ }
d.close
files.each do |file|
	puts file
	system "gvim #{file}"
end
