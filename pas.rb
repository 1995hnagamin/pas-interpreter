# encoding: utf-8
require 'pp'
require 'optparse'
require 'io/console'

@stack = []

def print_stack
  STDERR.print "[", @stack.join(","), "]\n"
end

def stack_state(stack)
  stack.map do |s|
    [s,s.chr("UTF-8")]
  end
end

def spush(n)
  @stack.push n
end

def spop
  @stack.pop
end
  
def sadd
  a = @stack.pop
  b = @stack.pop
  @stack.push b + a
end

def ssub
  a = @stack.pop
  b = @stack.pop
  @stack.push b - a
end

def smul
  a = @stack.pop
  b = @stack.pop
  @stack.push b * a
end

def sdiv
  a = @stack.pop
  b = @stack.pop
  @stack.push b / a
end

def smod
  a = @stack.pop
  b = @stack.pop
  @stack.push b % a
end

def snot
  a = @stack.pop
  @stack.push (a == 0 ? 1 : 0)
end

def sgreater
  a = @stack.pop
  b = @stack.pop
  @stack.push (b > a ? 1 : 0)
end

def sdup
  a = @stack[-1]
  @stack.push a
end

def split_array(arr, size)
  if size == 0
    [arr, []]
  else
    [arr[0,arr.length - size], arr[-size..-1]]
  end
end

def sroll1(depth)
  return if depth == 0
  head, tail = split_array(@stack, depth)
  top = tail.pop
  @stack = head + [top] + tail
end

def sroll
  roll = @stack.pop
  depth = @stack.pop
  roll.times do
    sroll1 depth
  end
end

def sinn
  str = ""
  begin
    c = STDIN.getc
    str << c
  end while not " \t\n".include? c
  n = str.to_i
  @stack.push n
end

def sinc
  n = STDIN.getc.ord
  @stack.push n
end

def soutn
  n = @stack.pop
  print n
end

def soutc
  n = @stack.pop
  print n.chr("UTF-8")
end

OptionParser.new do |o|
  o.on('-v', '--verbose', 'verbose option')  { |b| @print_stack = b }
  o.on('-s', '--step', 'stepwise execution') { |b| @stepwise = b }
  o.on('-f FILENAME') { |name| @filename = name }
  begin
    o.parse!
  rescue
    puts "#{o}"
    exit
  end
end

@lines = []

def label_lineno(word)
  stmt = "LABEL #{word}"
  @lines.index stmt
end

def comment_line?(line)
  line =~ /[ \t]+#.*/
end

open @filename do |file|
  while line = file.gets
    @lines << line.chomp if not comment_line? line
  end
end

i = -1
while true
  i += 1
  cmd = @lines[i]
  STDERR.print "#{sprintf "%03d", i + 1} #{cmd}:\t" if @print_stack

  case cmd
  when /PUSH ([0-9]+)/ then spush $1.to_i
  when /POP/  then spop
  when /ADD/  then sadd
  when /SUB/  then ssub
  when /MUL/  then smul
  when /DIV/  then sdiv
  when /MOD/  then smod
  when /NOT/  then snot
  when /GREATER/  then sgreater
  when /DUP/  then sdup
  when /ROLL/ then sroll
  when /INN/  then sinn
  when /INC/  then sinc
  when /OUTN/ then soutn
  when /OUTC/ then soutc
  when /HALT/ then break
  when /LABEL (.+)/ then ;
  when /JEZ (.+)/
    word = $1
    n = @stack.pop
    i = label_lineno(word) if n == 0
  when /JMP (.+)/
    word = $1
    i = label_lineno(word)
  when nil then break
  end
  print_stack if @print_stack
  stepping_input = STDIN.getch if @stepwise
  exit if stepping_input == ?\C-c
end

