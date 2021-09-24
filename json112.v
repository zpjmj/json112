module json112

[heap]
struct Json112{

}

pub enum Json112Type{
	null
	boolean
	number
	string
	array
	object
}

pub fn (J Json112) exist(node string) bool{
	return true
}

pub fn (J Json112) value<T>(node string) T{
	return T{}
}

pub fn (J Json112) val<T>(node string) T{
	return T{}
}

pub fn (J Json112) typ(node string) Json112Type{
	return .null
}

//encode json string to object
pub fn decode(json_str string,allow_comments ...bool) ?Json112{
	mut def_allow_comments := false
	if allow_comments.len != 0{
		def_allow_comments = allow_comments[0]
	}
	//创建解析器Parser
	mut parser := new_parser(json_str,def_allow_comments)
	return parser.parse()
}

//encode object to json string
pub fn encode<T>(typ T,mapping map[string]string,beautify ...bool) ?string {
	return ""
}





