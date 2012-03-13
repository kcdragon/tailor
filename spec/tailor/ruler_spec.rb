require 'fakefs/spec_helpers'
require_relative '../spec_helper'
require 'tailor/ruler'

describe Tailor::Ruler do
  let!(:file_text) { "" }
  let(:style) { {} }
  subject { Tailor::Ruler.new(file_text, style) }

  before do
    Tailor::Ruler.any_instance.stub(:ensure_trailing_newline).and_return(file_text)
  end

  describe "#initialize" do
    it "sets @proper_indentation to an Hash with :this_line and :next_line keys = 0" do
      proper_indentation = subject.instance_variable_get(:@proper_indentation)
      proper_indentation.should be_a Hash
      proper_indentation[:this_line].should be_zero
      proper_indentation[:next_line].should be_zero
    end

    context "name of file is passed in" do
      let(:file_name) { "test" }

      before do
        File.open(file_name, 'w') { |f| f.write "some text" }
      end

      it "opens and reads the file by the name passed in" do
        file = double "File"
        file.should_receive(:read).and_return file_text
        File.should_receive(:open).with("test", 'r').and_return file
        Tailor::Ruler.new(file_name, style)
      end
    end

    context "text to lex is passed in" do
      let(:text) { "some text" }

      it "doesn't try to open a file" do
        File.should_not_receive(:open)
        Tailor::Ruler.new(text, style)
      end
    end
  end

  describe "#current_lex" do
    let(:lexed_output) do
      [
        [[1, 0], :on_ident, "require"],
          [[1, 7], :on_sp, " "],
          [[1, 8], :on_tstring_beg, "'"],
          [[1, 9], :on_tstring_content, "log_switch"],
          [[1, 19], :on_tstring_end, "'"],
          [[1, 20], :on_nl, "\n"],
          [[2, 0], :on_ident, "require_relative"],
          [[2, 16], :on_sp, " "],
          [[2, 17], :on_tstring_beg, "'"],
          [[2, 18], :on_tstring_content, "tailor/runtime_error"],
          [[2, 38], :on_tstring_end, "'"],
          [[2, 39], :on_nl, "\n"]
      ]
    end

    it "returns all lexed output from line 1 when self.lineno is 1" do
      subject.stub(:lineno).and_return(1)
      subject.current_lex(lexed_output).should == [[[1, 0], :on_ident, "require"],
        [[1, 7], :on_sp, " "],
        [[1, 8], :on_tstring_beg, "'"],
        [[1, 9], :on_tstring_content, "log_switch"],
        [[1, 19], :on_tstring_end, "'"],
        [[1, 20], :on_nl, "\n"]
      ]
    end
  end

  describe "#current_line_indent" do
    subject { Tailor::Ruler.new(file_text, style) }

    context "when indented 0" do
      let(:file_text) { "puts 'something'" }

      it "returns 0" do
        subject.current_line_indent(Ripper.lex(file_text)).should == 0
      end
    end

    context "when indented 1" do
      let(:file_text) { " puts 'something'" }

      it "returns 1" do
        subject.current_line_indent(Ripper.lex(file_text)).should == 1
      end
    end
  end

  describe "#line_of_only_spaces?" do
    context '0 length line, no \n ending' do
      let(:file_text) { "" }

      it "should return true" do
        subject.line_of_only_spaces?(Ripper.lex(file_text)).should be_true
      end
    end

    context '0 length line, with \n ending' do
      let(:file_text) { "\n" }

      it "should return true" do
        subject.line_of_only_spaces?(Ripper.lex(file_text)).should be_true
      end
    end

    context 'comment line, starting at column 0' do
      let(:file_text) { "# this is a comment" }

      it "should return false" do
        subject.line_of_only_spaces?(Ripper.lex(file_text)).should be_false
      end
    end

    context 'comment line, starting at column 2' do
      let(:file_text) { "  # this is a comment" }

      it "should return false" do
        subject.line_of_only_spaces?(Ripper.lex(file_text)).should be_false
      end
    end

    context 'code line, starting at column 2' do
      let(:file_text) { "  class << self" }

      it "should return false" do
        subject.line_of_only_spaces?(Ripper.lex(file_text)).should be_false
      end
    end
  end

  describe "#modifier_keyword?" do
    context "the current line has a keyword that is also a modifier" do
      context "the keyword is acting as a modifier" do
        let!(:file_text) { %q{puts "hi" if true == true} }

        it "returns true" do
          subject.stub(:lineno).and_return 1
          subject.instance_variable_set(:@file_text, file_text)
          subject.modifier_keyword?("if").should be_true
        end
      end

      context "they keyword is NOT acting as a modifier" do
        let!(:file_text) { %q{if true == true; puts "hi"; end} }

        it "returns false" do
          subject.stub(:lineno).and_return 1
          subject.instance_variable_set(:@file_text, file_text)
          subject.modifier_keyword?("if").should be_false
        end
      end
    end

    context "the current line doesn't have a keyword" do
      let!(:file_text) { %q{puts true} }

      it "returns false" do
        subject.stub(:lineno).and_return 1
        subject.instance_variable_set(:@file_text, file_text)
        subject.modifier_keyword?("puts").should be_false
      end
    end
  end

  describe "#update_outdentation_expectations" do
    context "#single_line_indent_statement? returns false" do
      before do
        subject.stub(:single_line_indent_statement?).and_return false
        subject.instance_variable_set(:@config, { indentation: { spaces: 27 } })
      end

      it "decrements @proper_indentation[:this_line] by @config[:spaces]" do
        subject.instance_variable_set(:@proper_indentation, {
          this_line: 28, next_line: 28
        })
        subject.update_outdentation_expectations

        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:this_line].should == 1
      end

      it "decrements @proper_indentation[:next_line] by @config[:spaces]" do
        subject.update_outdentation_expectations

        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:next_line].should == -27
      end

      context "@proper_indentation[:this_line] gets decremented < 0" do
        it "sets @proper_indentation[:this_line] to 0" do
          subject.instance_variable_set(:@proper_indentation, {
            this_line: 0, next_line: 0
          })

          subject.update_outdentation_expectations
          proper_indentation = subject.instance_variable_get(:@proper_indentation)
          proper_indentation[:this_line].should == 0
        end
      end
    end

    context "#single_line_indent_statement? returns true" do
      before do
        subject.stub(:single_line_indent_statement?).and_return true
        subject.instance_variable_set(:@config, { indentation: { spaces: 13 } })
      end

      it "does not decrement @proper_indentation[:this_line]" do
        subject.update_outdentation_expectations

        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:this_line].should == 0
      end

      it "decrements @proper_indentation[:next_line] by @config[:spaces]" do
        subject.update_outdentation_expectations

        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:next_line].should == -13
      end
    end
  end

  describe "#update_indentation_expectations" do
    before do
      subject.instance_variable_set(:@config, { indentation: { spaces: 7 } })
    end

    it "sets @indent_keyword_line to lineno" do
      subject.stub(:lineno).and_return 10
      subject.update_indentation_expectations "def"

      subject.instance_variable_get(:@indent_keyword_line).should == 10
    end

    context "token is a CONTINUATION_KEYWORDS" do
      it "decrements @proper_indentation[:this_line] by @config[:spaces]" do
        subject.instance_variable_set(:@proper_indentation, {
          this_line: 8, next_line: 8
        })

        subject.update_indentation_expectations("elsif")
        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:this_line].should == 1
      end

      it "does not increment @proper_indentation[:next_line]" do
        subject.update_indentation_expectations("elsif")
        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:next_line].should == 0
      end

      context "@proper_indentation[:this_line] gets decremented < 0" do
        it "sets @proper_indentation[:this_line] to 0" do
          subject.instance_variable_set(:@proper_indentation, {
            this_line: 0, next_line: 0
          })

          subject.update_indentation_expectations("elsif")
          proper_indentation = subject.instance_variable_get(:@proper_indentation)
          proper_indentation[:this_line].should == 0
        end
      end
    end

    context "token is not a CONTINUATION_KEYWORDS" do
      it "does not decrement @proper_indentation[:this_line]" do
        subject.update_indentation_expectations("pants")
        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:this_line].should == 0
      end

      it "does not increment @proper_indentation[:next_line]" do
        subject.update_indentation_expectations("pants")
        proper_indentation = subject.instance_variable_get(:@proper_indentation)
        proper_indentation[:next_line].should == 7
      end
    end
  end

  describe "#single_line_indent_statement?" do
    context "@indent_keyword_line is nil and lineno is 1" do
      before do
        subject.instance_variable_set(:@indent_keyword_line, nil)
        subject.stub(:lineno).and_return 1
      end

      specify { subject.single_line_indent_statement?.should be_false }
    end

    context "@indent_keyword_line is 1 and lineno is 1" do
      before do
        subject.instance_variable_set(:@indent_keyword_line, 1)
        subject.stub(:lineno).and_return 1
      end

      specify { subject.single_line_indent_statement?.should be_true }
    end

    context "@indent_keyword_line is 2 and lineno is 1" do
      before do
        subject.instance_variable_set(:@indent_keyword_line, 2)
        subject.stub(:lineno).and_return 1
      end

      specify { subject.single_line_indent_statement?.should be_false }
    end

    context "@indent_keyword_line is 1 and lineno is 2" do
      before do
        subject.instance_variable_set(:@indent_keyword_line, 1)
        subject.stub(:lineno).and_return 2
      end

      specify { subject.single_line_indent_statement?.should be_false }
    end
  end

  describe "#multiline_braces?" do
    context "@brace_start_line is nil" do
      before { subject.instance_variable_set(:@brace_nesting, []) }
      specify { subject.multiline_braces?.should be_false }
    end

    context "@brace_start_line is 0 and lineno is 0" do
      before do
        subject.instance_variable_set(:@brace_nesting, [0])
        subject.stub(:lineno).and_return 0
      end

      specify { subject.multiline_braces?.should be_false }
    end

    context "@brace_start_line is 0 and lineno is 1" do
      before do
        subject.instance_variable_set(:@brace_nesting, [0])
        subject.stub(:lineno).and_return 1
      end

      specify { subject.multiline_braces?.should be_true }
    end

    context "@brace_nesting.first is 1 and lineno is 0" do
      before do
        subject.instance_variable_set(:@brace_nesting, [1])
        subject.stub(:lineno).and_return 0
      end

      specify { subject.multiline_braces?.should be_false }
    end
  end

  describe "#multiline_brackets?" do
    context "@bracket_start_line is nil" do
      before { subject.instance_variable_set(:@bracket_nesting, []) }
      specify { subject.multiline_brackets?.should be_false }
    end

    context "@bracket_nesting.first is 0 and lineno is 0" do
      before do
        subject.instance_variable_set(:@bracket_nesting, [0])
        subject.stub(:lineno).and_return 0
      end

      specify { subject.multiline_brackets?.should be_false }
    end

    context "@bracket_nesting.first is 0 and lineno is 1" do
      before do
        subject.instance_variable_set(:@bracket_nesting, [0])
        subject.stub(:lineno).and_return 1
      end

      specify { subject.multiline_brackets?.should be_true }
    end

    context "@bracket_nesting.first is 1 and lineno is 0" do
      before do
        subject.instance_variable_set(:@bracket_nesting, [1])
        subject.stub(:lineno).and_return 0
      end

      specify { subject.multiline_brackets?.should be_false }
    end
  end

  describe "#line_ends_with_op?" do
    context "line ends with a +, then \\n" do
      let(:lexed_output) do
        [
          [[1, 0], :on_ident, "thing"],
          [[1, 5], :on_sp, " "],
          [[1, 6], :on_op, "="],
          [[1, 7], :on_sp, " "],
          [[1, 8], :on_int, "1"],
          [[1, 9], :on_sp, " "],
          [[1, 10], :on_op, "+"],
          [[1, 11], :on_ignored_nl, "\n"],
          [[1, 11], :on_ignored_nl, "\n"]
        ]
      end

      it "returns true" do
        subject.line_ends_with_op?(lexed_output).should be_true
      end
    end

    context "line ends with not an operator, then \\n" do
      let(:lexed_output) do
        [
          [[1, 0], :on_ident, "thing"],
          [[1, 5], :on_sp, " "],
          [[1, 6], :on_op, "="],
          [[1, 7], :on_sp, " "],
          [[1, 8], :on_int, "1"],
          [[1, 11], :on_nl, "\n"]
        ]
      end

      it "returns false" do
        subject.line_ends_with_op?(lexed_output).should be_false
      end
    end
  end

  describe "#loop_with_do?" do
    context "line is 'while true do\\n'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "while"], [[1, 5], :on_sp, " "], [[1, 6], :on_kw, "true"], [[1, 10], :on_sp, " "], [[1, 11], :on_kw, "do"], [[1, 13], :on_ignored_nl, "\n"]]
      end

      it "returns true" do
        subject.loop_with_do?(lexed_output).should be_true
      end
    end

    context "line is 'while true\\n'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "while"], [[1, 5], :on_sp, " "], [[1, 6], :on_kw, "true"], [[1, 10], :on_sp, " "], [[1, 11], :on_ignored_nl, "\n"]]
      end

      it "returns false" do
        subject.loop_with_do?(lexed_output).should be_false
      end
    end

    context "line is 'until true do\\n'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "until"], [[1, 5], :on_sp, " "], [[1, 6], :on_kw, "true"], [[1, 10], :on_sp, " "], [[1, 11], :on_kw, "do"], [[1, 13], :on_ignored_nl, "\n"]]
      end

      it "returns true" do
        subject.loop_with_do?(lexed_output).should be_true
      end
    end

    context "line is 'until true\\n'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "until"], [[1, 5], :on_sp, " "], [[1, 6], :on_kw, "true"], [[1, 10], :on_sp, " "], [[1, 11], :on_ignored_nl, "\n"]]
      end

      it "returns false" do
        subject.loop_with_do?(lexed_output).should be_false
      end
    end

    context "line is 'for i in 1..5 do\\n'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "for"], [[1, 3], :on_sp, " "], [[1, 4], :on_ident, "i"], [[1, 5], :on_sp, " "], [[1, 6], :on_kw, "in"], [[1, 8], :on_sp, " "], [[1, 9], :on_int, "1"], [[1, 10], :on_op, ".."], [[1, 12], :on_int, "5"], [[1, 13], :on_sp, " "], [[1, 14], :on_kw, "do"], [[1, 16], :on_ignored_nl, "\n"]]
      end

      it "returns true" do
        subject.loop_with_do?(lexed_output).should be_true
      end
    end

    context "line is 'for i in 1..5\\n'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "for"], [[1, 3], :on_sp, " "], [[1, 4], :on_ident, "i"], [[1, 5], :on_sp, " "], [[1, 6], :on_kw, "in"], [[1, 8], :on_sp, " "], [[1, 9], :on_int, "1"], [[1, 10], :on_op, ".."], [[1, 12], :on_int, "5"], [[1, 13], :on_sp, " "], [[1, 14], :on_ignored_nl, "\n"]]
      end

      it "returns false" do
        subject.loop_with_do?(lexed_output).should be_false
      end
    end
  end

  describe "#line_of_only_rparen?" do
    context "line is '  )'" do
      let(:lexed_output) do
        [[[1, 0], :on_sp, "  "], [[1, 2], :on_rparen, ")"]]
      end

      it "returns true" do
        subject.line_of_only_rparen?(lexed_output).should be_true
      end
    end

    context "line is '  })'" do
      let(:lexed_output) do
        [[[1, 0], :on_sp, "  "], [[1, 2], :on_rbrace, "}"], [[1, 2], :on_rparen, ")"]]
      end

      it "returns false" do
        subject.line_of_only_rparen?(lexed_output).should be_false
      end
    end

    context "line is '  def some_method'" do
      let(:lexed_output) do
        [[[1, 0], :on_kw, "def"], [[1, 3], :on_sp, " "], [[1, 4], :on_ident, "some_method"], [[1, 15], :on_nl, "\n"]]
      end

      it "returns false" do
        subject.line_of_only_rparen?(lexed_output).should be_false
      end
    end
  end

  describe "#first_non_space_element" do
    context "lexed line contains only spaces" do
      let(:lexed_output) { [[[1, 0], :on_sp, "     "]] }

      it "returns nil" do
        subject.first_non_space_element(lexed_output).should be_nil
      end
    end

    context "lexed line contains only \\n" do
      let(:lexed_output) { [[[1, 0], :on_ignored_nl, "\n"]] }

      it "returns nil" do
        subject.first_non_space_element(lexed_output).should be_nil
      end
    end

    context "lexed line contains '  }\\n'" do
      let(:lexed_output) { [[[1, 0], :on_sp, "  "], [[1, 2], :on_rbrace, "}"], [[1, 3], :on_nl, "\n"]] }

      it "returns nil" do
        subject.first_non_space_element(lexed_output).should ==
          [[1,2], :on_rbrace, "}"]
      end
    end
  end
end
