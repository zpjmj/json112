module json112

struct NodeScanner{
	//node原始字符
	text string [required]
mut:
	//当前扫描位置
	pos int
	//已缓存的所有token
	all_tokens []NodeToken
	//all_tokens Array的索引
	tidx int
	//获取unicode码点
	get_unicodepoint fn(string,int)?Unicode
}

//扫描器构造方法
//text:json字符串
//encodeing:编码 目前只支持utf8
fn new_node_scanner(text string,encodeing string) &NodeScanner{
	mut scanner := &NodeScanner{
		text:text
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
	scanner.init_scanner()
	return scanner
}

//初始化扫描器 缓存所有token
fn (mut s NodeScanner) init_scanner() {
	for{
		tok := s.text_scan()
		s.all_tokens << tok

		if tok.kind == .eof{
			break
		}
	}
}

//从缓存中依次获取token
fn (mut s NodeScanner) scan() NodeToken{

	tok := s.all_tokens[s.tidx]
	s.tidx++

	if tok.kind == .eof{
		s.tidx--
	}

	return tok
}

fn (mut s NodeScanner) text_scan() NodeToken{
	mut start:=0
	for{
		//跳过空白字符
		s.skip_ws()

		//扫描到最后一个字符之后
		if s.pos >= s.text.len{
			break
		}
		c := s.text[s.pos]

		if is_name(c) {
			start = s.pos
			name  := s.decl_name()
			return s.new_token(.name,start,s.pos - start,name)
		}

		match c {
			`[` {
				start = s.pos
				s.pos++
				mut is_start := true

				for s.pos < s.text.len {
					next_c := s.text[s.pos]
					match next_c{
						`"`{
							if is_start {
								len_,converted_utf8_byte := string_scan(mut &s) or {
									s.pos--
									is_start = false
									break
								}
								mut str := ''
								unsafe{
									if converted_utf8_byte.len > 0{
										str = tos(converted_utf8_byte.data,converted_utf8_byte.len)
									}else{
										str = ''
									}
								}
								s.pos++
								return s.new_token(.string,start,len_,str)
							}
						}
						`0`,`1`,`2`,`3`,`4`,`5`,`6`,`7`,`8`,`9`{
							if is_start {
								mut index_flg := false
								s.pos++
								for s.pos < s.text.len {
									next_next_c := s.text[s.pos]
									if next_next_c.is_digit() {
										s.pos++
										continue
									}else{
										if next_next_c == `]` {
											index_flg = true
											break
										}else{
											is_start = false
											break
										}
									}
								}

								if index_flg {
									index := (s.text[start+1..s.pos]).int().str()
									s.pos++
									return s.new_token(.index,start,s.pos - start,"[$index]")
								}
							}
						}
						`]`{
							break
						}
						else{
							is_start = false
						}
					}
					s.pos++
				}

				unknown_str := s.text[start..s.pos]
				return s.new_token(.unknown,start,s.pos - start,unknown_str)
			}
			`.`{
				start = s.pos
				s.pos++
				return s.new_token(.dot,start,s.pos - start,'.')
			}
			else {
				start = s.pos
				unknown_str := s.decl_unknown()
				return s.new_token(.unknown,start,s.pos - start,unknown_str)
			}
		}
	}

	return s.new_token(.eof,s.pos,0,'')
}

[inline]
pub fn is_name(c byte) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`
}

[inline]
fn (mut s NodeScanner) decl_name() string {
	start := s.pos
	s.pos++
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if !(is_name(c) || c.is_digit()) {
			break
		}
		s.pos++
	}
	name := s.text[start..s.pos]
	return name
}

[inline]
fn (mut s NodeScanner) decl_unknown() string {
	start := s.pos
	s.pos++
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if is_name(c) || c == `[` || c == `.` {
			break
		}
		s.pos++
	}
	name := s.text[start..s.pos]
	return name
}

//创建Token
//kind:Token种类
//pos:Token在json字符串的开始位置
//len:Token字符占json字符串的长度
//val:扫描器转换后TokenVal的值
fn (mut s NodeScanner) new_token(kind NodeKind,pos int,len int,val string) NodeToken{
	return NodeToken{
		kind:kind
		pos:pos
		len:len
		val:val
	}
}

//跳过空白字符
fn (mut s NodeScanner) skip_ws() {
	for{
		if s.pos >= s.text.len{
			break
		}
		
		c := s.text[s.pos]
		if c != ` `{
			break
		}
		s.pos++
	}
}