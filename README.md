Ruby IRC Bot
============

I wrote this bot in 2006 (as a junior in high school). I cannot guarantee that it is free from vulnerabilities. 
In fact, I can probably guarantee the opposite, since it uses `eval`. You've been warned.

There are two versions. `irc.rb` is the full featured version with trivia and PHP function lookup. 
Please note, the trivia questions suck. I don't know who wrote them. The PHP lookup uses an SQL database.
I think it would be much better to use some API. `irc_small.rb` is a lot simpler (half the lines of code).

I am releasing this code just in case someone finds it useful. I will not update it. It probably isn't the best way to do things.
I wrote it while teaching myself ruby. If you use it, please be careful!

Installation and Usage
----------------------

To install, just clone the repo. If you want to use `irc.rb` and the PHP function lookup, you need to have a database with the included data.
If you just want to use `irc_small.rb` then nothing else should be needed. You can edit the last two lines of either ruby file, to include
your connection details. Also, don't forget to edit the `@owner` info.  To run, simply execute the file: `ruby irc_small.rb`.
