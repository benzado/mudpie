if require 'markdown' then
	MudPie::FILTERS['markdown'] = lambda do |item, text|
		Markdown.new(text).to_html
	end
end
