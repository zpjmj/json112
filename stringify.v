module json112

import strings

struct Indentation{
mut:
	len int
	str string
	indentation_char string
}

fn(mut ind Indentation) add(){
	ind.len+=ind.indentation_char.len
	ind.str+=ind.indentation_char
}

fn(mut ind Indentation) sub(){
	ind.len-=ind.indentation_char.len

	if ind.len<=0{
		ind.str = ''
	}else{
		ind.str = ind.str[0..ind.len]
	}
}

pub fn (J Json112) stringify(skip []string,space int) string{
	mut skip_node_arr := []string{}
	for i in skip{
		mut parser := new_node_parser(i)
		skip_node_arr << parser.parse().node_index
	}

	mut s_builder := strings.new_builder(J.byte_len + 100)
	defer{
		unsafe{
			s_builder.free()
		}
	}

	//配置缩进与换行
	mut indentation_char := '          '
	if space > 0 && space <= 10{
		indentation_char = indentation_char[0..space]
	}else{
		indentation_char = ''
	}

	mut indentation := Indentation{
		len:0
		str:''
		indentation_char:indentation_char
	}

	mut line_break := ''
	mut colon_str := ':'

	if indentation_char.len > 0{
		line_break = '\n'
		colon_str = ": "
	}

	stringify_object(&J,mut s_builder,'',J.child_node,skip_node_arr,mut indentation,line_break,colon_str)

	return s_builder.str()
	//return J.formatted_str
}

fn stringify_object(j_112 &Json112,mut s_builder strings.Builder,p_node string,child_node []string,skip_node_arr []string,mut indentation Indentation,line_break string,colon_str string){
	mut not_first := false

	s_builder.write_string('{')
	indentation.add()

	for n_name in child_node{
		node_name:=p_node + '["$n_name"]'

		mut skip_flg := false
		for i in skip_node_arr{
			if node_name == i{
				skip_flg = true
				break
			}
		}
		if skip_flg{
			continue
		}

		if not_first {
			s_builder.write_string(',')
		}

		s_builder.write_string(line_break)
		s_builder.write_string(indentation.str)
		s_builder.write_string('"')
		s_builder.write_string(convert_string(n_name))
		s_builder.write_string('"$colon_str')

		json_node:= j_112.all_nodes[node_name]

		match json_node.node_typ{
			.null{
				s_builder.write_string('null')
			}
			.boolean{
				unsafe{
					s_builder.write_string(json_node.node_val.bool_val.str())
				}
			}
			.number{
				mut num_val := '' 
				unsafe{
					num_val = json_node.node_val.number_val.str()
				}
				if num_val[num_val.len-1] == `.`{
					num_val = num_val[0..num_val.len-1]
				}
				s_builder.write_string(num_val)
			}
			.string{
				unsafe{
					s_builder.write_string('"${convert_string(json_node.node_val.string_val)}"')
				}
			}
			.array{
				json_node_len:= j_112.all_nodes[node_name+'["len"]']

				unsafe{
					stringify_array(j_112,mut s_builder,node_name,int(json_node_len.node_val.number_val),skip_node_arr,mut indentation,line_break,colon_str)
				}
			}
			else{
				stringify_object(j_112,mut s_builder,node_name,json_node.child_node,skip_node_arr,mut indentation,line_break,colon_str)
			}
		}

		not_first = true
	}
	indentation.sub()
	if not_first{
		s_builder.write_string(line_break)
		s_builder.write_string(indentation.str)
	}

	s_builder.write_string('}')

}

fn stringify_array(j_112 &Json112,mut s_builder strings.Builder,p_node string,arr_len int,skip_node_arr []string,mut indentation Indentation,line_break string,colon_str string){
	mut not_first := false

	s_builder.write_string('[')
	indentation.add()

	for n_name:=0;n_name<arr_len;n_name++{
		node_name:=p_node + '[$n_name]'

		mut skip_flg := false
		for i in skip_node_arr{
			if node_name == i{
				skip_flg = true
				break
			}
		}
		if skip_flg{
			continue
		}

		if not_first {
			s_builder.write_string(',')
		}

		s_builder.write_string(line_break)
		s_builder.write_string(indentation.str)

		json_node:= j_112.all_nodes[node_name]

		match json_node.node_typ{
			.null{
				s_builder.write_string('null')
			}
			.boolean{
				unsafe{
					s_builder.write_string(json_node.node_val.bool_val.str())
				}
			}
			.number{
				mut num_val := ''
				unsafe{
					num_val = json_node.node_val.number_val.str()
				}
				if num_val[num_val.len-1] == `.`{
					num_val = num_val[0..num_val.len-1]
				}
				s_builder.write_string(num_val)
			}
			.string{
				unsafe{
					s_builder.write_string('"${convert_string(json_node.node_val.string_val)}"')
				}
			}
			.array{
				json_node_len:= j_112.all_nodes[node_name + '["len"]']
				
				unsafe{
					stringify_array(j_112,mut s_builder,node_name,int(json_node_len.node_val.number_val),skip_node_arr,mut indentation,line_break,colon_str)
				}
			}
			else{
				stringify_object(j_112,mut s_builder,node_name,json_node.child_node,skip_node_arr,mut indentation,line_break,colon_str)
			}
		}

		not_first = true
	}

	indentation.sub()
	if not_first{
		s_builder.write_string(line_break)
		s_builder.write_string(indentation.str)
	}

	s_builder.write_string(']')
}


[inline]
fn convert_string(str string)string{
	mut s_builder := strings.new_builder(str.len*2)
	defer{
		unsafe{
			s_builder.free()
		}
	}

	for i in str{
		match i{
			`"`{
				s_builder.write_runes([`\\`,`"`])
			}
			`\\`{
				s_builder.write_runes([`\\`,`\\`])
			}
			`/`{
				s_builder.write_runes([`\\`,`/`])
			}
			`\b`{
				s_builder.write_runes([`\\`,`b`])
			}
			`\f`{
				s_builder.write_runes([`\\`,`f`])
			}
			`\n`{
				s_builder.write_runes([`\\`,`n`])
			}
			`\r`{
				s_builder.write_runes([`\\`,`r`])
			}
			`\t`{
				s_builder.write_runes([`\\`,`t`])
			}
			else{
				s_builder.write_b(i)
			}
		}
	}
	return s_builder.str()
}