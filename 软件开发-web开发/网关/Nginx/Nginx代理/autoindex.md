Nginx autoindex

```nginx
location ^~ / {
    root /path-to-website/public;
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;
    # 解决中文显示乱码问题
    charset utf_8;
}

```

美化样式

- <https://github.com/Naereen/Nginx-Fancyindex-Theme>
- <https://github.com/aperezdc/ngx-fancyindex>

```
fancyindex on;
fancyindex_localtime on;
fancyindex_exact_size off;
fancyindex_header "/Nginx-Fancyindex-Theme-light/header.html";
fancyindex_footer "/Nginx-Fancyindex-Theme-light/footer.html";
fancyindex_ignore "examplefile.html"; # Ignored files will not show up in the directory listing, but will still be public. 
fancyindex_ignore "Nginx-Fancyindex-Theme-light"; # Making sure folder where files are don't show up in the listing. 
# Warning: if you use an old version of ngx-fancyindex, comment the last line if you
# encounter a bug. See https://github.com/Naereen/Nginx-Fancyindex-Theme/issues/10
fancyindex_name_length 255; # Maximum file name length in bytes, change as you like.
```

编译：

```
wget https://github.com/aperezdc/ngx-fancyindex/releases/download/v0.5.2/ngx-fancyindex-0.5.2.tar.xz
```

