class Object
	def self.lazy_attr_reader(*names)
		names.each do |name|
			define_method(name) {
				name=name.to_s
				name=name[0...-1] if name.end_with?('?')

				instance_variable_name="@#{name}"
				initializer_method_name="#{name}!"

				if ! instance_variable_defined? instance_variable_name
					instance_variable_set(instance_variable_name, send(initializer_method_name))
				end

				instance_variable_get(instance_variable_name)
			}
		end
	end

	def self.lazy_attr_accessor(*names)
		lazy_attr_reader(*names)
		attr_writer(*names)
	end
end

