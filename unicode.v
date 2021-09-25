module json112

struct Unicode{
mut:
	//码点
	code_point u32
	//相对pos的偏移
	pos_offset int
	//此码点在原始字符串中的size
	size int
}