require 'digest'
require 'colorize'

def get_hashes(path)
	hashes = Hash.new

	if !File.exists?(path) 
		File.new(path, "w")
	else 
		File.readlines(path).each do |entry|
			line = entry.strip
			next if(line.length == 0)

			hash = line.split('=')
			hashes[hash[0]] = hash[1]
		end
	end
	return hashes
end


def get_paths(path)
	dirs = [path]
	dirs_temp = [path]

	while (dirs_temp.size > 0) do

		target = dirs_temp[0]
			dirs_temp.delete_at(0)

		Dir.glob("#{target}/*") { |entry|

			if(File.directory?(entry))

				dirs_temp.push(entry)
				dirs.push(entry)
			end
		}
	end
	return dirs
end

source_path = ARGV[0].to_s
source_basename = File.basename(source_path)

hashes_path = "#{source_basename}.txt"
changes_path = "#{source_basename}_changes.txt"

puts "Grabbing hashes..."
hashes = get_hashes(hashes_path)

# Get all root subdirectories
puts "Scanning directory..."
directories = get_paths(source_path)

# Generates files from paths
file_paths = []
file_paths_size = 0
puts "Generating file tree..."
directories.each do |dir|
	Dir.glob("#{dir}/*").each do |entry|
		next if !File.file?(entry)
		file_paths_size += 1
		file_paths.push(entry)
	end
end

# Generates hashes and populates snapshot # name => md5
snapshot = Hash.new
file_paths_enum = 0
puts "Generating snapshot..."
file_paths.each do |path|
	md5 = Digest::MD5.new
	begin
		md5.update File.read(path)
	rescue Exception => e
		puts "Exception: #{e}"
	end

	name = File.basename(path)
	snapshot[name] = md5.hexdigest;

	file_paths_enum += 1
	puts "#{file_paths_size}/#{file_paths_enum}".green
end


added = 0;
added_list = []
changed = 0
changed_list = []
removed = 0
removed_list = []

#Validate hashed files
puts "Validating hashes..."
hashes.each do |name,hash|
	if(!snapshot.key?(name))
		removed += 1
		removed_list.push("#{name}=#{hash}")

		File.open(changes_path, "a+") do |io|
			io.puts "Removed: #{name}=#{hash}"
		end
	end
end

snapshot.each do |name, hash|
	
	if(!hashes.key?(name))
		added += 1
		added_list.push("#{name}=#{hash}")

		File.open(hashes_path, "a+") do |io|
			io.puts "#{name}=#{hash}"
		end
	else
		if(!hash.eql? hashes[name])
			changed += 1
			changed_list.push("#{name}=#{hash}")

			File.open(changes_path, "a+") do |io|
				io.puts "Changed: #{name}=#{hash}"
			end
		end
	end
end

if(added_list.size == 0 && changed_list.size == 0 && removed_list.size == 0) 
	puts "Nothing to do."
else
	if(added_list.size > 0) 
		puts "Added: "
		added_list.each do |entry| 
			puts "#{entry}".green
		end
	end

	if(changed_list.size > 0) 
		puts "Changed: "
		changed_list.each do |entry| 
			puts "#{entry}".yellow
		end
	end

	if(removed_list.size > 0) 
		puts "Removed: "
		removed_list.each do |entry| 
			puts "#{entry}".red
		end
	end
end
puts "Added: #{added} Changed: #{changed} Removed: #{removed}"
puts "------------------------"
puts "Complete"