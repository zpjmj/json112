module json112

[heap]
struct Json112{
	//格式化后的json字符串
	formatted_str string
pub:
	all_node map[string]Json112Node
}

fn (J Json112) str() string{
	return J.formatted_str
}

pub enum Json112NodeType{
	null
	boolean
	number
	string
	array
	object
}

struct Json112Node{
	node_typ Json112NodeType
	node_val ConvertedValue
}

//经过转换后的节点字符串
struct Json112NodeIndex{
	origin_str string
	node_index string
}

type NodeIndex=string|Json112NodeIndex

//判断节点是否存在
pub fn (J Json112) exist(node NodeIndex) bool{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}else{
		panic('The type of the input parameter must be string or Json112NodeIndex.')
	}

	return (node_index in J.all_node)
}

//获取节点的值 只能获取基本类型boolean number string的值
pub fn (J Json112) val<T>(node NodeIndex) T{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}else{
		panic('The type of the input parameter must be string or Json112NodeIndex.')
	}

	if !(node_index in J.all_node) {
		panic('Node does not exist.')
	}

	json_node := J.all_node[node_index]

	$if T is string{
		unsafe{
			return json_node.node_val.string_val
		}
	}$else $if T is bool{
		unsafe{
			return json_node.node_val.bool_val
		}
	}$else $if T is f64{
		unsafe{
			return json_node.node_val.number_val
		}
	}$else{
		panic('Only values of basic type `boolean number string` can be obtained')
	}
}

//判断节点的类型null boolean number string array object
pub fn (J Json112) typ(node NodeIndex) Json112NodeType{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}else{
		panic('The type of the input parameter must be string or Json112NodeIndex.')
	}

	if !(node_index in J.all_node) {
		panic('Node does not exist.')
	}

	json_node := J.all_node[node_index]

	return json_node.node_typ
}

//交友节点字符串并且转换为可以直接用于检索的节点字符串
pub fn node(node_str string) Json112NodeIndex{
	mut parser := new_node_parser(node_str)
	return parser.parse()
}

//encode json string to object
pub fn decode(json_str string,allow_comments ...bool) ?Json112{
	mut def_allow_comments := false
	if allow_comments.len != 0{
		def_allow_comments = allow_comments[0]
	}
	//创建解析器Parser
	mut parser := new_parser(json_str,def_allow_comments)?
	return parser.parse()
}

//encode object to json string
pub fn encode<T>(typ T,mapping map[string]string,beautify ...bool) ?string {
	return ""
}





