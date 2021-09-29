module json112
import math

const (
	ws=[` `,`\t`,`\n`,`\r`]  //空白字符
	structural_char=[`{`,`}`,`[`,`]`,`:`,`,`] //json结构字符
)

interface StringScanner{
	//json原始字符
	text string
mut:
	//当前扫描位置
	pos int
	//获取unicode码点
	get_unicodepoint fn(string,int)?Unicode
}

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

//扫描器构造方法
//text:json字符串
//scan_comment:是否扫描注释 目前未实现
//encodeing:编码 目前只支持utf8
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
}

//从缓存中依次获取token
fn (mut s Scanner) scan() Token{

	tok := s.all_tokens[s.tidx]
	s.tidx++

	if tok.kind == .eof{
		s.tidx--
	}

	return tok
}

//扫描json字符生成token
fn (mut s Scanner) text_scan()? Token{
	mut start := 0
	mut len := 0
	mut str := ""

	for{
		//跳过空白字符
		s.skip_ws()

		//扫描到最后一个字符之后
		if s.pos >= s.text.len{
			break
		}
		c := s.text[s.pos]

		//扫描数字
		if (c >= `0` && c <= `9`) || c == `-`{
			start = s.pos
			len = s.continue_scan()
			str = s.text[start..start + len]

			//符号位 '-' or '+'
			mut minus := []byte{}
			mut minus_flag := true

			//整数
			mut int_ := []byte{}
			mut int_flag := false

			//小数
			mut frac := []byte{}
			mut frac_flag := false 

			//科学计数法符号位 '-' or '+'
			mut	exp_sign := []byte{}
			mut exp_sign_flag := false
			//科学计数法数值
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
						frac << b
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
						frac_flag = false
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
						exp_sign_flag = false
						exp_flag = true
						continue
					} else {
						exp_sign_flag = false
						exp_flag = true
					}
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

			// log('Number sacn:')
			// log(minus)
			// log(int_)
			// log(frac)
			// log(exp_sign)
			// log(exp)
			// log(error_flg)

			if error_flg {
				return s.new_token(.unknown,start,len,.undefined,0)
			}

			if int_.len < 1 || (frac.len > 0 && frac.len < 2) || (exp_flag && exp.len == 0){
				return s.new_token(.unknown,start,len,.undefined,0)
			}

			mut number_str :=''
	
			unsafe{
				if minus.len > 0{
					number_str = tos(minus.data,minus.len) + tos(int_.data,int_.len)
				}else{
					number_str = tos(int_.data,int_.len)
				}
			}
			
			if frac.len > 0 {
				unsafe{
					number_str = number_str + tos(frac.data,frac.len)
				}
			}
			mut number_val := number_str.f64()

			if exp_flag {
				unsafe{
					if exp_sign.len == 0{
						number_val = number_val * math.pow(10,tos(exp.data,exp.len).i64())
					}else{
						number_val = number_val * math.pow(10,(tos(exp_sign.data,exp_sign.len) + tos(exp.data,exp.len)).i64())
					}
				}
			}

			return s.new_token(.number,start,len,.number,number_val)
		}

		match c {
			`"` {
				start = s.pos
				//扫描字符串
				//len_,converted_utf8_byte := s.string_scan()?
				len_,converted_utf8_byte := string_scan(mut &s)?
				
				return s.new_token(.string,start,len_,.string,converted_utf8_byte)
			}
			`:` {
				start = s.pos
				s.pos++
				return s.new_token(.colon,start,1,.undefined,0)
			}
			`,` {
				start = s.pos
				s.pos++
				return s.new_token(.comma,start,1,.undefined,0)
			}
			`{` {
				start = s.pos
				s.pos++
				return s.new_token(.begin_object,start,1,.undefined,0)
			}
			`}` {
				start = s.pos
				s.pos++
				return s.new_token(.end_object,start,1,.undefined,0)
			}
			`[` {
				start = s.pos
				s.pos++
				return s.new_token(.begin_array,start,1,.undefined,0)
			}
			`]` {
				start = s.pos
				s.pos++
				return s.new_token(.end_array,start,1,.undefined,0)
			}
			`n`{
				start = s.pos
				len = s.continue_scan()
				str = s.text[start..start + len]

				if str == 'null' {
					return s.new_token(.null,start,len,.null,Null{})		
				}else{
					return s.new_token(.unknown,start,len,.undefined,0)	
				}
			}
			`t`,`f` {
				start = s.pos
				len = s.continue_scan()
				str = s.text[start..start + len]

				if str == 'true'{
					return s.new_token(.boolean,start,len,.bool,true)	
				}else if str == 'false'{
					return s.new_token(.boolean,start,len,.bool,false)	
				}else{
					return s.new_token(.unknown,start,len,.undefined,0)	
				}
			}
			else {
				start = s.pos
				len = s.continue_scan()
				return s.new_token(.unknown,start,len,.undefined,0)
			}
		}
	}

	return s.new_token(.eof,s.pos,0,.undefined,0)
}

//创建Token
//kind:Token种类
//pos:Token在json字符串的开始位置
//len:Token字符占json字符串的长度
//typ:扫描器转换后TokenVal的类型
//val:扫描器转换后TokenVal的值
fn (mut s Scanner) new_token<T>(kind Kind,pos int,len int,typ TokenValType,val T) Token{
	mut converted_value := ConvertedValue{}

	$if T is []byte{
		unsafe{
			if val.len > 0 {
				converted_value.string_val = tos(val.data,val.len)
			}else{
				converted_value.string_val = ''
			}
		}
	}$else $if T is bool{
		converted_value.bool_val = val
	}$else $if T is f64{
		converted_value.number_val = val		
	}$else{
		converted_value.skip = 0
	}

	return Token{
		kind:kind
		pos:pos
		len:len
		typ:typ
		val:converted_value
	}
}

//跳过空白字符
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

//扫描到关键字后继续扫描到结构字符
fn (mut s Scanner) continue_scan() int{
	start_pos := s.pos
	mut last_pos := s.pos
	for{
		if s.pos >= s.text.len{
			break
		}

		s.skip_ws()

		c := s.text[s.pos]
		if c in structural_char{
			break
		}

		if last_pos != s.pos {
			break
		}

		s.pos++
		last_pos = s.pos
	}
	return last_pos - start_pos
}

//扫描字符串
[inline]
fn string_scan(mut s &StringScanner)? (int,[]byte){
	mut escape_flag := false
	start_pos := s.pos
	s.pos++
	
	mut converted_byte := []byte{}
	for{
		if s.pos >= s.text.len{
			log('string_scan 0001')
			return error('Expect a quote to close the string.')
		}

		c := s.text[s.pos]

		//第一次扫描的转义字符
		if !escape_flag && c == `\\` {
			escape_flag = true
			s.pos++
			continue
		}

		//转义字符的下一个字符
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
					//变换utf16转义字符串到utf8字符
					if (s.pos + 4) >= s.text.len {
						log('string_scan 0002')
						return error('Expect the character \\uXXXX.')
					}

					utf16_str:=s.text[s.pos+1..s.pos+5]

					for i in utf16_str{
						if !i.is_hex_digit(){
							log('string_scan 0003')
							return error('The hex character is expected after the \\u character.')
						}
					}
					s.pos+=5

					mut utf16_codepoint:=('0x' + utf16_str).u32()
					//基本多语言平面码点
					if utf16_codepoint < 0xD800 || utf16_codepoint > 0xDFFF {
						utf8byte := unicodepoint_encode_to_utf8byte(utf16_codepoint)?
						for i in utf8byte{
							converted_byte << i
						}
						s.pos--
					//辅助平面码点
					}else if utf16_codepoint > 0xD7FF && utf16_codepoint < 0xDC00{
						if (s.pos + 6) >= s.text.len {
							log('string_scan 0004')
							return error('Expect the character \\uXXXX\\uXXXX.')
						}
						next2_char:=s.text[s.pos..s.pos+2]
						
						if next2_char != '\\u'{
							log('string_scan 0005')
							return error('Expect the character \\uXXXX\\uXXXX.')
						}

						utf16_str_trail:=s.text[s.pos+2..s.pos+6]

						for i in utf16_str_trail{
							if !i.is_hex_digit(){
								log('string_scan 0006')
								return error('The hex character is expected after the \\u character.')
							}
						}
						utf16_codepoint_trail:=('0x' + utf16_str_trail).u32()

						if utf16_codepoint_trail < 0xDC00 || utf16_codepoint_trail > 0xDFFF {
							log('string_scan 0007')
							return error('The trail surrogates code point needs to be in the 0xDC00...0xDFFF range.')
						}

						utf16_codepoint = ((utf16_codepoint - 0xD800) << 10) | (utf16_codepoint_trail - 0xDC00) + 0x10000
						utf8byte := unicodepoint_encode_to_utf8byte(utf16_codepoint)?
						for i in utf8byte{
							converted_byte << i
						}
						s.pos+=5

					}else{
						log('string_scan 0008')
						return error('Needs lead surrogates before trail surrogates.')
					}
				}
				else{
					log('string_scan 0009')
					return error('The character \\${s.text[s.pos..s.pos+1]} could not be escaped.')		
				}
			}
			escape_flag = false
			s.pos++
		//不需要转义的字符
		} else {
			//扫描用于闭合字符串的双引号
			if c == `"`{
				s.pos++
				break
			}

			//获取码点值 校验码点值是否在合理区间内
			u := s.get_unicodepoint(s.text,s.pos)?
			if u.code_point < 0x20 ||
			   (u.code_point > 0x21 && u.code_point < 0x23) || 
			   (u.code_point > 0x5B && u.code_point < 0x5D) ||
			   u.code_point > 0x10FFFF {
				   log('string_scan 0010')
				   return error('Invalid code point value: ${u.code_point}.')
			}

			s.pos += u.pos_offset
			for i:=0;i<u.size;i++ {
				converted_byte << s.text[s.pos]
				s.pos++
			}
		}
	}
	return s.pos - start_pos,converted_byte
}
