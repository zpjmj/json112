module json112

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

//入口函数
fn (mut p Parser) parse() ?Json112{
	p.init_parser()
	
	
	return Json112{}
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

