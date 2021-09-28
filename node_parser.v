module json112

struct NodeParser{
	//node原始字符串
	node_str string
mut:
	//扫描器实例
	scanner &NodeScanner
	//上一个token
	prev_tok NodeToken
	//当前token
	tok      NodeToken
	//下一个token
	peek_tok NodeToken
}

//初始化
fn new_node_parser(node_str string) &NodeParser{
	parser := &NodeParser{
		node_str:node_str
		scanner:new_node_scanner(node_str,'utf8')
	}

	//log(parser.scanner.all_tokens)
	return parser
}

fn (mut p NodeParser) init_parser(){
	first_tok := p.scanner.scan()
	second_tok := p.scanner.scan()
	p.tok = first_tok
	p.peek_tok = second_tok
}

[inline]
fn (mut p NodeParser) next_token(){
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.scanner.scan()
}

//入口函数
fn (mut p NodeParser) parse() Json112NodeIndex{
	p.init_parser()

	mut node_index := ''

	for{
		match p.tok.kind{
			.unknown,.index{
				node_index = node_index + p.tok.val
			}
			.name,.string{
				node_index = node_index + '["${p.tok.val}"]'
			}
			.dot{
				if p.peek_tok.kind != .name{
					node_index = node_index + p.tok.val
				}
			}
			else{
				break
			}
		}
		p.next_token()
	}

	return Json112NodeIndex{
		origin_str:p.node_str
		node_index:node_index
	}
}

