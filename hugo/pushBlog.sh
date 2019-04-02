#!/bin/bash

cd ./hugo/blog
echo "进入blog目录....."
rm -rf public/*
echo "删除public目录文件....."
hugo
echo "生成新文件....."
cd ../../chengsanban.github.io
echo "进入git博客目录....."
rm -rf ./*
echo "删除git博客内容....."
cp -r ../hugo/blog/public/* .
echo "拷贝public内容到当前目录....."
cp -r ../hugo/blog/content ./
echo "拷贝原始文章....."
cp -r ../image ./
echo "拷贝原始图片....."
echo "开始提交....."
git add .
git commit -am "new article"
git push origin master
