class VacationMailer < ActionMailer::Base

  # Used to create the message template
  def message(user, message, subject = "Out of office")
    subject    subject
    from       user.epost
    
    body       message
  end

  # Used to parse message template read in from server
  def receive(mail)
    mail
  end

end
