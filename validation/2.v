import json
//string => struct

struct Tes{
	name string
	age int
}

struct Tes2{
	name1 string
	age2 int
	age3 int
}

fn main(){
	a:='{"name":"aaa","age":15}'
	b:=json.decode(Tes,a) or {panic(err)}
	println(b)
}
