module json112

import ast

//解析器 json string to object
struct Parser{
	//json原始字符串
	json_str string
	//是否允许有注释
	allow_comments bool
mut:
	//扫描器实例
	scanner &Scanner
    //上一个token
	prev_tok Token
	//当前token
	tok      Token
	//下一个token
	peek_tok Token
	//保存解析后的节点
	all_node map[string]Json112Node
	//格式化json字符串
    ast_json_object ast.JsonObject
}

//初始化
fn new_parser(json_str string,allow_comments bool)? &Parser{
	parser := &Parser{
		json_str:json_str
		allow_comments:allow_comments
		scanner:new_scanner(json_str,allow_comments,'utf8')?
	}

	return parser
}

fn (mut p Parser) init_parser(){
	first_tok := p.scanner.scan()
	second_tok := p.scanner.scan()
	p.tok = first_tok
	p.peek_tok = second_tok
}

[inline]
fn (mut p Parser) next_token(){
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.scanner.scan()
}

//入口函数
fn (mut p Parser) parse() ?Json112{
	p.init_parser()

	if p.tok.kind == .begin_object{
		p.decl_object('')?
	}else{
		log('Parser.parse 0001')
		return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
	}

	if p.peek_tok.kind != .eof{
		log('Parser.parse 0002')
		return error('SyntaxError: Unexpected end of JSON input')
	}

	//log(p.all_node)
	return Json112{
		all_nodes:p.all_node
		formatted_str:p.json_str
	}
}

fn (mut p Parser) decl_object(prev_node_name string)?{
	mut is_first := true
	for{
		p.next_token()
		tok := p.tok
		
		match tok.kind{
			.string{
				p.next_token()
				if p.tok.kind != .colon{
					log('Parser.decl_object 0001')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				
				mut name := prev_node_name
				unsafe{
					name = name + '["' + p.prev_tok.val.string_val + '"]'
				}

				p.next_token()
				match p.tok.kind{
					.string{
						node := Json112Node{
							node_typ:.string
							node_val:p.tok.val
						}
						p.all_node[name] = node
					}
					.number{
						node := Json112Node{
							node_typ:.number
							node_val:p.tok.val
						}
						p.all_node[name] = node
					}
					.boolean{
						node := Json112Node{
							node_typ:.boolean
							node_val:p.tok.val
						}
						p.all_node[name] = node
					}
					.null{
						node := Json112Node{
							node_typ:.null
							node_val:p.tok.val
						}
						p.all_node[name] = node
					}
					.begin_object{
						node := Json112Node{
							node_typ:.object
							node_val:p.tok.val
						}
						p.all_node[name] = node
						p.decl_object(name)?
					}
					.begin_array{
						node := Json112Node{
							node_typ:.array
							node_val:p.tok.val
						}
						p.all_node[name] = node

						arrlen := p.decl_array(name)?
						len_node := Json112Node{
							node_typ:.number
							node_val:ConvertedValue{number_val:arrlen}
						}
						p.all_node[name+'.len'] = len_node
					}
					else{
						log('Parser.decl_object 0002')
						return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
					}
				}

				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_object{
					log('Parser.decl_object 0003')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
			}
			.comma{
				if is_first {
					log('Parser.decl_object 0004')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}

				if p.peek_tok.kind != .string{
					log('Parser.decl_object 0005')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
			}
			.end_object{
				return
			}
			else{
				log('Parser.decl_object 0006')
				return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
			}
		}
	}
}

fn (mut p Parser) decl_array(prev_node_name string)?f64{
	mut is_first := true
	mut index := 0
	mut len := 0

	for{
		p.next_token()
		tok := p.tok
		match tok.kind{
			.string{
				name := prev_node_name + '[$index]'
				node := Json112Node{
					node_typ:.string
					node_val:p.tok.val
				}
				p.all_node[name] = node

				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_array{
					log('Parser.decl_array 0001')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
				len++
			}
			.number{
				name := prev_node_name + '[$index]'
				node := Json112Node{
					node_typ:.number
					node_val:p.tok.val
				}
				p.all_node[name] = node
				
				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_array{
					log('Parser.decl_array 0002')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
				len++
			}
			.boolean{
				name := prev_node_name + '[$index]'
				node := Json112Node{
					node_typ:.boolean
					node_val:p.tok.val
				}
				p.all_node[name] = node
				
				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_array{
					log('Parser.decl_array 0003')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
				len++
			}
			.null{
				name := prev_node_name + '[$index]'
				node := Json112Node{
					node_typ:.null
					node_val:p.tok.val
				}
				p.all_node[name] = node
				
				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_array{
					log('Parser.decl_array 0004')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
				len++
			}
			.begin_object{
				name := prev_node_name + '[$index]'
				node := Json112Node{
					node_typ:.object
					node_val:p.tok.val
				}
				p.all_node[name] = node
				p.decl_object(name)?

				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_array{
					log('Parser.decl_array 0005')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
				len++
			}
			.begin_array{
				name := prev_node_name + '[$index]'
				node := Json112Node{
					node_typ:.array
					node_val:p.tok.val
				}
				p.all_node[name] = node

				arrlen := p.decl_array(name)?
				len_node := Json112Node{
					node_typ:.number
					node_val:ConvertedValue{number_val:arrlen}
				}
				p.all_node[name+'.len'] = len_node

				if p.peek_tok.kind != .comma && p.peek_tok.kind != .end_array{
					log('Parser.decl_array 0006')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				is_first = false
				len++
			}
			.comma{
				if is_first {
					log('Parser.decl_array 0007')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}

				if p.peek_tok.kind !in [.string,.number,.boolean,.null,.begin_object,.begin_array]{
					log('Parser.decl_array 0008')
					return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
				}
				index++
			}
			.end_array{
				break
			}
			else{
				log('Parser.decl_array 0009')
				return error('SyntaxError: Unexpected token `${p.json_str[p.tok.pos..p.tok.pos+p.tok.len]}` in JSON at position ${p.tok.pos}')
			}
		}
	}
	return len
}
