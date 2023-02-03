#!/usr/bin/env ruby

require 'optparse'
require 'set'

@options = {
    filepath: "puzzles/sudoku-com-easy-20230126T132000.txt"
}

@board = Array.new(9){Array.new(9, 0)}


OptionParser.new do |opts|
  opts.on("-f", "--file", String, "Puzzle file") do |v|
    @options[:file] = v.nil? ? @options[:file] : v
  end
end.parse!


class Cell
  @row
  @col
  @sol  
  def initialize(row, col, sol)
    @row = row
    @col = col
    @sol = sol
  end
  def to_str
    "Cell(%d, %d)%s" % [@row, @col, @sol.to_a.sort]
  end
  def to_s
    to_str
  end
  attr_reader :row
  attr_reader :col
  attr_reader :sol
end


def print
  @board.each do |row|
    puts row.join(" ")
  end
end


def iter08
  ix = (0..8)
  ix.each do |i|
    yield(i)
  end
end


def done
  d = true
  iter_rc do |r,c|
    if @board[r][c] == 0
      d = false
      break
    end
  end
  d
end


def is_valid(a)
  iv = true
  n = Array.new(9, 0)
  a.each do |v|
    if v > 0
      i = v-1
      n[i] += 1
      if n[i] > 1
        iv = false
        break
      end
    end
  end
  iv
end


def valid
  v = true
  # check that each row, col is valid
  iter08 do |i|
    if !is_valid(get_row(i)) || !is_valid(get_col(i))
      v = false
      break
    end
  end
  if v
    # check that each box is valid
    (0..2).each do |r|
      (0..2).each do |c|
        if !is_valid(get_box(r, c))
          v = false
          break
      end
    end
  end
  v
end


def get_row(r)
  row = []
  iter08 do |c|
    v = @board[r][c]
    row.append(v)
  end
  row
end


def get_col(c)
  col = []
  iter08 do |r|
    v = @board[r][c]
    col.append(v)
  end
  col
end


def get_box(rb, cb)
  box = []
  row = (rb*3..rb*3 + 2)
  col = (cb*3..cb*3 + 2)
  row.each do |r|
    col.each do |c|
      box.append(@board[r][c])
    end
  end
  box
end


def iter_rc
  rows = (0..8)
  rows.each do |r|
    cols = (0..8)
    cols.each do |c|
      yield(r, c)
    end
  end
end


def solutions(r, c)
  row = get_row(r)
  col = get_col(c)
  box = get_box(r/3, c/3)
  taken = Set.new(row) | Set.new(col) | Set.new(box)
  Set.new((1..9)) - taken
end


def solve1
  solved1 = false
  iter_rc do |r,c|
    if @board[r][c] != 0
      next
    end
    s = solutions(r, c)
    l = s.length
    if l == 0
      break
    elsif l == 1
      v = s.first
      @board[r][c] = v
      solved1 = true
      break
    end
  end
  solved1
end


def parse_vals(r, vals)
  c = 0
  vals.each do |v|
    if v.to_i.to_s != v 
      raise "Invalid value '%s' in row %d, col %d" % [r, c, v]
    end
    i = v.to_i
    if i < 0
      i = 0
    end
    @board[r][c] = i
    c += 1
  end
end


def parse_line(r, line)
  pl = false
  l = line.strip.delete(" ")
  if l.length > 0 && l[0] != "#"
    vals = l.split(",")
    if vals.length != 9
      throw "Invalid row %d: %s" % [r, l]
    end
    parse_vals(r, vals)
    pl = true
  end
  pl
end


def parse_file
  filepath = @options[:filepath]
  r = 0
  File.readlines(filepath).each do |line|
    if parse_line(r, line)
      r += 1
    end
  end
end


def read
  filepath = @options[:filepath]
  puts "starting %s" % [filepath]
  if filepath.nil?
    raise "Puzzle filepath is nil."
  elsif !File.exists?(filepath)
    raise "Puzzle file %s not found." % [filepath]
  else
    parse_file
  end
  if !valid
    raise "Board is not valid."
  end
  print
end


def unsolved1
  us = []
  backup = Array.new(9){Array.new(9, 0)}
  iter_rc do |r,c|
    backup[r][c] = @board[r][c].to_s.to_i
    if @board[r][c] == 0
      sol = solutions(r, c)
      us.append(Cell.new(r, c, sol))
    end
  end
  if us.length == 0
    raise "unsolved.length == 0"
  end
  u = us.sort_by { |u|
    u.sol.length
  }.first
  [u, backup]
end


def backtrack
  b = false
  us1 = unsolved1
  u, backup = us1[0], us1[1]
  u.sol.each do |v|
    @board[u.row][u.col] = v
    b = solve
    if b
      break
    else
      iter_rc do |r,c|
        @board[r][c] = backup[r][c]
      end
    end
  end
  b
end


def solve
  while !done && valid do
    if solve1
      next
    else
      if !backtrack
        break
      end
    end
  end
  done && valid
end


def main
  read
  puts solve ? "solved board" : "unable to solve board"
  print
end


main
