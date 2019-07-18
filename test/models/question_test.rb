require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  
  
  def setup
    @question = Question.new(prompt: "How many how manys?", extent: "private",
          choices: ["Beef", "Stroganoff"])
    
  end
  
  test "should be valid" do
    assert @question.valid?
  end
  
  
end
