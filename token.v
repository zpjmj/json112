module json112

struct JsonToken{
	Kind JsonKind

}

enum JsonKind{
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
	Kind NodeKind

}

enum NodeKind{
	unknown
	name
	index // 123
	lsbr // [
	rsbr // ]
	dot // .
}