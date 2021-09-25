module json112

const (
	ws=[` `,`\t`,`\n`,`\r`]
	structural_char=[`{`,`}`,`[`,`]`,`:`,`,`]
)

struct Scanner{
	//json原始字符
	text string [required]
	//是否扫描注释
	scan_comment bool [required]
mut:
	//当前扫描位置
	pos int
	//已缓存的所有token
	all_tokens []Token
	//all_tokens Array的索引
	tidx int
	//获取unicode码点
	get_unicodepoint fn(string,int)?Unicode
}	

fn new_scanner(text string,scan_comment bool,encodeing string)? &Scanner{
	mut scanner := &Scanner{
		text:text
		scan_comment:scan_comment
	}

	match encodeing{
		'utf8'{
			scanner.get_unicodepoint = utf8str_to_unicodepoint
		}
		'utf16'{
			scanner.get_unicodepoint = utf16str_to_unicodepoint
		}
		else{
			scanner.get_unicodepoint = utf8str_to_unicodepoint
		}
	}


	//初始化
	scanner.init_scanner()?
	return scanner
}

//初始化扫描器 缓存所有token
fn (mut s Scanner) init_scanner()? {
	for{
		tok := s.text_scan()?
		s.all_tokens << tok

		if tok.kind == .eof{
			break
		}
	}
	log(s.all_tokens)
}

//获取token
fn (mut s Scanner) scan() Token{

	tok := s.all_tokens[s.tidx]
	s.tidx++

	if tok.kind == .eof{
		s.tidx--
	}

	return tok
}

fn (mut s Scanner) text_scan()? Token{
	mut start := 0
	mut len := 0
	mut str := ""

	for{
		s.skip_ws()

		if s.pos >= s.text.len{
			break
		}
		c := s.text[s.pos]

		if (c >= `0` && c <= `9`) || c == `-`{
			start = s.pos
			len = s.continue_scan()
			str = s.text[start..start + len]

			mut minus := []byte{}
			mut minus_flag := true

			mut int_ := []byte{}
			mut int_flag := false

			mut frac := []byte{}
			mut frac_flag := false 

			mut	exp_sign := []byte{}
			mut exp_sign_flag := false
			mut exp := []byte{}
			mut exp_flag := false

			mut error_flg := false

			for i,b in str{
				if minus_flag {
					if b >= `0` && b <= `9` {
						minus_flag = false
						int_flag = true
						int_ << b
						continue
					}
					if i==0 && b == `-`{
						minus << b
					}else{
						error_flg = true
					}
					continue
				}
				if int_flag {
					if b == `.`{
						int_flag = false
						frac_flag = true
						continue
					}

					if b == `e` || b == `E`{
						int_flag = false
						exp_sign_flag = true
						continue
					}
					
					if int_[0] != `0` && b >= `0` && b <= `9`{
						int_ << b
					} else {
						error_flg = true
					}
					continue
				}
				if frac_flag {
					if b == `e` || b == `E`{
						int_flag = false
						exp_sign_flag = true
						continue
					}

					if b >= `0` && b <= `9`{
						frac << b
					} else {
						error_flg = true
					}
				}
				if exp_sign_flag {
					if b == `-` || b == `+`{
						exp_sign << b
					}
					exp_sign_flag = false
					exp_flag = true
					continue
				}
				if exp_flag {
					if b >= `0` && b <= `9`{
						exp << b
					} else {
						error_flg = true
					}
					continue
				}
			}

			if error_flg {
				return s.new_token(.unknown,start,len,0)
			}

			return s.new_token(.number,start,len,0)
		}

		match c {
			`"` {
				start = s.pos
				len_,converted_utf8_byte := s.string_scan()?
				
				return s.new_token(.string,start,len_,converted_utf8_byte)
			}
			`:` {
				start = s.pos
				s.pos++
				return s.new_token(.colon,start,1,0)
			}
			`,` {
				start = s.pos
				s.pos++
				return s.new_token(.comma,start,1,0)
			}
			`{` {
				start = s.pos
				s.pos++
				return s.new_token(.begin_objec,start,1,0)
			}
			`}` {
				start = s.pos
				s.pos++
				return s.new_token(.end_object,start,1,0)
			}
			`[` {
				start = s.pos
				s.pos++
				return s.new_token(.begin_array,start,1,0)
			}
			`]` {
				start = s.pos
				s.pos++
				return s.new_token(.end_array,start,1,0)
			}
			`n`{
				start = s.pos
				len = s.continue_scan()
				str = s.text[start..start + len]

				if str == 'null' {
					return s.new_token(.null,start,len,0)		
				}else{
					return s.new_token(.unknown,start,len,0)	
				}
			}
			`t`,`f` {
				start = s.pos
				len = s.continue_scan()
				str = s.text[start..start + len]

				if str == 'true'{
					return s.new_token(.boolean,start,len,true)	
				}else if str == 'false'{
					return s.new_token(.boolean,start,len,false)	
				}else{
					return s.new_token(.unknown,start,len,0)	
				}
			}
			else {
				start = s.pos
				len = s.continue_scan()
				return s.new_token(.unknown,start,len,0)
			}
		}
	}

	return s.new_token(.eof,s.pos,0,0)
}

fn (mut s Scanner) new_token<T>(kind Kind,pos int,len int,val T) Token{
	mut converted_value := ConvertedValue{}

	$if T is []byte{
		converted_value.str_val = val
	}$else $if T is bool{
		converted_value.bool_val = val
	}$else $if T is i64{
		converted_value.i64_val = val		
	}$else $if T is f64{
		converted_value.f64_val = val		
	}$else $if T is int{
		converted_value.unknown_val = val	
	}$else{
		converted_value.null_val = val
	}

	return Token{
		kind:kind
		pos:pos
		len:len
		typ:'zzz'
		val:converted_value
	}
}

fn (mut s Scanner) skip_ws() {
	for{
		if s.pos >= s.text.len{
			break
		}

		c := s.text[s.pos]
		if c !in ws{
			break
		}
		s.pos++
	}
}

fn (mut s Scanner) continue_scan() int{
	start_pos := s.pos
	mut last_pos := s.pos
	for{
		s.skip_ws()

		c := s.text[s.pos]
		if c in structural_char{
			break
		}

		if last_pos != s.pos {
			break
		}
		if s.pos >= s.text.len{
			break
		}
		s.pos++
		last_pos = s.pos
	}
	return last_pos - start_pos
}

fn (mut s Scanner) string_scan()? (int,[]byte){
	mut escape_flag := false
	start_pos := s.pos
	s.pos++
	
	mut converted_byte := []byte{}
	converted_byte << `"`

	for{
		if s.pos >= s.text.len{
			return error('Expect a quote to close the string.')
		}

		c := s.text[s.pos]

		if !escape_flag && c == `\\` {
			escape_flag = true
			s.pos++
			continue
		}

		if escape_flag {
			match c{
				`"`{
					converted_byte << `"`
				}
				`\\`{
					converted_byte << `\\`
				}
				`/`{
					converted_byte << `/`
				}
				`b`{
					converted_byte << `\b`
				}
				`f`{
					converted_byte << `\f`
				}
				`n`{
					converted_byte << `\n`
				}
				`r`{
					converted_byte << `\r`
				}
				`t`{
					converted_byte << `\t`
				}
				`u`{
					if (s.pos + 5) >= s.text.len {
						return error('Expect the character \\uXXXX.')
					}

					utf16_str:=s.text[s.pos+1..s.pos+5]
					for i in utf16_str{
						if !i.is_hex_digit(){
							error('The hex character is expected after the \\u character.')
						}
					}
					s.pos+=5

					mut utf16_codepoint:=('0x' + utf16_str).u32()

					if utf16_codepoint < 0xD800 && utf16_codepoint > 0xDFFF {
						utf8byte := unicodepoint_encode_to_utf8byte(utf16_codepoint)?
						for i in utf8byte{
							converted_byte << i
						}
						s.pos--
					}else if utf16_codepoint > 0xD7FF && utf16_codepoint < 0xDC00{
						if (s.pos + 6) >= s.text.len {
							return error('Expect the character \\uXXXX\\uXXXX.')
						}
						next2_char:=s.text[s.pos..s.pos+2]
						
						if next2_char != '\\u'{
							return error('Expect the character \\uXXXX\\uXXXX.')
						}

						utf16_str_trail:=s.text[s.pos+2..s.pos+6]
						for i in utf16_str_trail{
							if !i.is_hex_digit(){
								error('The hex character is expected after the \\u character.')
							}
						}
						utf16_codepoint_trail:=('0x' + utf16_str_trail).u32()

						if utf16_codepoint_trail < 0xDC00 || utf16_codepoint_trail > 0xDFFF {
							error('The trail surrogates code point needs to be in the 0xDC00...0xDFFF range.')
						}

						utf16_codepoint = ((utf16_codepoint - 0xD800) >> 5) | (utf16_codepoint_trail - 0xDC00)
						utf8byte := unicodepoint_encode_to_utf8byte(utf16_codepoint)?
						for i in utf8byte{
							converted_byte << i
						}
						s.pos+=5

					}else{
						error('Needs lead surrogates before trail surrogates.')
					}
				}
				else{
					error('The character \\${s.text[s.pos..s.pos+1]} could not be escaped.')		
				}
			}
			s.pos++
		} else {
			if c == `"`{
				converted_byte << c
				s.pos++
				break
			}

			u := s.get_unicodepoint(s.text,s.pos)?

			if u.code_point < 0x20 ||
			   (u.code_point > 0x21 && u.code_point < 0x23) || 
			   (u.code_point > 0x5B && u.code_point < 0x5D) ||
			   u.code_point > 0x10FFFF {
				   return error('Invalid code point value: ${u.code_point}.')
			}

			s.pos += u.pos_offset
			for i:=0;i<u.size;i++ {
				converted_byte << s.text[s.pos]
				s.pos++
			}
		}

		s.pos++
	}
	return s.pos - start_pos,converted_byte
}
