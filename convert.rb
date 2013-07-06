#!/usr/bin/env ruby

require 'csv'
require 'pry'

if ARGV.size != 2
	puts 'usage: convert.rb projectRoot outputFile.csv'
	exit
end

$projectRoot = ARGF.filename
ARGF.skip

Dir.chdir(File.expand_path($projectRoot)) {|path|
	$input = `git log`
}
$input.gsub!("\t", "    ")

system("touch #{ARGV[0]}") unless File.exist?(ARGV[0])
$file = CSV.open(ARGF.filename, "wb")
$file << ['CommitID', 'MergeIDs', 'Author', 'Email', 'CommitDate', 'ChangeModules', 'Content']

$row = []

def handle_head(data)
	$row += [data[:Commit], data[:Merge], data[:Author], data[:Email], data[:Date]]
end

def handle_content(ppos, pos)
	$row << $input[ppos...pos]
end

def handle_influenceModules(curCommit, lastCommit)
	mods, data = "", ""
	Dir.chdir(File.expand_path($projectRoot)) {|path|
		data = `git diff #{curCommit[:Commit]} #{lastCommit[:Commit]} --stat`
	}
	data.each_line{|line|
		mods << line.sub(/([^|]*)\|.*/, '\1') 
	}	
	$row << mods
end

$ppos, $pos = 0, 0
$pattern = /commit\s*(?<Commit>.*)\n(Merge:\s(?<Merge>.{7}\s.{7})\n)?Author:\s*(?<Author>[^<]*)<(?<Email>.*)>\nDate:\s*(?<Date>.*)\n/
while data = $pattern.match($input, $pos)
	# binding.pry
	handle_head(data)
	$ppos = $pos = data.end(0)
	if matchData = $pattern.match($input, $pos)
		$pos = matchData.begin(0)
		handle_influenceModules(data, matchData)
		handle_content($ppos, $pos)
	else
		$row << ""
		handle_content($ppos, $input.size)
	end
	$file << $row
	$row.clear
end

$file.close