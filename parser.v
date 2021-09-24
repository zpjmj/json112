module json112

//解析器 json string to object
struct Parser{
	//json原始字符串
	json_str string
	//是否允许有注释
	allow_comments bool
	//扫描器实例
	scanner &Scanner
}

//初始化
fn new_parser(json_str string,allow_comments bool) Parser{
	parser := Parser{
		json_str:json_str
		allow_comments:allow_comments
		scanner:new_scanner(json_str)
	}
	
	return parser
}

//入口函数
fn (mut p Parser) parse() Json112{
	println('Parser.parse run')
	return Json112{}
}

