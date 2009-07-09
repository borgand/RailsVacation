require 'test_helper'

class VacationMailerTest < ActionMailer::TestCase
  test "message" do
    @expected.subject = 'VacationMailer#message'
    @expected.body    = read_fixture('message')
    @expected.date    = Time.now

    assert_equal @expected.encoded, VacationMailer.create_message(@expected.date).encoded
  end

end
