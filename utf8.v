module json112

fn utf8str_to_unicodepoint(str string,pos int)?Unicode{
	
	if str.len == 0 {
		return error('Input string length = 0.')
	}

	if pos >= str.len || pos < 0{
		return error('Position < string.len.')
	}

	first_bit := byte(str[pos] >> 7)
	first_second_bit := byte(str[pos] >> 6)

	if first_bit == 0b0 {
		return Unicode{
			code_point:u32(str[pos])
			pos_offset:0
			size:1
		}
	}

	if first_second_bit == 0b10{
		for i:=pos-1;i>=0;i--{
			c:=byte(str[i] >> 6)
			if c == 0b11{
				u:=utf8str_to_unicodepoint(str,i)?
				return Unicode{
					code_point:u.code_point
					pos_offset:i-pos
					size:u.size
				}
			} 
		}
		return error('Not found first byte.')
	}

	bit_123 := byte(str[pos] >> 5)
	bit_1234 := byte(str[pos] >> 4)
	bit_12345 := byte(str[pos] >> 3)

	mut unicode:=Unicode{
		code_point:0
		pos_offset:0
	}
	if bit_123 == 0b00000110{
		if str.len - pos < 2{
			return error('This code point requires at least 2 bytes.')
		}	
		unicode.size = 2
		unicode.code_point |= u32(str[pos] << 3) << 3
		unicode.code_point |= u32(str[pos+1] << 2) >> 2
	}else if bit_1234 == 0b00001110{
		if str.len - pos < 3{
			return error('This code point requires at least 3 bytes.')
		}
		unicode.size = 3
		unicode.code_point |= u32(str[pos] << 4) << 8
		unicode.code_point |= u32(str[pos+1] << 2) << 4
		unicode.code_point |= u32(str[pos+2] << 2) >> 2
	}else if bit_12345 == 0b00011110{
		if str.len - pos < 4{
			return error('This code point requires at least 4 bytes.')
		}
		unicode.size = 4
		unicode.code_point |= u32(str[pos] << 5) << 13
		unicode.code_point |= u32(str[pos+1] << 2) << 10
		unicode.code_point |= u32(str[pos+2] << 2) << 4
		unicode.code_point |= u32(str[pos+3] << 2) >> 2
	}else{
		return error('Code point > U+1FFFFF.')
	}

	return unicode
}

[inline]
fn unicodepoint_encode_to_utf8byte(codepoint u32)?[]byte{
	if codepoint > 0x1FFFFF{
		return error('Code point > U+1FFFFF.')
	}

	mut utf8byte:=[]byte{}

	if codepoint < 0x0080 {
		utf8byte << byte(codepoint)
	}else if codepoint < 0x0800{
		utf8byte << byte(((codepoint & 0x000007C0) | 0x00003000) >> 6)
		utf8byte << byte((codepoint & 0x0000003F) | 0x00000080)
	}else if codepoint < 0x10000{
		utf8byte << byte(((codepoint & 0x0000F000) | 0x000E0000) >> 12)
		utf8byte << byte(((codepoint >> 6) & 0x0000003F) | 0x00000080)
		utf8byte << byte((codepoint & 0x0000003F) | 0x00000080)
	}else{
		utf8byte << byte(((codepoint & 0x001C0000) | 0x03C00000) >> 18)
		utf8byte << byte(((codepoint >> 12) & 0x0000003F) | 0x00000080)
		utf8byte << byte(((codepoint >> 6) & 0x0000003F) | 0x00000080)
		utf8byte << byte((codepoint & 0x0000003F) | 0x00000080)
	}

	return utf8byte
}