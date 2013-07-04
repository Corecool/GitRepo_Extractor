#!/usr/bin/env ruby

require 'csv'
# require 'pry'

if ARGV.size != 2
	puts 'usage: convert.rb input output'
	exit
end

if File.exist?(ARGF.filename)
	$input = IO.read(ARGF.filename)
else
	puts "Input File is not exist."
	exit
end
$input.gsub!("\t", "    ")
ARGF.skip

system("touch #{ARGV[0]}") unless File.exist?(ARGV[0])
$file = CSV.open(ARGF.filename, "wb")
$file << ['CommitID', 'MergeIDs', 'Author', 'Email', 'CommitDate', 'Content']

$row = []

def handle_head(data)
	$row += [data[:Commit], data[:Merge], data[:Author], data[:Email], data[:Date]]
end

def handle_content(ppos, pos)
	$row << $input[ppos...pos]
end

$ppos, $pos = 0, 0
$pattern = /commit\s*(?<Commit>.*)\n(Merge:\s(?<Merge>.{7}\s.{7})\n)?Author:\s*(?<Author>[^<]*)<(?<Email>.*)>\nDate:\s*(?<Date>.*)\n/
while data = $pattern.match($input, $pos)
	# binding.pry
	handle_head(data)
	$ppos = $pos = data.end(0)
	if matchData = $pattern.match($input, $pos)
		$pos = matchData.begin(0)
		handle_content($ppos, $pos)
	else
		handle_content($ppos, $input.size)
	end
	$file << $row
	$row.clear
end

$file.close