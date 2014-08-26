require 'pry'
require 'httparty'
require 'nokogiri'
require 'json'

def get_pairs(table_rows)
  pairs = {}
  cur_course = nil
  table_rows.each do |row|
    next if row.content == "\n"
    cur_course = row.children.first.content unless row.children.first.content.empty?
    children = row.children[1..-1]
    pairs[cur_course] = pairs.fetch(cur_course, []) +
      children.map(&:content).select { |e| !e.empty? }
  end
  pairs
end

approved_pairs_url = 'http://cs.brown.edu/degrees/undergrad/concentrations/approvedpairs/'

html = Nokogiri::HTML(HTTParty.get(approved_pairs_url))
cs_table = html.css('table').children.first
eng_table = html.css('table').children.last

cs_pairs = cs_table.children[1..-1]
eng_pairs = eng_table.children[1..-1]

cur_course = nil
cs_pairs_hash = get_pairs cs_pairs
eng_pairs_hash = get_pairs eng_pairs
pairs_hash = cs_pairs_hash.merge(eng_pairs_hash)

File.open('pairs.json', 'w') { |file| file.write(JSON.pretty_generate(pairs_hash)) }
