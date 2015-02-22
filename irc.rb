require 'socket'

class IRCBot < TCPSocket
    def initialize(server, port, nick, channel, say_hello = true)
        ##
        # Create a config and assign the variables to it
        @config = Hash.new
        @config[:server], @config[:port], @config[:nick], @config[:channel] = server, port, nick, channel
        ##
        # Calls the TCPSocket construct and passes the connection info
        @t = super(@config[:server], @config[:port])
        @t.puts "USER RHAP RHAP RHAP :RHAP \r\n"
        ##
        # Sets the nick of the bot
        @t.puts "NICK #{@config[:nick]} \r\n"
        ##
        # Join the specified channel
        self.join @config[:channel]
        ##
        # Sets various config and other options
        @owner = Hash.new
        ## 
        # The following is the format of what the bot recieves:
        # :kyle!~kyle@X-24735511.lmdaca.adelphia.net PRIVMSG #youngcoders :for the most part
        # :nick!~ident@host PRIVMSG #channel :message
        @owner[:nick] = "Kyylle"
        @owner[:ident] = "Kyylle" # all of the ident, usually the username
        @owner[:host] = "lmdaca.adelphia.net" # part or all of the host
        @config[:mode] = "normal"
        ##
        # Responses to the greatings
        @greetings = ['Hi', 'Hello', 'Hey', 'Hay', 'Hola', 'Sup', 'Whats up', 'Yo', 'Hi, I am tired', 'Sup, foolio']
        ##
        # Should the bot say hello when it connects?
        self.greet if say_hello
        ##
        # Lets get ready for trivia!!
        # This section grabs the questions from "questions.txt"
        # The questions are on the odd lines, and the answers are 1 line below (always on even lines)
        # It can be easily configured to grab questions out of a database
        # The format looks like this:
        # @questions[index] = {
        #       :question => "Is...?",
        #       :answer => "yes"}
        #
        # The answers are case insensitive, but the user must have it exact
        #
        @questions = Array.new
        qs = File.open "questions.txt", "r"
        c = 0
        ar = qs.readlines
        while c < (ar.length - 1)
            @questions[c/2.to_i] = {:question => ar[c].chomp, :answer => ar[c+1].chomp}
            c += 2
        end
        qs.close
        @trivia = {:start => nil, :end => nil, :number => 0, :last_hint => Time.now, :cur_quest => (rand @questions.length)}
        @score = Hash.new

        ##
        # This hash contains the commands that the bot responds to.
        # The key is the command and the value is what is evaled.
        # There might be a security risk in evaling stuff sent from the user,
        # but so far i haven't found one.
        # Most of the commands are self explainatory.
        @cmds = {
            ".quit"=>"self.quit",
            # changes my nick
            ".nick"=>"self.update_nick data[1]",
            # tell me what to say
            ".say"=>"self.say data[1,data.length].collect {|x| ' '+x}",
            # searches the database for the PHP function and displays the info in the channel
            ".php"=>"self.php_search data[1], @config[:channel]",
            # same as above, but PMs the requestee
            ".php_pm"=>"self.php_search data[1], nick",
            ".about"=>"self.about",
            # switch channel
            ".switch"=>"self.join data[1]",
            # mostly for debugging, it shows the current mode: non vital
            ".current_mode"=>"self.current_mode",
            ".trivia_start"=>"self.trivia_start",
            ".trivia_end"=>"self.trivia_end",
            ".score"=>"self.score data[1]",
            # only the owner can call .answer, it is protected
            ".answer"=>"self.answer",
            # gives a hint, must be called 5 seconds apart
            ".hint"=>"self.hint",
            # asks the current trivia question
            ".question"=>"self.ask_question",
            # skips and goes to the next question
            ".next"=>"self.next_q",
            # displays the greeting
            ".greet"=>"self.greet",
            # just a playful function, it turns the message into binary
            ".txt2bin"=> "self.txt2bin data[1,data.length].collect {|x| ' '+x}",
            # shows the owner info, customize it!
            ".owner"=>"self.say '#{@owner[:nick]} is my overlord.  He owns http://www.******.com.'"
        }
        ##
        # These are the commands that are protected.  only the owner can call them
        @my_cmds = ['.quit', '.nick', '.switch', '.answer']
    end
    ##
    # This is the main loop.  It gets the info from the IRC server and loops through it.  
    # It calls functions to parse for any recognized commands.
    def main
        @t.each do 
            |line|
            info = grab_info(line) # grabs the info from an PRIVMSG
            STDOUT.puts line, "\n" # puts to the console
            ##
            # An IRC client (a bot is a client) must respond to PINGs from the IRC server.
            # If not, the bot will be kicked.
            pong(line) if line[0..3] == "PING"
            if info and info[4] # only called if grabbing the info was successful
                log_it info # logs in a friendly format, in chat.txt
                ##
                # Are there any commands?  This bot won't even check for a command unless it starts with a dot (.)
                # and the caller is authorized
                check_for_cmd(info[4], info[0]) if info and info[4] =~ /^\.(.+)/ and auth(info)
                self.check_for_greet(info[4], info[0]) if info[4].include?(@config[:nick]) # should i respond with a greeting?
                if @config[:mode] == "trivia"
                    check_answer(info[4], info[0]) # did the user answer correctly?
                end
            end
        end
    end

    def check_for_cmd(cmd, nick)
        # split by space
        data = cmd.split
        if data and data[0] and @cmds.include? data[0]
            eval "#{@cmds[data[0]]}"
        end
    end

    ##
    # This is how the array is split, if you can't tell by the regex:
    # 0: user
    # 1: ident
    # 2: host
    # 3: channel/user
    # 4: message
    def grab_info(text)
        if text =~ /^\:(.+)\!\~?(.+)\@(.+) PRIVMSG \#?(\w+) \:(.+)/
            return [$1, $2, $3, $4, $5]
        else
            return false
        end
    end

    ##
    # Is the user authorized to use @my_cmds?
    def auth(array) # array is what is returned from grab_info
        STDOUT.puts array
        ##
        # If the called command is protected, proceed
        if @my_cmds.include?((array[4].to_s.split)[0])
            # authenticates 'nick', 'username', and then 'host' (in that order)
            if array[0] == @owner[:nick] and array[1] == @owner[:ident] and array[2].include?(@owner[:host]) # and array[4][0..8] == ".bot_quit" 
                return true
            else
                return false
            end
        else # else the command is not protected, and any user can use it
            return true
        end
    end

    ##
    # Playful function that converts text into binary
    def txt2bin(array)
        text = array.to_s.strip.unpack('B*').to_s
        i = 4
        while i <= text.length
            text.insert(i, ' ')
            i += 5
        end
        self.say "Binary: #{text}"
    end

    ##
    # Called if say_hello is true or by the .greet command
    def greet
        self.say "Hello, I am #{@config[:nick]}.  I am the resident uber-bot.  To learn more, type '.about'."
    end

    ##
    # This is the "about me" info.  Go ahead and customize it.
    def about
        cmds = String.new ""
        @cmds.each_pair {|k,v| (cmds << " #{k}") if not @my_cmds.include? k }
        self.say "These are the current recognized commands: \0037 #{cmds}"
        #greets = @greetings.collect {|x| ' '+x}
        self.say "I also respond to the following greetings (and my name): \0036 Hi, Hello, Hey, Hay, Hola, Sup, Whats up, Yo"
        self.say "What do I do?  What don't I do is more like it.  I keep logs of the IRC channel, I ask trivia questions, I search for php functions, and I can even say things if you know the right command.  Heck, I am so stuck up, I can't stop saying I!"
    end

    ##
    # Joins the requested channel and changes the current channel in @config
    def join(channel, quit_prev = true)
        @t.puts "PART #{@config[:channel]}" if quit_prev
        @t.puts "JOIN #{channel} \r\n"
        @config[:channel] = channel
    end

    ##
    # This logs the stuff said in "chat.txt"
    # 0: user
    # 1: ident
    # 2: host
    # 3: channel/user
    # 4: message
    # The array can be spoofed, look at self.say for an example
    def log_it(array)
        f = File.new("chat.txt", "a")
        string = "[#{Time.new.strftime "%m/%d/%Y %I:%M %p PST"}] <#{array[0]}> : #{array[4]} \n"
        f.puts string
        f.close
    end

    ##
    # Starts trivia mode, and asks a question.
    def trivia_start
        @config[:mode] = "trivia"
        @trivia[:start] = Time.now
        self.say "\00310Trivia mode is starting."
        self.ask_question(@trivia[:cur_quest])
    end

    ##
    # Ask the current question.
    def ask_question(num = @trivia[:cur_quest])
        self.say "\0036 #{@questions[num][:question]}"
        STDOUT.puts "\n :#{@questions[@trivia[:cur_quest]][:answer]}: \n"
    end

    ##
    # End trivia mode and return to normal.  Can restart with .trivia_start
    def trivia_end
        @config[:mode] = "normal"
        @trivia[:cur_quest] = 0
        self.say "\00310Trivia mode is over."
    end

    # says the answer
    def answer
        self.say "\0030 #{@questions[@trivia[:cur_quest]][:answer]}"
    end

    ##
    # Gives a hint for the current question.
    # Currently there are 5 different types of hints.  Go ahead and add more, just increase the rand parameter.
    def hint
        if @config[:mode] == "trivia" # make sure we are in trivia mode
            if (Time.now - @trivia[:last_hint]) >= 5 # make sure a hint wasn't requested less than 5 seconds ago
                rnd = rand 5
                hint = ""
                # answer length
                (hint = "It is #{@questions[@trivia[:cur_quest]][:answer].length} characters long.") if rnd == 0
                # start and ending letters
                (hint = "It starts with #{@questions[@trivia[:cur_quest]][:answer][0].chr} and ends with #{@questions[@trivia[:cur_quest]][:answer][-1].chr}.") if rnd == 1
                # shows the vowels
                (hint = "#{@questions[@trivia[:cur_quest]][:answer].gsub(/[^aeiou]/i, '*')}") if rnd == 2
                # converts each character into ascii
                (@questions[@trivia[:cur_quest]][:answer].each_byte {|c| hint << " #{c}"}) if rnd == 3
                # replaces the vowels with asterisks
                (hint = @questions[@trivia[:cur_quest]][:answer].gsub(/[aeiou]/, '*')) if rnd == 4
                self.say "\00313 Hint: #{hint}"
                @trivia[:last_hint] = Time.now
            else
                self.say "\0037 You have requested a hint less than 5 seconds ago."
            end
        else
            self.say "Not in trivia mode"
        end 
    end

    ##
    # Shows the score.
    # .score
    # will show all users and there scores (if they have answered at least one correctly)
    # .score nick
    # will show nicks score, if it exists, otherwise it will show the same as calling .score with now parameters
    def score(nick)
        if @score.has_key? nick
            self.say "Score: \0034 #{nick} \0035 #{@score[nick].to_s}"
        else
            score = ""
            @score.each_pair {|k,v| score << " \0034 #{k}: \0035 #{v}" }
            #(self.say 'Score:'+@score[nick]) if @score.has_key? nick
            self.say "Current scores: #{score}"
        end
    end

    ##
    # Skips the current question and moves on to the next
    # if called by '.next' then it will say the bot answered it, but the bot really doesn't get any points.
    def next_q(nick = @config[:nick])
        self.say "\0032Correct\0033 #{nick}.\0032  The answer was:\0034 #{@questions[@trivia[:cur_quest]][:answer]}"
        if @questions.length > (@trivia[:number] + 1)
            @trivia[:cur_quest] = (rand @questions.length)
            self.ask_question(@trivia[:cur_quest])
        else
            self.trivia_end
        end
    end

    ##
    # Checks to se if the users answer was correct
    def check_answer(text, nick)
        if (text.chomp.downcase == @questions[@trivia[:cur_quest]][:answer].downcase)
            if @score.has_key? nick
                @score[nick] += 1
            else
                @score[nick] = 1
            end
            self.next_q nick
        end
    end

    ##
    # Searches the (local) PHP database for the function name
    # the contents of 'php_lookup' are as follows:
    # 
    # require 'rubygems'
    # require_gem 'activerecord'
    #
    # ActiveRecord::Base.establish_connection(
    #   :adapter => "mysql",
    #   :username => "root",
    #   :host => "localhost",
    #   :password => "****",
    #   :database => "misc" )
    # class PHPFunctions < ActiveRecord::Base
    # end
    #
    # You must have ruby on rails installed correctly (or know what you are doing).
    # The database can be downloaded from (1.02MB):
    # http://www.webjunky.us/downloads/quicklookup.tar
    # 
    def php_search(function, nick = nil)
        require 'php_lookup'
        func = PHPFunctions.find(:first, :conditions => ["name = ?", function])
        if func
            self.say "\002PHP function:\002 \0034#{function}\0031 \002URL:\002 http://www.php.net/#{function}", nick
            self.say "\002Description:\002 \0037#{func.description}", nick
            self.say "\002Use:\002 \0036#{func.use1}", nick
        else
            self.say "#{function}, not found."
        end
    end

    ##
    # Checks to see if the bot should respond to a greeting
    # If so, then it randomly grabs a response.
    def check_for_greet(cmd, nick)
        if cmd =~ /\b(Hi|Hello|Hey|Hay|Hola|Sup|Whats up|Yo)\b/i
            self.say "#{@greetings[rand(@greetings.length)]}, #{nick}"
        end
    end

    ##
    # Outputs the message to the channel or nick
    def say(message, channel = @config[:channel])
        @t.puts "PRIVMSG #{channel} :#{message}"
        log_it([@config[:nick],"","","",message]) if channel == @config[:channel]
    end

    ##
    # Quit the IRC channel
    # It also quits the program, since the loop is over
    def quit(reason = "You told me to")
        @t.puts "QUIT :#{reason}"
        exit
    end

    ##
    # Respond to PINGs
    def pong(line)
        line[0..3] = "PONG"
        @t.puts "#{line}"
        STDOUT.puts "#{line}"
    end

    #updates the nick
    def update_nick(nick = @config[:nick])
        @t.puts "NICK :#{nick}"
        @config[:nick] = nick
    end

    ##
    # Displays the current mode.
    # Useful to tell if trivia has been started
    def current_mode
        self.say "The current mode is: #{@config[:mode]}"
    end
end

##
# Example usage:
# server, port, nick, channel
bob = IRCBot.new('irc.freenode.net', 6667, 'BasicBob', '#my_own_test_channel')
bob.main # engage the main loop
