require 'pry'
require 'httparty'
require 'nokogiri'
require 'json'

approved_pairs_url = 'http://cs.brown.edu/degrees/undergrad/concentrations/approvedpairs/'

def get_pairs(table_rows)
  pairs = {}
  cur_course = nil
  table_rows.each do |row|
    next if row.content == "\n"
    cur_course = row.children.first.content.gsub("-", "") unless row.children.first.content.empty?
    children = row.children[1..-1]
    pairs[cur_course] = pairs.fetch(cur_course, []) +
      children.map(&:content).map { |e| e.gsub("-", "") }
        .select { |e| !e.empty? }
  end
  pairs
end

def get_nodes(pairs_hash)
  pairs_hash
    .inject([]) { |node_list, (key, value)| node_list + value.unshift(key) }
    .uniq.sort.map { |e| { name: e } }
end

def get_node_index(node_name, nodes)
  nodes.find_index { |n| n[:name] == node_name }
end

def get_edges(pairs_hash, nodes)
  pairs_hash.inject([]) do |edge_list, (key, value)|
    source = get_node_index(key, nodes)
    edge_list + value.map do |e|
      { source: source, target: get_node_index(e, nodes) }
    end
  end
end

html = Nokogiri::HTML(HTTParty.get(approved_pairs_url))
cs_table = html.css('table').children.first
eng_table = html.css('table').children.last

cs_pairs = cs_table.children[1..-1]
eng_pairs = eng_table.children[1..-1]

cs_pairs_hash = get_pairs(cs_pairs)
eng_pairs_hash = get_pairs(eng_pairs)
pairs_hash = cs_pairs_hash.merge(eng_pairs_hash)
nodes = get_nodes(pairs_hash)
edges = get_edges(pairs_hash, nodes)

File.open('pairs.json', 'w') { |file| file.write(JSON.pretty_generate(nodes: nodes, links: edges)) }
