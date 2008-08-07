class ListFiles

	def initialize path
		@dirs = []
		@files = []
		@platform = "/"
		@platform = "\\" if PLATFORM =~ /win/
		@root_path = os_path path		
		
		root = Dir.open(@root_path)
		scan root
	end

	def list_files
		recurse
		@files
	end

	def recurse
		while @dirs != []
			path = @dirs.pop
			dir = Dir.open(path)
			scan dir
		end
	end

	def scan dir 
		local_path = dir.path
		dir.each  do |item|
			path = os_join local_path, item
			(File.directory?(path) ? @dirs.push(path) :	@files.push(path)) unless item.find {|r| r=~/^\./ }
		end	
	end

	def os_join *args
		args.join(@platform)
	end

	def os_path path
		if path.include?("\\")
			p = path.split("\\")
		elsif path.include?("/")
			p = path.split("/")
		end
		path = os_join p
		path
	end
end
