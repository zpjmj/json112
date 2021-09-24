module json112

struct Token{
	//token种类
	kind Kind
	//token位置
	pos int
	//token字符长度
	len int
}

enum Kind{
	unknown
	eof
	null
	boolean
	number
	string
	begin_objec // {
	begin_array // [
	end_object // }
	end_array // ]
	colon // :
	comma // ,
	comment
}

struct NodeToken{
	kind NodeKind

}

enum NodeKind{
	unknown
	name
	index // 123
	lsbr // [
	rsbr // ]
	dot // .
}