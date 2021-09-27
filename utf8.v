module json112

//uts8字符编码转换为unicode码点
//str:需要转换的utf8字符串
//pos:字符位置
[inline]
fn utf8str_to_unicodepoint(str string,pos int)?Unicode{
	//pos位置check
	if str.len == 0 {
		log('utf8str_to_unicodepoint 0001')
		return error('Input string length = 0.')
	}

	if pos >= str.len || pos < 0{
		log('utf8str_to_unicodepoint 0002')
		return error('Position < string.len.')
	}

	//获取先头1位和2位
	first_bit := byte(str[pos] >> 7)
	first_second_bit := byte(str[pos] >> 6)

	//线头1位=0 ascii字符
	if first_bit == 0b0 {
		return Unicode{
			code_point:u32(str[pos])
			pos_offset:0
			size:1
		}
	}

	//线头2位=10 pos指定的位置是一个多字节字的中间
	if first_second_bit == 0b10{
		for i:=pos-1;i>=0;i--{
			//每次向前找1byte
			c:=byte(str[i] >> 6)
			//找的11开头的多字节字的首个字符
			if c == 0b11{
				//递归调用
				u:=utf8str_to_unicodepoint(str,i)?
				return Unicode{
					code_point:u.code_point
					pos_offset:i-pos //pos_offset为相对传入pos的偏移量为负值
					size:u.size
				}
			} 
		}
		log('utf8str_to_unicodepoint 0003')
		return error('Not found first byte.')
	}

	//获取多字节字的 123 1234 12345 位
	bit_123 := byte(str[pos] >> 5)
	bit_1234 := byte(str[pos] >> 4)
	bit_12345 := byte(str[pos] >> 3)

	mut unicode:=Unicode{
		code_point:0
		pos_offset:0
	}
	//为2byte的utf8字时
	if bit_123 == 0b00000110{
		if str.len - pos < 2{
			log('utf8str_to_unicodepoint 0004')
			return error('This code point requires at least 2 bytes.')
		}	
		unicode.size = 2
		unicode.code_point |= u32(byte(str[pos] << 3)) << 3
		unicode.code_point |= u32(byte(str[pos+1] << 2)) >> 2
	//为3byte的utf8字时
	}else if bit_1234 == 0b00001110{
		if str.len - pos < 3{
			log('utf8str_to_unicodepoint 0005')
			return error('This code point requires at least 3 bytes.')
		}
		unicode.size = 3
		unicode.code_point |= u32(byte(str[pos] << 4)) << 8
		unicode.code_point |= u32(byte(str[pos+1] << 2)) << 4
		unicode.code_point |= u32(byte(str[pos+2] << 2)) >> 2
	//为4byte的utf8字时
	}else if bit_12345 == 0b00011110{
		if str.len - pos < 4{
			log('utf8str_to_unicodepoint 0006')
			return error('This code point requires at least 4 bytes.')
		}
		unicode.size = 4
		unicode.code_point |= u32(byte(str[pos] << 5)) << 13
		unicode.code_point |= u32(byte(str[pos+1] << 2)) << 10
		unicode.code_point |= u32(byte(str[pos+2] << 2)) << 4
		unicode.code_point |= u32(byte(str[pos+3] << 2)) >> 2
	}else{
		//大于4byte的utf8字暂时不支持
		//目前最大应该为 0x10FFFF 但多处理一些应该也没有问题吧
		log('utf8str_to_unicodepoint 0007')
		return error('Code point > U+1FFFFF.')
	}

	return unicode
}

//unicode码点转换为uts8字符编码
[inline]
fn unicodepoint_encode_to_utf8byte(codepoint u32)?[]byte{
	//大于4byte的utf8字暂时不支持
	if codepoint > 0x1FFFFF{
		log('unicodepoint_encode_to_utf8byte 0001')
		return error('Code point > U+1FFFFF.')
	}

	mut utf8byte:=[]byte{}

	//为ascii字符时
	if codepoint < 0x0080 {
		utf8byte << byte(codepoint)
	//2byte utf8字符
	}else if codepoint < 0x0800{
		utf8byte << byte(((codepoint & 0x000007C0) | 0x00003000) >> 6)
		utf8byte << byte((codepoint & 0x0000003F) | 0x00000080)
	//3byte utf8字符
	}else if codepoint < 0x10000{
		utf8byte << byte(((codepoint & 0x0000F000) | 0x000E0000) >> 12)
		utf8byte << byte(((codepoint >> 6) & 0x0000003F) | 0x00000080)
		utf8byte << byte((codepoint & 0x0000003F) | 0x00000080)
	//4byte utf8字符
	}else{
		utf8byte << byte(((codepoint & 0x001C0000) | 0x03C00000) >> 18)
		utf8byte << byte(((codepoint >> 12) & 0x0000003F) | 0x00000080)
		utf8byte << byte(((codepoint >> 6) & 0x0000003F) | 0x00000080)
		utf8byte << byte((codepoint & 0x0000003F) | 0x00000080)
	}

	return utf8byte
}