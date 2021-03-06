require 'fileutils'
require 'trollop'
require File.dirname(__FILE__) + '/../core/detail_parser'


OPTS = Trollop::options do 
    opt :source_dir, "Source Dir", :type => :string
    opt :dest_dir, "Dest Dir (Optional)", :type => :string
    opt :template_dir, "Template Directory (Optional)", :type => :string
    version "summarize_results.rb 0.4 (c) Ben Nagy, 2010"
    banner <<-EOS

Usage:
Summarizes the results for a directory full of crashes, where each crash file is
accompanied by a .txt file - outputs data for the first file it
finds from each !exploitable bucket. Optionally, copies one file from each bucket
to dest-dir. Optionally, if given a template directory, adds the output from ole2diff 
(stream by stream diff for OLE2 files) into the summary. It will match templates to
crashes by comparing the MD5 hash in the filename with the available templates.

    ruby summarize_results.rb --source-dir /foo --dest-dir /bar --template_dir
EOS
end

SOURCE_PATH=OPTS[:source_dir]
DEST_PATH=OPTS[:dest_dir]

def dump(results, summary)
    hack=Hash.new {|h,k| h[k]=0}
    puts "=========SUMMARY==============="
    summary.each {|k,v| puts "#{k}: #{v}"}
    puts "#{results.keys.size} Buckets."
    results.sort.each {|k,v|
        hack[v[2]]+=1
    }
    hack.each {|k,v| puts "#{k}: #{v}"}
    puts "==============================="
    results.sort.each {|k,v|
        puts "--- #{k} (count: #{v[0]}) ---"
        puts v[1].join("\n")
        if OPTS[:template_given]
            next unless v[1][3]
            puts `ruby ole2diff.rb -o #{OPTS[:template]} #{v[1][3]}`
        end
    }
end

def sample(results)
    FileUtils.mkdir(DEST_PATH) unless File.directory? DEST_PATH
    puts "Copying to : #{DEST_PATH}"
    results.each {|k,v|
        next unless v[1][3]
        puts "File: #{v[1][3]}"
        FileUtils.cp(v[1][3],DEST_PATH)
    }
end

# get all detail files in the SOURCE_PATH
pattern=File.join(SOURCE_PATH, "*.txt")
results=Hash.new {|hsh, k| hsh[k]=[0,"", ""]}
summary=Hash.new {|hsh, k| hsh[k]=0}

Dir.glob(pattern, File::FNM_DOTMATCH).each {|fn|
    contents=File.open(fn, "rb") {|ios| ios.read}
    if hsh=DetailParser.hash( contents )
        results[hsh][0]+=1
        crashfile1=fn.sub('.txt','.raw')
        if File.exists? crashfile1
            file=crashfile1
        else
            file="<missing?>"
        end
        fault=DetailParser.faulting_instruction(contents)
        classification=DetailParser.classification(contents)
        summary[classification]+=1
        summary["total"]+=1
        instructions=DetailParser.disassembly(contents).map {|a| a[1]}.join("\n")
        title=DetailParser.long_desc(contents)
        registers=DetailParser.registers(contents).map {|a| a.join('=')}.join(' ')
        stack=DetailParser.stack_trace(contents)[0..3].map {|a| a[1]}.join("\n")
        stack="-----STACK-------\n" << stack << "\n--------------------"
        results[hsh][1]=["#{classification}: #{title}", fault, registers, instructions, stack, file]
        results[hsh][2]=classification
    end
}
dump results, summary
sample results if OPTS[:dest_dir_given]
