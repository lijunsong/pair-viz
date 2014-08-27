var width = 800;
var height = 600;

var svg = d3.select("body").append("svg")
.attr("width", width)
.attr("height", height);

var force = d3.layout.force()
    .gravity(.05)
    .distance(100)
    .charge(-100)
    .size([width, height]);


function get_related_courses(n, dependencies) {
    return dependencies[n.index];
}
// this is undirected graph, so n1 should be in n2's
// relation, vice versa.
function is_related(n1, n2, dependencies) {
    var related = dependencies[n2.index];
    for(var i = 0; i < related.length; i++) {
        if (related[i] == n1)
            return true;
    }
    return false;
}

// map from course name to dependency name list
function build_dependency(nodes, links) {
    var map = {};
    links.forEach(function(link) {
        var index = link.source.index;
        if (map[index] == null)
            map[index] = [link.target];
        else
            map[index].push(link.target);
    });
    return map;
}

function run(error, json) {
    /* force will build the index internally */
    force
        .nodes(json.nodes)
        .links(json.links)
        .start();

    // build dependency mapping
    var dependencies = build_dependency(json.nodes, json.links);

    var link = svg.selectAll(".link")
        .data(json.links)
        .enter().append("line")
        .attr("class", "link");

    var node = svg.selectAll(".node")
        .data(json.nodes)
        .enter().append("g")
        .attr("class", "node")
        .call(force.drag)
        // XXX: following code does not work as I expect it.
        .on("mouseover", function(d) {
            // color each node
            node.select("circle").attr("fill", function(n) {
                if (is_related(n, d, dependencies)) return "red";
                else
                    return "#EEE";
            });
            node.select("text").attr("fill", function(n) {
                if (is_related(n, d, dependencies)) return "red";
                else
                    return "#EEE";
            });
        })
        .on("mouseout", function() {
            node.select("circle").attr("fill", "steelblue");
            node.select("text").attr("fill", "black");
        });

    node.append("circle")
        .attr("r", 6);
    node.append("text")
        .attr("dx", 12)
        .attr("dy", ".35em")
        .text(function(d) { return d.name });

    force.on("tick", function() {
        link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

        node.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")";
        })
    });

}

d3.json("pairs.json", run);
