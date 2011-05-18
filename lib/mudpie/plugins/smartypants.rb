if require 'rubypants' then
	MudPie::FILTERS['smartypants'] = lambda do |item, text|
		RubyPants.new(text).to_html
	end
end
