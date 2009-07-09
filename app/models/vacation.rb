class Vacation < Tableless

  attr_accessor :enabled, :subject, :message, :rc_file, :msg_file

  RC_FILE = "vacation.rc"
  MSG_FILE = "vacation.msg"
  DB_FILE = "vacation.db"

  def self.userdir_exists?(username)
    connect!
    begin
      if @@sftp.stat!(File.join(Conf.datadir, username))
        return true
      end
    rescue
      return false
    end
  end

  def self.find_by_username(username)
    connect!
    if userdir_exists?(username)
      return new(username)
    else
      return nil
    end
  end

  def self.find_or_create_by_user(user)
    return new(user)
  end

  # The initializer
  # Tries to find rc-file and message file and defaults to empty values
  def initialize(user)
    connect!
    @user = user.is_a?(User) ? user : User.find_by_login(user)
    @username = @user.login
    @rc_file = ""
    @msg_file = ""
    @subject = "Out of Office"
    @message = ""
    begin
      @rc_file = @@sftp.file.open(File.join(Conf.datadir,@username,RC_FILE)).read
    rescue
    end
    begin
      @msg_file = @@sftp.file.open(File.join(Conf.datadir,@username,MSG_FILE)).read
    rescue
    end
    @enabled = !@rc_file.blank?
    parse_message
  end

  # returns true, if the vacation msg directory is created
  # intented as an indicator that User has to set up procmail beforehand
  def set_up?
    return self.class.userdir_exists?(@username)
  end
  

  # save method with rescue
  def save
    return save!
  rescue => e
    logger.error(e)
    logger.error(e.backtrace.join("\n"))
    return false
  end

  # Write out the files
  def save!
    generate_files
    # Create the directory, unless it exists
    @@sftp.mkdir!(File.join(Conf.datadir,@username), :permissions => 0777) unless self.class.userdir_exists?(@username)
    # We need the dir be writable to User's procmail, but mkdir does not set the perms correctly
    @@sftp.setstat!(File.join(Conf.datadir,@username), :permissions => 0777)
    # Write out RC_FILE
    @@sftp.file.open(File.join(Conf.datadir,@username,RC_FILE),"w") { |file|
      file.puts @rc_file
    }
    # As save is supposed to change text or enabled-state, we should purge db
    db_file = File.join(Conf.datadir,@username,DB_FILE)
    begin
      @@sftp.remove!(db_file)
    rescue
      logger.debug("Database file not found, ignoring (#{db_file})")
    end

    # Write out message file
    @@sftp.file.open(File.join(Conf.datadir,@username,MSG_FILE),"w") { |file|
      file.puts @msg_file
    }
    return true
  end

  private

  def generate_files
    # If disabled, the RC_FILE will be empty
    if @enabled
      @rc_file = 
":0 c
| #{Conf.vacation_bin} -a #{@user.login}@#{Conf.domain} -a #{@user.dotted_name}@#{Conf.domain} -f #{File.join(Conf.datadir,@username,DB_FILE)} -m #{File.join(Conf.datadir,@username,MSG_FILE)} #{@user.login}
"
    else
      @rc_file = ""
    end
    @msg_file = VacationMailer.create_message(@user, @message, @subject).to_s
  end


  # Parse msg_file and extract subject and message
  def parse_message
    msg = VacationMailer.receive(@msg_file)
    @subject = msg.subject
    @message = msg.body
  end

  # Class-level connect
  def self.real_connect
    sftp = nil
    if Conf.remote_host
      sftp = Net::SFTP.start(Conf.remote_host, Conf.remote_user, Conf.ssh_opts)
    end
    # TODO: write non-ssh version

    return sftp
  end

  # connects if necessary
  def self.connect
    @@sftp ||= real_connect
  end

  # always reconnects
  def self.connect!
    @@sftp = real_connect
  end


  # instance-level connect (reuses class-level)
  def connect
    @@sftp = self.class.connect
  end

  # instance-level (re-)connect
  def connect!
    @@sftp = self.class.connect!
  end
  
end
