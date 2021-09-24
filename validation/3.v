#flag -ID:\GIT\json112\validation
#include <3.h>

struct Tes{
	name string
	age int
}


fn C.jsonTestF()J112tye

fn main(){
	a := vlu_to_typ<int>('152')
	println(a)
	println(typeof(a).name)

	b := vlu_to_typ<string>('aaaaa')
	println(b)
	println(typeof(b).name)

	c := vlu_to_typ<string>('3.14')
	println(c)
	println(typeof(c).name)

	d := vlu_to_typ<Tes>('3.14')
	println(d)
	println(typeof(d).name)

}

type J112tye = int|string|f32|voidptr

fn vlu_to_typ<T>(s string) J112tye{
	$if T is int{
		return s.int()
	}

	$if T is f32{
		return s.f32()
	}

	$if T is string{
		return s
	}
	
	return C.jsonTestF() 
}