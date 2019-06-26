require 'test_helper'

class SchoolsTermTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
    end 

end