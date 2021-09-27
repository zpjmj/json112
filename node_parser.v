module json112

struct NodeParser{

}

//初始化
fn new_node_parser(node_str string) &NodeParser{
	parser := &NodeParser{
	}

	return parser
}

//入口函数
fn (mut p NodeParser) parse() Json112NodeIndex{
	return Json112NodeIndex{}
}
