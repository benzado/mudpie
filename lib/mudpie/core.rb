class String

	def append_path_component(component)
		p = self + '/' + component
		p.sub! /\/+/, '/'
	end

	def path_extension
		i = self.rindex('.')
		if i then
			j = i + 1
			self[j, self.length - j]
		else
			""
		end
	end

end
