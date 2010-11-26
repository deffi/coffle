class Array
	def fill_length!(target_length, value=nil)
		return if target_length<=self.length

		self.concat [value]*(target_length-self.length)
	end

	def fill_length(target_length, value=nil)
		result=self.dup
		result.fill_length!(target_length, value)
		result
	end

	def format_table(separator=" ")
		# Determine the maximum size of each column
		column_widths=[]

		self.each do |row|
			column_widths.fill_length!(row.length, 0)

			row.each_with_index do |value, column|
				column_widths[column]=[column_widths[column], value.to_s.length].max
			end
		end

		self.map { |row|
			row.each_with_index.map { |value, column|
				value.to_s.ljust(column_widths[column])
			}.join(separator)
		}.join("\n")
	end
end

