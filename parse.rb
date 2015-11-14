def parse_name(line)
  parts = line.split
  parts.size == 6 ? parts.last : ""
end

def parse_mem(line)
  parts = line.split
  parts.size > 2 ? parts[1].to_i : 0
end

procs = [{}]
i = 0
new_line = true

File.readlines(ARGV[0]).each do |line|
  if line.start_with?("VmFlags")
    i += 1
    new_line = true
    procs << {}
  else
    if new_line
      procs[i][:name] = parse_name(line)
    elsif line.start_with?("Size:")
      procs[i][:size] = parse_mem(line)
    elsif line.start_with?("Rss:")
      procs[i][:rss] = parse_mem(line)
    end
    new_line = false
  end
end

procs.pop

jvm_heap_alloc_index = 0
procs.each_index do |x|
  proc = procs[x]
  if proc[:name].start_with?("[heap")
    jvm_heap_alloc_index = x + 1
    break
  end
end

#jvm_heap_allocs = [42496,393216]
jvm_heap_allocs = [procs[jvm_heap_alloc_index][:size]]
#puts "Assuming Heap is #{jvm_heap_allocs}"

jvm_heap = procs.select{|proc| jvm_heap_allocs.include?(proc[:size]) and proc[:name].empty? }

tot_kb = procs.inject(0) do |sum, proc|
  sum + proc[:rss]
end

tot_kb_lib = procs.inject(0) do |sum, proc|
  sum + ((proc[:name].start_with?("/lib") or proc[:name].include?(".jdk")) ? proc[:rss] : 0)
end

tot_kb_heap = procs.inject(0) do |sum, proc|
  sum + (proc[:name].start_with?("[heap") ? proc[:rss] : 0)
end

buffers = procs.select {|proc| proc[:name].empty? and proc[:rss] > 500 }

stacks = procs.select{|proc| proc[:name].start_with?("[stack") }

threads = procs.select{|proc| proc[:size] == 504 and proc[:name].empty? }

jvm_heap_kb = jvm_heap.inject(0){|sum, p| sum + p[:rss]}
stack_kb = stacks.inject(0){|sum, p| sum + p[:rss]}
thread_kb = threads.inject(0){|sum, p| sum + p[:rss]}
buffer_kb = buffers.inject(0){|sum, p| sum + p[:rss]} - jvm_heap_kb

def format_kb(num)
  if num < 10
    "      #{num}"
  elsif num < 100
    "     #{num}"
  elsif num < 1000
    "    #{num}"
  elsif num < 10000
    "   #{num}"
  elsif num < 100000
    "  #{num}"
  elsif num < 1000000
    " #{num}"
  else
    "#{num}"
  end
end

puts "#{format_kb tot_kb_heap} kB: OS Heap (not JVM heap)"
puts "#{format_kb stack_kb} kB: Thread stacks (over #{stacks.size} threads)"
puts "#{format_kb tot_kb_lib} kB: Native libs (like libgcc, libnio, etc)"
puts "#{format_kb buffer_kb} kB: Anonymous maps (over #{buffers.size} maps)"
puts "#{format_kb jvm_heap_kb} kB: JVM Heap"
puts "#{format_kb tot_kb} kB: Total RSS"
