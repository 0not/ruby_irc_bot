require 'rubygems'
require_gem 'activerecord'

ActiveRecord::Base.establish_connection(
	:adapter => "mysql",
	:username => "root",
	:host => "localhost",
	:password => "******",
	:database => "misc" )
class PHPFunctions < ActiveRecord::Base
end
