#!/bin/bash
echo on
echo "进入静态页面目录....."
cd /Users/chengsanban/github/chengsanban.github.io
echo "删除静态网站文件"
rm 404.html
rm -rf dist
rm index.html
rm -rf post
rm -rf tags
rm -rf about
rm favicon.ico
rm index.xml
rm robots.txt
rm -rf categories
rm -rf lib
rm sitemap.xml
rm -rf content
rm -rf page
rm sitemap.xsl
echo "进入hugo网站目录"
cd hugofile/blog
echo "删除public目录文件....."
rm -rf public/*
echo "生成新网站静态文件....."
hugo
echo "进入git博客目录....."
cd ../..
echo "拷贝public内容到当前目录....."
cp -r hugofile/blog/public/* .
echo "删除生成的原始文件"
rm -rf hugofile/blog/public/*
echo "开始提交....."
git add .
git commit -am "new article"
git push origin master
