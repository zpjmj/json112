module json112

//表示null值
struct Null{}

//指示token转换后值的类型
enum TokenValType{
	undefined
	null
	number
	string
	bool
}

//经过扫描器后转换后的实际值 主要是number和string中的转义处理
union ConvertedValue{
mut:
	skip int
	string_val string
	bool_val bool
	number_val f64
}

struct Token{
	//token种类
	kind Kind [required]
	//token位置
	pos int [required]
	//token字符长度
	len int [required]
	//type 类型
	typ TokenValType [required]
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
	begin_object // {
	begin_array // [
	end_object // }
	end_array // ]
	colon // :
	comma // ,
	comment
}

struct NodeToken{
	//token种类
	kind NodeKind [required]
	//token位置
	pos int [required]
	//token字符长度
	len int [required]
	//变换后的实际值
	val string [required]
}

enum NodeKind{
	unknown
	eof
	name   //xxx
	string// ["xxx"] 
	index // [0]
	dot
}