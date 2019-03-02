{
  addressable = {
    dependencies = ["public_suffix"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0viqszpkggqi8hq87pqp0xykhvz60g99nwmkwsb0v45kc2liwxvk";
      type = "gem";
    };
    version = "2.5.2";
  };
  colorator = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f7wvpam948cglrciyqd798gdc6z3cfijciavd0dfixgaypmvy72";
      type = "gem";
    };
    version = "1.1.0";
  };
  concurrent-ruby = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "183lszf5gx84kcpb779v6a2y0mx9sssy8dgppng1z9a505nj1qcf";
      type = "gem";
    };
    version = "1.0.5";
  };
  em-websocket = {
    dependencies = ["eventmachine" "http_parser.rb"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bsw8vjz0z267j40nhbmrvfz7dvacq4p0pagvyp17jif6mj6v7n3";
      type = "gem";
    };
    version = "0.5.1";
  };
  eventmachine = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "075hdw0fgzldgss3xaqm2dk545736khcvv1fmzbf1sgdlkyh1v8z";
      type = "gem";
    };
    version = "1.2.5";
  };
  ffi = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "034f52xf7zcqgbvwbl20jwdyjwznvqnwpbaps9nk18v9lgb1dpx0";
      type = "gem";
    };
    version = "1.9.18";
  };
  forwardable-extended = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15zcqfxfvsnprwm8agia85x64vjzr2w0xn9vxfnxzgcv8s699v0v";
      type = "gem";
    };
    version = "2.6.0";
  };
  "http_parser.rb" = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15nidriy0v5yqfjsgsra51wmknxci2n2grliz78sf9pga3n0l7gi";
      type = "gem";
    };
    version = "0.6.0";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a1r0q8gx379dzzmbdxr9mj228vfvml7187zy71rgh9cd38fqz84";
      type = "gem";
    };
    version = "0.9.3";
  };
  jekyll = {
    dependencies = ["addressable" "colorator" "em-websocket" "i18n" "jekyll-sass-converter" "jekyll-watch" "kramdown" "liquid" "mercenary" "pathutil" "rouge" "safe_yaml"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05f61rqwz1isci7by34zyz38ah2rv5b8i5h618cxcl97hwqps8n2";
      type = "gem";
    };
    version = "3.7.2";
  };
  jekyll-sass-converter = {
    dependencies = ["sass"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vwaaqpm9zn9jqkysj6gh9zv7mskx53bqgl0bjyh95sln1qk67d9";
      type = "gem";
    };
    version = "1.5.1";
  };
  jekyll-watch = {
    dependencies = ["listen"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0m7scvj3ki8bmyx5v8pzibpg6my10nycnc28lip98dskf8iakprp";
      type = "gem";
    };
    version = "2.0.0";
  };
  kramdown = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mkrqpp01rrfn3rx6wwsjizyqmafp0vgg8ja1dvbjs185r5zw3za";
      type = "gem";
    };
    version = "1.16.2";
  };
  liquid = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17fa0jgwm9a935fyvzy8bysz7j5n1vf1x2wzqkdfd5k08dbw3x2y";
      type = "gem";
    };
    version = "4.0.0";
  };
  listen = {
    dependencies = ["rb-fsevent" "rb-inotify" "ruby_dep"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01v5mrnfqm6sgm8xn2v5swxsn1wlmq7rzh2i48d4jzjsc7qvb6mx";
      type = "gem";
    };
    version = "3.1.5";
  };
  mercenary = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10la0xw82dh5mqab8bl0dk21zld63cqxb1g16fk8cb39ylc4n21a";
      type = "gem";
    };
    version = "0.3.6";
  };
  multi_json = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rl0qy4inf1mp8mybfk56dfga0mvx97zwpmq5xmiwl5r770171nv";
      type = "gem";
    };
    version = "1.13.1";
  };
  pathutil = {
    dependencies = ["forwardable-extended"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wc18ms1rzi44lpjychyw2a96jcmgxqdvy2949r4vvb5f4p0lgvz";
      type = "gem";
    };
    version = "0.16.1";
  };
  public_suffix = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mvzd9ycjw8ydb9qy3daq3kdzqs2vpqvac4dqss6ckk4rfcjc637";
      type = "gem";
    };
    version = "3.0.1";
  };
  "pygments.rb" = {
    dependencies = ["multi_json"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0lbvnwvz770ambm4d6lxgc2097rydn5rcc5d6986bnkzyxfqqjnv";
      type = "gem";
    };
    version = "1.2.1";
  };
  rb-fsevent = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fbpmjypwxkb8r7y1kmhmyp6gawa4byw0yb3jc3dn9ly4ld9lizf";
      type = "gem";
    };
    version = "0.10.2";
  };
  rb-inotify = {
    dependencies = ["ffi"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yfsgw5n7pkpyky6a9wkf1g9jafxb0ja7gz0qw0y14fd2jnzfh71";
      type = "gem";
    };
    version = "0.9.10";
  };
  redcarpet = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h9qz2hik4s9knpmbwrzb3jcp3vc5vygp9ya8lcpl7f1l9khmcd7";
      type = "gem";
    };
    version = "3.4.0";
  };
  rouge = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ibw38faway64k89kn7apw41ws773nd964bmpympjpwr1xckjrw5";
      type = "gem";
    };
    version = "3.1.0";
  };
  ruby_dep = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c1bkl97i9mkcvkn1jks346ksnvnnp84cs22gwl0vd7radybrgy5";
      type = "gem";
    };
    version = "1.5.0";
  };
  safe_yaml = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hly915584hyi9q9vgd968x2nsi5yag9jyf5kq60lwzi5scr7094";
      type = "gem";
    };
    version = "1.0.4";
  };
  sass = {
    dependencies = ["sass-listen"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10401m2xlv6vaxfwzy4xxmk51ddcnkvwi918cw3jkki0qqdl7d8v";
      type = "gem";
    };
    version = "3.5.5";
  };
  sass-listen = {
    dependencies = ["rb-fsevent" "rb-inotify"];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xw3q46cmahkgyldid5hwyiwacp590zj2vmswlll68ryvmvcp7df";
      type = "gem";
    };
    version = "4.0.0";
  };
}