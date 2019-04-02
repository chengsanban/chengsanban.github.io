---
author: "橙三瓣"
date: 2018-04-11
title: "STL解析(8):STL配接器"
tags: [
    "C++",
    "C",
    "STL",
]
categories: [
    "编程笔记",
]
---
## 一、配接器概念
配接器又称适配器，既是STL组件之一，又是一种设计模式，设计模式中给出的概念就是：把一个类的接口转换为另一个接口，使原本不能相互协调工作的类工作。  
STL中改变容器接口的就叫容器适配器，改变迭代器接口的称之为迭代器适配器。
## 二、配接器的应用
### 容器配接器
  就像先前在讲容器概念的时候讲到的，stack和queue为什么是适配器，因为他只是简单改变了底层容器deque的接口而已。
### 迭代器配接器
  像下面这种情况，原本的接口函数非常复杂back_insert_iterator<_Container>(__x)，也不宜用户理解，稍加封装把接口变为back_inserter(_Container& __x) ，就看起来简单不少，虽然只是改了个名称。  
```C++
inline back_insert_iterator<_Container>  
back_inserter(_Container& __x) 
{ return back_insert_iterator<_Container>(__x); }
```
然而你可以自己设计自己的适配器，让适配器根据你的意愿工作，例如你本来，是有一个输出迭代器，他的功能是输出到文本，你适当调整接口就可以让他输出到屏幕。
### 仿函数配接器
仿函数配接器可能是最有用的配接器类型，使用它组合各种方法和仿函数，配接之后再配接。  
**举个栗子**：  
我有10个数，一个求最大值和一个求最小值仿函数，现在我要实现的功能是找出里面最大的数字和最小的数字相减。  
//求最大值仿函数
```C++
template<class T>
class Big{ ........} 
//求最小值仿函数
template<class T>
class Small{ ........} 
//仿函数的仿函数 
tempalte<class T1,class T2>
class BigSubSmall<Big,Small>
{
     //调用两个仿函数返回值做差
} 

//配接器
int BSS(int *a)
{ 
    //调用BigSubSmall仿函数计算传回结果
}
```  
> 图文来自博主原来博客chengvincent.com

