class VariableChanger

	def initialize path
		require '/home/katateochi/mantissa/tool_development/file_tools/list_files.rb'
#		"X:\\Documents\\Katateochi\\Main Documents\\Programming\\Ruby\\Tools\\list_files.rb"
		@path = path
		f = ListFiles.new(@path)
		@paths = f.list_files
		@transform ={:from => "@prescription_collection_request", :to => "@pcr"}
#		@transform ={:from => "<%= link_to 'Back', :controller => '/employees/admins' %>", :to => "<%=link_to 'Back', :controller => '/employees' %>"}
		@line_padding = 5
		scan_files
		review_work_list
		write_files
	end

	def write_files
		for job in @work_list
			if job.has_key?(:confirmed_update)
				result = "skipped"	
				print "Writing file: #{job[:file].path}....."
				puts write_file(with_verification(job))
			end
		end
	end

	def with_verification job
		valid = false
		File.open(job[:file].path,'r') do |f|
			 if f.mtime == job[:mtime]
				 valid = true
			 end
		end
		valid ? job : false
	end

	def write_file job
		if job
			File.open(job[:file].path,'w') do |file|
				file.write job[:confirmed_update]
			end
			result = "Done"
		else
			result = "Skipped\n\tThis file has been modified since the beginging of this ludicrously long process, it was skipped so you can run me again!!"
		end
		return result
	end

	def scan_files
		@work_list = []
		for path in @paths
			File.open(path, 'r') do |file|
				@mtime  = file.mtime
				output = analyse file
				unless output[:index] == []
					@work_list.push output
				end
			end
		end
	end

	def review_work_list
		for job in @work_list
			puts "\n\n#{job[:index].size} Alterations Needed in: #{job[:file].path.sub(@path,"")}\n"
			raise "Warning line numbers dont match for #{job[:file].path}" if job[:original].size != job[:changed].size
			updated = []
			@file_changed = false
			r1 = "each"
			if job[:index].size >= 2
				puts "There is more than one change to make in this file, would you like to view each change in turn or view entire file? \n[all/a || each/e || Return to skip this file]"
				r1 = gets.chomp
			end

			if ["all", "a"].include? r1
				updated = review_by_file job
			elsif ["each", "e"].include? r1
				updated = review_by_line job
			end
			updated = job[:original] if updated == []
			if @file_changed
				raise "updated file has different line count to original" if updated.size != job[:original].size
				job.merge!({:confirmed_update => updated})
			end
		end
	end

	def review_by_line job
		count = 0
		out = job[:original]
		for i in job[:index]
			puts "Alteration #{count +=1}"
			block_print job, i
			puts "Accept change? [y/n]"
			r3 = gets.chomp
			if ["y", "Y"].include? r3
				out[i] = job[:changed][i]
				@file_changed = true
			end
			puts "\n\n"
		end
		return out
	end

	def review_by_file job
		file_print job
		print "\nPlease enter the (comma separated) line numbers you want to accept, or type \"all\" or \"none\"\nchanged line numbers: "
		job[:index].each { |i| print "#{i+1}, "}
		puts "\n"
		task = mind_taker #takes insturctions from user, intended for future drop and replace with telepathic software
		out = []
		if task == "all"
			out = job[:changed]
			@file_changed = true
		elsif task == "none"
			out = job[:original]
		else
			job[:original].size.times do |index|
				out[index] = job[:original][index]
				if job[:index].include? index
					if task.include? index
						out[index] = job[:changed][index]
						@file_changed = true
					end
				end
			end
		end
		return out
	end

	def mind_taker
		valid = false
		pass = 0
		while valid == false
			pass += 1
			puts "please just do what i ask" if pass > 1
			r2 = gets.chomp
			task = []
			if ["all", "a"].include? r2
				task = "all" 
				valid = true
			elsif ["none", "n"].include? r2
				task = "none"
				valid = true
			elsif (r2 =~/\d,/) != nil || (r2 =~ /\d/) != nil
				confirmed_lines = []
				lines = r2.split(",")
				check = 0
				for line in lines
					if line.to_i.class == Fixnum
						confirmed_lines.push line.to_i
						check += 1
					end
				end
				valid = true if check == lines.size
				valid = false if (r2 =~ /[A-Za-z]/)
				confirmed_lines.each{ |c| task.push(c -= 1) } if valid == true
			end
		end
		return task
	end

	def analyse file
		original, changed, index = [], [], []
		count = 0
		file.each do |line|
			original.push line
			changed.push line
			if needs_change? line
				changed.pop
				changed.push change(line)
				index.push count
			end
			count += 1
		end
		return {:file => file, :index => index, :original => original, :changed => changed, :mtime => @mtime}
	end

	def change line
		line.gsub(/#{Regexp.escape @transform[:from]}/,"#{@transform[:to]}") 
	end

	def needs_change? line
		true  if line =~ /#{Regexp.escape @transform[:from]}/
	end

	def block_print job, index
		min = index - @line_padding
		min = 0 if min < 0
		max =  index + @line_padding
		max = job[:original].size if max > job[:original].size

		before = job[:original][min..(index - 1)]
		after = job[:original][(index + 1)..max]
		old_line = job[:original][index]
		new_line = job[:changed][index]
		
		#DONT MESS with the adjustments, they have been mathed out, tested and they work!
		puts_block(before, min+1)
		puts_line(job[:original][index], index+1, ">>\n   OlD>")
		puts_line(job[:changed][index], "", "   NEW>")
		puts "\n"
		puts_block(after, (index + 2))
	end

	def file_print job
		job[:original].size.times do |i|
			if job[:index].include? i
				puts_line(job[:original][i], i+1, ">>\n   OlD>")
				puts_line(job[:changed][i], "", "   NEW>")
				puts "\n"
			else
				puts_line(job[:original][i], i+1)
			end
		end
	end

	def puts_block block, line_number
		for line in block
		puts_line(line, line_number)
			line_number += 1
		end
	end

	def puts_line line, number, flag = nil
		p = "#{number}>>\t#{line}"
		p.sub!(">>",flag) if flag
		puts p
	end
end

#v = VariableChanger.new("X:\\Documents\\Katateochi\\Main Documents\\Programming\\Ruby\\testing_zone")
#v = VariableChanger.new("X:\\Documents\\Katateochi\\Main Documents\\Programming\\mantissa\\nootts\\virtual-pharmacy\\website\\app")
v = VariableChanger.new('/home/katateochi/mantissa/projects/nootts/virtual-pharmacy/website/app/')




