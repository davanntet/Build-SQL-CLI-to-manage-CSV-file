require_relative "my_sqlite_request"
require "csv"
class MySqlite
	def initialize
		@str_cli = nil
		@starter_cli = ["select ","insert into ","update ","delete from "]
		@first_cli = nil
		@continue_cli = {"select "=>" from ","insert into "=>" values","update "=>" where ","delete from "=>" where "}
		@mysqlite = MySqliteRequest.new
		@headers = nil
		@methods = []
		#from
		@from_table_name = nil
		#select
		@select_column_names = nil
		#where
		@where_column_name = nil
		@where_criteria = nil
		#join
		@join_column_on_db_a = nil
		@join_filename_db_b = nil
		@join_column_on_db_b = nil
		#order
		@order_order = nil
		@order_column_name = nil
		#insert
		@insert_table_name = nil
		#values
		@values_data = nil
		#update
		@update_table_name = nil
		#set
		@set_data = nil
		# method priority
		@method_priority = {
			"FROM"=>1,
			"SELECT"=>2,
			"WHERE"=>5,
			"JOIN"=>4,
			"ORDER"=>6,
			"INSERT"=>1,
			"VALUES"=>2,
			"UPDATE"=>1,
			"SET"=>4,
			"DELETE"=>1,
		}
	end

	def check_cli?(str_cli)
		str_cli = str_cli.strip.downcase
		@starter_cli.each do |e|
			if str_cli.include?(e)
				if str_cli.include?(@continue_cli[e])
					@first_cli = e.strip
					return true
				end
			end
		end
		return false
	end

	def insert_into
		val = @str_cli.scan(/Insert into\s+(\w+)/i).flatten.first
		@insert_table_name = val.strip
		dataset = CSV.read("#{@insert_table_name}.csv")
		@headers = dataset[0]
	end
	def _insert_into
		@methods.push("INSERT")
	end

	def values
		val = @str_cli.scan(/\((.*?)\)/).flatten
		val = val.map { |e| e.gsub(/['"]/, '')}[0].split(",")
		@values_data = @headers.zip(val).to_h
	end
	def _values
		@methods.push("VALUES")
	end

	def update
		@update_table_name = @str_cli.scan(/update\s+(\w+)\s+set/i).flatten.first
		dataset = CSV.read("#{@update_table_name}.csv")
		@headers = dataset[0]
	end
	def _update
		@methods.push("UPDATE")
	end 

	def set
		@set_data = Hash[*@str_cli.scan(/set\s+(\w+)\s*=\s*([\w']+)/i).flatten]
	end
	def _set
		@methods.push("SET")
	end

	def where
		vals = @str_cli.scan(/where\s+(.+?)(\s+order\s+by\s+\w+)?$/i).flatten.first.split("=")
		@where_column_name = vals[0].strip
		@where_criteria = vals[1].strip
	end
	def _where
		@methods.push("WHERE")
	end

	def delete_from
		
	end
	def _delete_from
		_from
		@methods.push("DELETE")
	end

	def order_by
		vals = @str_cli.scan(/order by\s+(\w+)\s*(asc|desc)?/i).flatten
		if vals[1]
			@order_order = vals[1]
		end
		@order_column_name = vals[0]
	end
	def _order_by
		@methods.push("ORDER")
	end

	def select
		@select_column_names =  @str_cli.scan(/select\s+(.*?)\s+from/i).flatten.first
		@select_column_names = @select_column_names.split(',').map(&:strip) unless @select_column_names == '*'
		if @select_column_names == "*"
			@select_column_names = @headers
		end
	end
	def _select
		@methods.push("SELECT")
	end

	def from
		@from_table_name = @str_cli.scan(/from\s+(\w+)/i).flatten.first
		dataset = CSV.read("#{@from_table_name}.csv")
		@headers = dataset[0]
	end
	def _from
		@methods.push("FROM")
	end

	def join
		vals = @str_cli.scan(/from\s+(\w+)\s+join\s+(\w+)/i).flatten
		on_vals = @str_cli.scan(/on\s+(.+?)\s+where/i).flatten.first
		on_vals_ = @str_cli.scan(/(\w+)\.(\w+)/)
		# Construct the hash
		on_vals_ = on_vals_.each_with_object({}) do |(table, column), hash|
		  hash[table] = column
		end
		@from_table_name = vals[0].strip
		dataset = CSV.read("#{@from_table_name}.csv")
		@headers = dataset[0]
		@join_filename_db_b = vals[1].strip
		@join_column_on_db_a = on_vals_[@from_table_name]
		@join_column_on_db_b = on_vals_[@join_filename_db_b]
		if File.exist?("#{@join_filename_db_b}.csv")
			dataset_b = CSV.read("#{@join_filename_db_b}.csv")
			header_b = dataset_b[0]
			@select_column_names.push(*header_b)
		end
	end
	def _join
		@methods.push("JOIN")
	end

	def query(str_cli)
		@str_cli = str_cli
		pointers = {
			"insert into" => {"key"=>"values","continue"=>false,"start"=>lambda{_insert_into},"end"=>lambda{_values}},
			"update" => {"key"=>"set","continue"=>true,"start"=>lambda{_update},"end"=>lambda{_set}},
			"set" => {"key"=>"where","continue"=>false,"start"=>lambda{_set},"end"=>lambda{_where}},
			"where"=>{"key"=>"order by","continue"=>false,"start"=>lambda{_where},"end"=>lambda{_order_by}},
			"delete from" => {"key"=>"where","continue"=>false,"start"=>lambda{_delete_from},"end"=>lambda{_where}},
			"select" => {"key"=>"from","continue"=>true,"start"=>lambda{_select},"end"=>lambda{_from}},
			"from" => {"key"=>"join","continue"=>true,"start"=>lambda{_from},"end"=>lambda{_join}},
			"join" => {"key"=>"where","continue"=>true,"start"=>lambda{_join},"end"=>lambda{_where}},
		}

		execute_map = {
			"FROM"=>lambda{from},
			"SELECT"=>lambda{select},
			"WHERE"=>lambda{where},
			"JOIN"=>lambda{join},
			"ORDER"=>lambda{order_by},
			"INSERT"=>lambda{insert_into},
			"VALUES"=>lambda{values},
			"UPDATE"=>lambda{update},
			"SET"=>lambda{set},
			"DELETE"=>lambda{delete_from},
		}

		methods_map = {
			"FROM"=>lambda{@mysqlite.from(@from_table_name)},
			"SELECT"=>lambda{@mysqlite.select(*@select_column_names)},
			"WHERE"=>lambda{@mysqlite.where(@where_column_name,@where_criteria)},
			"JOIN"=>lambda{@mysqlite.join(@join_column_on_db_a,@join_filename_db_b,@join_column_on_db_b)},
			"ORDER"=>lambda{@mysqlite.order(@order_order,@order_column_name)},
			"INSERT"=>lambda{@mysqlite.insert(@insert_table_name)},
			"VALUES"=>lambda{@mysqlite.values(@values_data)},
			"UPDATE"=>lambda{@mysqlite.update(@update_table_name)},
			"SET"=>lambda{@mysqlite.set(@set_data)},
			"DELETE"=>lambda{@mysqlite.delete},
		}

		is_continue = true
		next_point = @first_cli.strip.downcase
		while is_continue
			if @str_cli.strip.downcase.include?(next_point)
				pointers[next_point]["start"].call
			end
			if pointers[next_point]["continue"] == false && @str_cli.strip.downcase.include?(pointers[next_point]["key"])
				pointers[next_point]["end"].call
			end
			is_continue = pointers[next_point]["continue"]
			next_point = pointers[next_point]["key"]
		end
		@methods = @methods.sort_by {|e| @method_priority[e]}
		@methods.each do |e|
			execute_map[e].call
		end
		@methods.each do |e|
			methods_map[e].call
		end
		@mysqlite.run()
	end
end


def start
	puts "MySQLite version 0.1 2024-09-14"
	input_cli = ""
	while input_cli!='quit'
		print "my_sqlite_cli> "
		input_cli = STDIN.gets.chomp
		if input_cli=="quit"
			break
		end
		exector = MySqlite.new
		if exector.check_cli?(input_cli)
			exector.query(input_cli)
			puts "correct"
		else
			puts "cli is incorrect, please try again with correctly cli."
		end
	end
	puts "👽 Hacked 🤧"
end

start