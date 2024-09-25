
require 'csv'
require 'terminal-table'

class MySqliteRequest
	def initialize
		@columns = nil
		@select_file_name=nil
		@body = nil
		@dataset = nil
		@selected_columns = nil
		@result = nil
		@selected_columns_id = nil
		@index_update = nil
		@index_delete = nil
		@header = nil
		@body = nil
		@copy_result = nil
		@is_copy = false
		#methods
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
		@is_something_wrong=false
		#method priority
		@method_priority = {
			"FROM"=>1,
			"SELECT"=>4,
			"WHERE"=>3,
			"JOIN"=>2,
			"ORDER"=>5,
			"INSERT"=>1,
			"VALUES"=>2,
			"UPDATE"=>1,
			"SET"=>4,
			"DELETE"=>4,
		}
	end

	public
	def helper_find_column_index(columns,column_name)
		col_id = nil
		@header.each_with_index do |e,i|
            if column_name == e
                col_id = i
                break
            end
        end
        if col_id == nil
        	puts "helper_find_column_index: column_name not found"
        	@is_something_wrong=true
        end
        return col_id
	end

	def from(table_name)
		@methods.push("FROM")
		@from_table_name = table_name
		@select_file_name = table_name
		self
	end

	def select(*column_names)
		@methods.push("SELECT")
		@select_column_names = column_names
		self
	end

	def where(column_name,criteria)
		@methods.push("WHERE")
		@where_column_name = column_name
		@where_criteria = criteria
		self
	end
	
	def join(column_on_db_a, filename_db_b, column_on_db_b)
		@methods.push("JOIN")
		@join_column_on_db_a = column_on_db_a
		@join_filename_db_b = filename_db_b
		@join_column_on_db_b = column_on_db_b
		self
	end

	def order(order, column_name)
		@methods.push("ORDER")
		@order_order = order
		@order_column_name = column_name
		self
	end

	def insert(table_name)
		@methods.push("INSERT")
		@insert_table_name = table_name
		@select_file_name = table_name
		self
	end

	def values(data)
		@methods.push("VALUES")
		@values_data = data
		self
	end

	def update(table_name)
		@methods.push("UPDATE")
		@update_table_name = table_name
		@select_file_name = table_name
		self
	end

	def set(data)
		@methods.push("SET")
		@set_data = data
		self
	end

	def delete
		@methods.push("DELETE")
		self
	end
	
	private
	def _from(table_name)
		@dataset = CSV.read("#{table_name}.csv")
		@header = @dataset[0]
		@body = @dataset.drop(1)
		@result = @body
	end


	def _select(column_names)
		@selected_columns = column_names
        @selected_columns_id = column_names.map {|e| helper_find_column_index(@header,e)}
	end

	def _where(column_name,criteria)
		col_id = 0
        @header.each_with_index do |e,i|
            if column_name == e
                col_id = i
                break
            end
        end
        row_id = []
        @result.each_with_index do |e,i|
            if criteria == e[col_id]
                row_id.push(i)
            end
        end
        @index_update = row_id
        @index_delete = row_id
        @result = @result.values_at(*row_id)
	end

	def _join(column_on_db_a, filename_db_b, column_on_db_b)
		dataset_b = CSV.read("#{filename_db_b}.csv")
		header_b = dataset_b[0]
		body_b = dataset_b.drop(1)
		index_column_b = helper_find_column_index(header_b,column_on_db_b)
		if index_column_b
			index_column_a = helper_find_column_index(@header,column_on_db_a)
			if index_column_a
				based_column_a = @body.map {|e| e[index_column_a]}
				body_b.each do |e|
					match_index = []
					based_column_a.each_with_index do |x,i|
						if x == e[index_column_b]
							match_index.push(i)
						end
					end
					match_index.each do |k|
						@result[k].push(*e)
					end
				end
			else
				puts "Column name of first table is not found"
				@is_something_wrong=true
			end
		else
			puts "Column name of second table is not found"
			@is_something_wrong=true
		end
		@header.push(*header_b)
		# @select_column_names.push(*header_b)
	end

	def _order(order, column_name)
		find_index = helper_find_column_index(@header,column_name)
		if find_index
			@result = @result.sort_by {|e| e[find_index]}
			if order == "desc"
				@result = @result.reverse
			end
		else
			puts "Column name not found"
			@is_something_wrong=true
		end
	end

	def _insert(table_name)

		return _from(table_name)
	end

	def _values(data)
		list_values = []
		@header.each do |e|
			if data[e]
				list_values.push(data[e])
			else
				puts "Not found column `#{e}`"
				@is_something_wrong=true
			end
		end
		@result.push(list_values)
	end

	def _update(table_name)
		return _from(table_name)
	end

	def _set(data)
		list_keys = data.keys
		@result = @body
		list_keys.each do |e|
			find_index = helper_find_column_index(@header,e)
			@index_update.each do |x|
				@result[x][find_index] = data[e]
			end
		end
	end

	def _delete
		@result = @body
		list_del = @result.values_at(*@index_delete)
		@result = @result - list_del
	end


	
	def array_of_hashes_to_table(array_of_hashes)
	  headers = array_of_hashes[0]
	  rows = array_of_hashes.drop(1)

	  table = Terminal::Table.new :headings => headers, :rows => rows
	  puts table
	end
	def save_to_csv(file_name, data)
	  CSV.open(file_name, "w") do |csv|
	    data.each do |row|
	      csv << row
	    end
	  end
	end

	public
	def run
		methods_map = {
			"FROM"=>lambda{_from(@from_table_name)},
			"SELECT"=>lambda{_select(@select_column_names)},
			"WHERE"=>lambda{_where(@where_column_name,@where_criteria)},
			"JOIN"=>lambda{_join(@join_column_on_db_a,@join_filename_db_b,@join_column_on_db_b)},
			"ORDER"=>lambda{_order(@order_order,@order_column_name)},
			"INSERT"=>lambda{_insert(@insert_table_name)},
			"VALUES"=>lambda{_values(@values_data)},
			"UPDATE"=>lambda{_update(@update_table_name)},
			"SET"=>lambda{_set(@set_data)},
			"DELETE"=>lambda{_delete},
		}

		sorted_methods = @methods.sort_by {|e| @method_priority[e]}
		sorted_methods.each do |e|
			methods_map[e].call
		end
		final_result = []
		if @selected_columns_id
			final_result.push(@selected_columns)
			@result.each do|e|
				each_row = []
				@selected_columns_id.each do |x|
					each_row.push(e[x])
				end
				final_result.push(each_row)
			end
		else
			final_result.push(@header)
			final_result.push(*@result)
		end

		if @is_something_wrong==false
			if @methods.include?("SELECT")
				array_of_hashes_to_table(final_result)
			else
				save_to_csv("#{@select_file_name}.csv",final_result)
			end
		end
	end

end
