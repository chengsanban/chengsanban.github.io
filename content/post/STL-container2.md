---
author: "橙三瓣"
date: 2018-04-08
title: "STL解析(5):STL关联式容器"
tags: [
    "C++",
    "C",
    "STL",
]
categories: [
    "编程笔记",
]
---
## 一、简说  
![容器总览](https://chengsanban.github.io/image/STL-container/STL-allContainer.png)  
看到上面这幅图片、关联式容器有两大类，一类的底层使用红黑树、另一类是哈希桶、有什么区别，看图：
![关联式容器区别](https://chengsanban.github.io/image/STL-container/STL-linkContainer.png)  
## 二、底层容器介绍  
既然都看到底层结构，就直接讲讲底层结构的实现，然后再提一下各种容器的用法即可：
### 红黑树
这里我来偷个懒，你们就到我的这篇文章上看看^-^  点这儿^-^
### 哈希桶
继续偷懒，你们就到我的这篇文章上看看^-^  点这儿^-^
## 三、容器的使用
map:  
![map函数](https://chengsanban.github.io/image/STL-container/STL-mapFunction.png)  

set:  
![set函数](https://chengsanban.github.io/image/STL-container/STL-setFunction.png)    

其他类别mapXX和setXX的使用是一样的，但是在这里还是要解释一下这个value_comp函数，因为他是返回函数指针的，用法如下  
```C++
#include<iostream>
#include<set>
using namespace std;
int main()
{ 
    set<int> s1; 
    s1.insert(1); 
    s1.insert(45); 
    s1.insert(9); 
    s1.insert(11); 
    set<int>::value_compare myComp; 
    myComp = s1.value_comp(); 
    set<int>::iterator iter1 = s1.find(45); 
    set<int>::iterator iter2 = s1.find(9); 
    cout << myComp(*iter1, *iter2)<<endl; 
    return 0;
}
```  
> 图文来自博主原来博客chengvincent.com

