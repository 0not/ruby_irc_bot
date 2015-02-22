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
        # :TriRift!~tririft.p@asterisk-1EC3FDFD.hsd1.ma.comcast.net
        @owner[:nick] = "Kyylle"
        @owner[:ident] = "Kylle" #"kyle" # all of the ident, usually the username
        @owner[:host] = "gateway/web/freenode/ip.205.185.99.123" # part or all of the host
        ##
        # Responses to the greatings
        @greetings = ['Hi', 'Hello', 'Hey', 'Hay', 'Hola', 'Sup', 'Whats up', 'Yo', 'Hi, I am tired', 'Sup, foolio']
        ##
        # Should the bot say hello when it connects?
        self.greet if say_hello
        
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
            ".about"=>"self.about",
            # switch channel
            ".switch"=>"self.join data[1]",
            ".txt2bin"=>"self.txt2bin data[1,data.length].collect {|x| ' '+x}",
            # shows the owner info, customize it!
            ".owner"=>"self.say '#{@owner[:nick]} is my overlord.  He owns http://www.*****.com.'"
        }
        ##
        # These are the commands that are protected.  only the owner can call them
        @my_cmds = ['.quit', '.nick', '.switch']
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
                ##
                # Are there any commands?  This bot won't even check for a command unless it starts with a dot (.)
                # and the caller is authorized
                check_for_cmd(info[4], info[0]) if info and info[4] =~ /^\.(.+)/ and auth(info)
                self.check_for_greet(info[4], info[0]) if info[4].include?(@config[:nick]) # should i respond with a greeting?
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
end

##
# Example usage:
# server, port, nick, channel
bob = IRCBot.new('irc.freenode.net', 6667, 'BasicBob', '#my_own_test_channel')
bob.main # engage the main loop
