H_SPACING_OK = {}
H_SPACING_1 = {}
H_SPACING_2 = {}

H_SPACING_OK[:short_line_no_newline] =
  %Q{'#{'#' * 78}'}

H_SPACING_OK[:short_line_newline_at_81] =
  %Q{'#{'#' * 78}'
}

#-------------------------------------------------------------------------------
H_SPACING_1[:hard_tab] =
  %Q{def something
\tputs "something"
end}

H_SPACING_1[:hard_tab_with_spaces] =
  %Q{class Thing
  def something
\t  puts "something"
  end
end}

# This only reports the hard tab problem (and not the indentation problem)
# because a hard tab is counted as 1 space; here, this is 4 spaces, so it
# looks correct to the parser.  I'm leaving this behavior, as detecting the
# hard tab should signal the problem.  If you fix the hard tab and don't
# fix indentation, tailor will flag you on the indentation on the next run.
H_SPACING_1[:hard_tab_with_1_indented_space] =
  %Q{class Thing
  def something
\t   puts "something"
  end
end}

H_SPACING_2[:hard_tab_with_2_indented_spaces] =
  %Q{class Thing
  def something
\t    puts "something"
  end
end}

#-------------------------------------------------------------------------------
H_SPACING_1[:long_line_no_newline] =
  %Q{'#{'#' * 79}'}

H_SPACING_1[:long_line_newline_at_82] =
  %Q{'#{'#' * 79}'
}

#-------------------------------------------------------------------------------
H_SPACING_1[:empty_line_with_spaces] =
  %Q{  }

H_SPACING_1[:empty_line_with_spaces_in_method] =
  %Q{def thing
  
  puts 'something'
end}

H_SPACING_1[:trailing_spaces_on_def] =
  %Q{def thing 
  puts 'something'
end}

#-------------------------------------------------------------------------------
H_SPACING_1[:no_space_after_comma] =
  %Q{[1,2]}

H_SPACING_1[:two_spaces_after_comma] =
  %Q{[1,  2]}

H_SPACING_2[:two_spaces_after_comma_twice] =
  %Q{[1,  2,  3]}

H_SPACING_2[:spaces_before_with_trailing_comments] =
  %Q{[
  1 ,   # Comment!
  2 ,   # Another comment.
}

H_SPACING_OK[:space_after_comma_in_array] =
  %Q{[1, 2]}

H_SPACING_OK[:trailing_comma] =
  %Q{def thing(one, two,
  three)
end}

H_SPACING_OK[:trailing_comma_with_trailing_comment] =
  %Q{def thing(one, two,  # Comment!
  three)
end}

#-------------------------------------------------------------------------------
H_SPACING_1[:one_space_before_comma] =
  %Q{[1 ,2]}

H_SPACING_1[:two_spaces_before_comma] =
  %Q{[1  , 2]}

H_SPACING_2[:two_spaces_before_comma_twice] =
  %Q{[1  , 2  , 3]}

H_SPACING_OK[:no_before_comma_in_array] =
  %Q{[1, 2]}

#-------------------------------------------------------------------------------
H_SPACING_OK[:single_line_hash] =
  %Q{{ :one => 'one' }}

H_SPACING_OK[:single_line_hash_lonely_braces] =
  %Q{{
  :one => 'one'
}}

H_SPACING_OK[:two_line_hash] =
  %Q{{ :one =>
'one' }}

H_SPACING_OK[:three_line_hash] =
  %Q{{ :one =>
'one', :two =>
'two' }}

H_SPACING_OK[:single_line_block] =
  %Q{1..10.times { |n| puts number }}

H_SPACING_OK[:multi_line_braces_block] =
  %Q{1..10.times { |n|
puts number }}

H_SPACING_1[:single_line_hash_2_spaces_before_lbrace] =
  %Q{thing =  { :one => 'one' }}

H_SPACING_1[:single_line_hash_2_spaces_after_lbrace] =
  %Q{thing = {  :one => 'one' }}

H_SPACING_1[:single_line_hash_0_spaces_before_lbrace] =
  %Q{thing ={ :one => 'one' }}

H_SPACING_1[:two_line_hash_2_spaces_before_lbrace] =
  %Q{thing1 =
  thing2 =  { :one => 'one' }}

H_SPACING_1[:two_line_hash_2_spaces_before_lbrace_lonely_braces] =
  %Q{thing1 =
  thing2 =  {
  :one => 'one'
}}

H_SPACING_1[:single_line_block_2_spaces_before_lbrace] =
  %Q{1..10.times  { |n| puts number }}

H_SPACING_1[:single_line_block_0_spaces_before_lbrace] =
  %Q{1..10.times{ |n| puts number }}

H_SPACING_1[:two_line_braces_block_2_spaces_before_lbrace] =
%Q{1..10.times  { |n|
puts number }}
