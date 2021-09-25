module json112

struct Null{
	
}

union ConvertedValue{
mut:
	unknown_val int
	str_val []byte
	bool_val bool
	i64_val i64
	f64_val f64
	null_val Null
}

struct Token{
	//token种类
	kind Kind [required]
	//token位置
	pos int [required]
	//token字符长度
	len int [required]
	//type 类型
	typ string [required]
	//变换后的实际值
	val ConvertedValue [required]
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