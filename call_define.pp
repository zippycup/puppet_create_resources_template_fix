define hiera_util::call_define ( $conf, $call_define_key = 'call_define' ) {

  $define_hash=$conf[$call_define_key][$name]

  if $name == 'file' {
    $define_hash.each | $key, $value | {
      if has_key($value,'content') and $value['content'] =~ /^template/ {
        if $value['content'] =~ "'" {
           $template_entry = split($value['content'], "'")
        }
        if $value['content'] =~ '"' {
           $template_entry = split($value['content'], '"')
        }
        File <| title == $key |> { content => template($template_entry[1]) }
      }
    }
  } 

  if is_hash($define_hash) {
    create_resources($name, $define_hash)
  }
}

