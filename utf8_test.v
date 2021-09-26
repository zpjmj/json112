module json112

fn test_utf8str_to_unicodepoint(){
	mut t:=Unicode{}
	//if str.len == 0 {
	t=utf8str_to_unicodepoint('',0) or {
		assert err.msg == 'Input string length = 0.'
		Unicode{}
	}

	//if pos >= str.len || pos < 0{
	t=utf8str_to_unicodepoint('12345',5) or {
		assert err.msg == 'Position < string.len.'
		Unicode{}
	}
	t=utf8str_to_unicodepoint('12345',6) or {
		assert err.msg == 'Position < string.len.'
		Unicode{}
	}
	t=utf8str_to_unicodepoint('12345',-1) or {
		assert err.msg == 'Position < string.len.'
		Unicode{}
	}

	//if first_bit == 0b0 {
	t=utf8str_to_unicodepoint('a',0) or {panic('test filed')}
	assert t.code_point == 97
	assert t.pos_offset == 0
	assert t.size == 1
	
	//if first_second_bit == 0b10{
	t=utf8str_to_unicodepoint('啊',1) or {panic('test filed')}
	assert t.code_point == 21834
	assert t.pos_offset == -1
	assert t.size == 3
	t=utf8str_to_unicodepoint('啊',2) or {panic('test filed')}
	assert t.code_point == 21834
	assert t.pos_offset == -2
	assert t.size == 3
	t=utf8str_to_unicodepoint('𒀂',3) or {panic('test filed')}
	assert t.code_point == 73730
	assert t.pos_offset == -3
	assert t.size == 4
	mut str := ''
	unsafe{
		c:=[]byte{cap:3,init:0b10}
		str=tos(c.data,3)
	}
	t=utf8str_to_unicodepoint(str,2) or {
		assert err.msg == 'Not found first byte.'
		Unicode{}
	}

	//if bit_123 == 0b00000110{
	t=utf8str_to_unicodepoint('£',0) or {panic('test filed')}
	assert t.code_point == 163
	assert t.pos_offset == 0
	assert t.size == 2

	//}else if bit_1234 == 0b00001110{
	t=utf8str_to_unicodepoint('啊',0) or {panic('test filed')}
	assert t.code_point == 21834
	assert t.pos_offset == 0
	assert t.size == 3

	//}else if bit_12345 == 0b00011110{
	t=utf8str_to_unicodepoint('𒀂',0) or {panic('test filed')}
	assert t.code_point == 73730
	assert t.pos_offset == 0
	assert t.size == 4

	//}else{
	unsafe{
		d:=[]byte{cap:3,init:0b11110}
		str=tos(d.data,3)
	}
	t=utf8str_to_unicodepoint(str,0) or {
		assert err.msg == 'Code point > U+1FFFFF.'
		Unicode{}
	}
}

fn test_unicodepoint_encode_to_utf8byte(){
	mut byte_arr:=[]byte{}
	unicodepoint_encode_to_utf8byte(0x1FFFFF1) or {
		assert 'Code point > U+1FFFFF.' == err.msg 
	}

	//if codepoint < 0x0080 {
	byte_arr = unicodepoint_encode_to_utf8byte(97) or {panic('test filed')}
	assert byte_arr.len == 1
	assert byte_arr[0] == 97

	//}else if codepoint < 0x0800{
	byte_arr = unicodepoint_encode_to_utf8byte(163) or {panic('test filed')}
	assert byte_arr.len == 2
	assert byte_arr[0] == 194
	assert byte_arr[1] == 163

	//}else if codepoint < 0x10000{
	byte_arr = unicodepoint_encode_to_utf8byte(21834) or {panic('test filed')}
	assert byte_arr.len == 3
	assert byte_arr[0] == 229
	assert byte_arr[1] == 149
	assert byte_arr[2] == 138

	//}else{
	byte_arr = unicodepoint_encode_to_utf8byte(73730) or {panic('test filed')}
	assert byte_arr.len == 4
	assert byte_arr[0] == 240
	assert byte_arr[1] == 146
	assert byte_arr[2] == 128
	assert byte_arr[3] == 130
}