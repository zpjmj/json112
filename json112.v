module json112

[heap]
struct Json112{
pub mut:
	byte_len int
	all_nodes map[string]Json112Node
	child_node []string
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
mut:
	node_typ Json112NodeType
	node_val ConvertedValue
	child_node []string
}

//经过转换后的节点字符串
struct Json112NodeIndex{
	origin_str string
	node_index string
	parent_node_index string
}

type NodeIndex=string|Json112NodeIndex

pub fn (J Json112) str() string{
	return J.stringify([]string{},4)
}

//判断节点是否存在
pub fn (J Json112) exist(node NodeIndex) bool{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}

	return (node_index in J.all_nodes)
}

//获取节点的值 只能获取基本类型boolean number string的值
pub fn (J Json112) val<T>(node NodeIndex) ?T{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}

	if !(node_index in J.all_nodes) {
		return error('Node does not exist.')
	}

	json_node := J.all_nodes[node_index]

	$if T is string{
		if json_node.node_typ != .string{
			return error('The node type is ${json_node.node_typ}, not string')
		}

		unsafe{
			return json_node.node_val.string_val
		}
	}$else $if T is bool{
		if json_node.node_typ != .boolean{
			return error('The node type is ${json_node.node_typ}, not boolean')
		}

		unsafe{
			return json_node.node_val.bool_val
		}
	}$else $if T is f64{
		if json_node.node_typ != .number{
			return error('The node type is ${json_node.node_typ}, not number')
		}

		unsafe{
			return json_node.node_val.number_val
		}
	}$else{
		return error('Only values of basic type `boolean number string` can be obtained')
	}
}

//判断节点的类型null boolean number string array object
pub fn (J Json112) typ(node NodeIndex) ?Json112NodeType{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}

	if !(node_index in J.all_nodes) {
		return error('Node does not exist.')
	}

	json_node := J.all_nodes[node_index]

	return json_node.node_typ
}

//删除指定节点
pub fn (mut J Json112) remove(node NodeIndex) {
	mut node_index := ''
	mut parsed_node := Json112NodeIndex{}

	if node is Json112NodeIndex{
		node_index = node.node_index
		parsed_node = node
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node = parser.parse()
		node_index = parsed_node.node_index
	}

	if !(node_index in J.all_nodes) {
		return
	}

	len_node_index := parsed_node.parent_node_index + '["len"]'

	if len_node_index == node_index{
		return
	}

	j_str := J.stringify([parsed_node.origin_str],0)

	mut j112 := decode(j_str) or {return}

	unsafe{
		J.free()
	}

	J = j112
}


// //删除指定节点
// pub fn (mut J Json112) remove(node NodeIndex) {
// 	mut node_index := ''
// 	mut parsed_node := Json112NodeIndex{}

// 	if node is Json112NodeIndex{
// 		node_index = node.node_index
// 		parsed_node = node
// 	}else if node is string{
// 		mut parser := new_node_parser(node)
// 		parsed_node = parser.parse()
// 		node_index = parsed_node.node_index
// 	}

// 	if !(node_index in J.all_nodes) {
// 		return
// 	}

// 	json_node := J.all_nodes[node_index]

// 	if json_node.node_typ == .array{
// 		J.remove_arr_node(node_index)
// 	}else if json_node.node_typ == .object{
// 		J.remove_obj_node(node_index)
// 	}

// 	if parsed_node.parent_node_index.len == 0{
// 		for i,n_name in J.child_node{
// 			if '["$n_name"]' == node_index {
// 				J.child_node.delete(i)
// 				break
// 			}
// 		}
// 	}else{
// 		parent_json_node := J.all_nodes[parsed_node.parent_node_index]

// 		if parent_json_node.node_typ == .object{
// 			for i,n_name in parent_json_node.child_node{
// 				if parsed_node.parent_node_index + '["$n_name"]' == node_index {
// 					J.all_nodes[parsed_node.parent_node_index].child_node.delete(i)
// 					break
// 				}
// 			}
// 		}else{
// 			len_node_index := parsed_node.parent_node_index + '["len"]'

// 			if len_node_index == node_index{
// 				return
// 			}

// 			mut arr_len := 0
// 			unsafe{
// 				arr_len=int(J.all_nodes[len_node_index].node_val.number_val)
// 			}
			
// 			mut start:=node_index.len - 1

// 			for i:=node_index.len - 2;i>=0;i--{
// 				if node_index[i].is_digit(){
// 					start = i
// 				}else{
// 					break
// 				}
// 			}
// 			now_arr_index:=node_index[start..node_index.len - 1].int()

// 			unsafe{
// 				J.all_nodes[len_node_index].node_val.number_val--
// 			}
			
// 			for i:=now_arr_index;i<arr_len-1;i++{
// 				member_json_node := J.all_nodes[parsed_node.parent_node_index + '[$i]']



// 				J.all_nodes[parsed_node.parent_node_index + '[$i]'] = J.all_nodes[parsed_node.parent_node_index + '[${i + 1}]']
// 			}

// 			J.all_nodes.delete(parsed_node.parent_node_index + '[${arr_len - 1}]')
// 		}
// 	}

// 	J.all_nodes.delete(node_index)
// }

// fn (mut J Json112) remove_arr_node(node_index string) {
// 	len_node := node_index + '["len"]'
// 	defer{
// 		J.all_nodes.delete(len_node)
// 	}

// 	mut arr_len := 0
// 	unsafe{
// 		arr_len = int(J.all_nodes[len_node].node_val.number_val) 
// 	}

// 	for i:=0;i<arr_len;i++{
// 		arr_member_node_index := node_index + '[$i]'
// 		json_node := J.all_nodes[arr_member_node_index]

// 		if json_node.node_typ == .array{
// 			J.remove_arr_node(arr_member_node_index)
// 		}else if json_node.node_typ == .object{
// 			J.remove_obj_node(arr_member_node_index)
// 		}

// 		J.all_nodes.delete(arr_member_node_index)
// 	}
// }

// fn (mut J Json112) remove_obj_node(node_index string) {
// 	obj_json_node := J.all_nodes[node_index]
// 	child_node := obj_json_node.child_node

// 	for i in child_node{
// 		child_node_index := node_index + '["$i"]'
// 		json_node := J.all_nodes[child_node_index]

// 		if json_node.node_typ == .array{
// 			J.remove_arr_node(child_node_index)
// 		}else if json_node.node_typ == .object{
// 			J.remove_obj_node(child_node_index)
// 		}

// 		J.all_nodes.delete(child_node_index)
// 	}
// }

//追加节点
pub fn (mut J Json112) add(node NodeIndex)?{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}

	if node_index in J.all_nodes {
		return error('Node already exists.')
	}

}

//改变已有节点的值
pub fn (mut J Json112) change(node NodeIndex)?{
	mut node_index := ''
	if node is Json112NodeIndex{
		node_index = node.node_index
	}else if node is string{
		mut parser := new_node_parser(node)
		parsed_node := parser.parse()
		node_index = parsed_node.node_index
	}

	if !(node_index in J.all_nodes) {
		return error('Node does not exist.')
	}

}

[unsafe]
pub fn (mut J Json112) free(){
	unsafe{
		J.all_nodes.free()
		J.child_node.free()
	}
}

//交友节点字符串并且转换为可以直接用于检索的节点字符串
pub fn node(node_str string) Json112NodeIndex{
	mut parser := new_node_parser(node_str)
	return parser.parse()
}

//encode json string to object
pub fn decode(json_str string,allow_comments ...bool) ?Json112{
	mut def_allow_comments := false
	if allow_comments.len > 0{
		def_allow_comments = allow_comments[0]
	}
	//创建解析器Parser
	mut parser := new_parser(json_str,def_allow_comments)?
	return parser.parse()
}




// type VJsonNumber=i8|i16|int|i64|isize|byte|u16|u32|u64|usize
// //encode object to json string
// pub fn encode<T>(typ T,mut mapping ...map[string]string) string {
// 	mut mapping_default := map[string]string{}

// 	if mapping.len > 0 {
// 		 mapping[0].move(mapping_default)
// 	}
	
// 	return "{${encode_array(typ,mapping_default)}}"
// }

// fn encode_array<T>(typ T,mapping map[string]string)string{
// 	mut obj_str := ''
// 	mut arr_str := ''
// 	mut j_str := ''
// 	mut name := ''

// 	$for f in T.fields {
// 		$if f.typ is VJsonNumber {
// 			if f.name in mapping{
// 				name = mapping[f.name]
// 			}else{
// 				name = f.name
// 			}
// 			j_str +=  '"$name":' + f64(typ.$(f.name)).str()
// 		}$else $if f.typ is string {
// 			if f.name in mapping{
// 				name = mapping[f.name]
// 			}else{
// 				name = f.name
// 			}
// 			j_str +=  '"$name":"' + typ.$(f.name) + '"'
// 		}$else $if f.typ is bool {
// 			if f.name in mapping{
// 				name = mapping[f.name]
// 			}else{
// 				name = f.name
// 			}
// 			j_str +=  '"$name":' + typ.$(f.name).str()
// 		}$else $if f.typ is bool {

// 			mut type_name := typeof(f).name
// 			mut type_name2 := ''
// 			mut type_name4 := ''

// 			if type_name.len > 2{
// 				type_name2=type_name[0..2]
// 			}

// 			if type_name.len > 4{
// 				type_name4=type_name[0..4]
// 			}

// 			if type_name4 == 'map[' {
// 				if f.name in mapping{
// 					name = mapping[f.name]
// 				}else{
// 					name = f.name
// 				}
// 				j_str +=  '"$name":null'
// 			}else if type_name2 == '[]' {
// 				if f.name in mapping{
// 					name = mapping[f.name]
// 				}else{
// 					name = f.name
// 				}
// 				arr_str = encode_array(typ.$(f.name),mapping)

// 				j_str +=  '"$name":$arr_str'
// 			}else{
// 				if f.name in mapping{
// 					name = mapping[f.name]
// 				}else{
// 					name = f.name
// 				}
// 				obj_str = encode_object(typ.$(f.name),mapping)

// 				j_str +=  '"$name":$obj_str'
// 			}
// 		}

// 		j_str = j_str + ','
// 	}

// 	return "[$j_str]"
// }

// fn encode_object<T>(typ T,mapping map[string]string)string{
// 	mut obj_str := ''
// 	mut arr_str := ''
// 	mut j_str := ''
// 	mut name := ''
// 	$for f in T.fields {
// 		$if f.typ is VJsonNumber {
// 			if f.name in mapping{
// 				name = mapping[f.name]
// 			}else{
// 				name = f.name
// 			}
// 			j_str +=  '"$name":' + f64(typ.$(f.name)).str()
// 		}$else $if f.typ is string {
// 			if f.name in mapping{
// 				name = mapping[f.name]
// 			}else{
// 				name = f.name
// 			}
// 			j_str +=  '"$name":"' + typ.$(f.name) + '"'
// 		}$else $if f.typ is bool {
// 			if f.name in mapping{
// 				name = mapping[f.name]
// 			}else{
// 				name = f.name
// 			}
// 			j_str +=  '"$name":' + typ.$(f.name).str()
// 		}$else $if f.typ is bool {

// 			mut type_name := typeof(f).name
// 			mut type_name2 := ''
// 			mut type_name4 := ''

// 			if type_name.len > 2{
// 				type_name2=type_name[0..2]
// 			}

// 			if type_name.len > 4{
// 				type_name4=type_name[0..4]
// 			}

// 			if type_name4 == 'map[' {
// 				if f.name in mapping{
// 					name = mapping[f.name]
// 				}else{
// 					name = f.name
// 				}
// 				j_str +=  '"$name":null'
// 			}else if type_name2 == '[]' {
// 				if f.name in mapping{
// 					name = mapping[f.name]
// 				}else{
// 					name = f.name
// 				}
// 				arr_str = encode_array(typ.$(f.name),mapping)

// 				j_str +=  '"$name":$arr_str'
// 			}else{
// 				if f.name in mapping{
// 					name = mapping[f.name]
// 				}else{
// 					name = f.name
// 				}
// 				obj_str = encode_object(typ.$(f.name),mapping)

// 				j_str +=  '"$name":$obj_str'
// 			}
// 		}

// 		j_str = j_str + ','
// 	}

// 	return "[$j_str]"
// }


