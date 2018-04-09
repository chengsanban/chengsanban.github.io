---
author: "橙三瓣"
date: 2018-04-07
title: "STL解析(7):STL仿函数"
tags: [
    "C++",
    "C",
    "STL",
]
categories: [
    "编程笔记",
]
---
## 一、仿函数概念
仿函数又称函数对象，虽然是类，但是在调用的时候，却可以像函数一样的被调用，作用在哪里？这个东西，在STL算法之中仿函数可以像模板参数一样被传递，STL算法有一部分由两种实现方式，一种是自定义方式，例如sort可以按照大小排序，另一种实现方式留给用户，用户可以定义自己的仿函数，传入算法模板参数。  
问题来了，定义个函数直接传入函数指针就行，何必呢！函数指针的方式一个是不符合抽象，另一个就是融入不了STL家族，打破STL作风。。。。
## 二、融入STL
要像一个STL组件，就要相应的型别（迭代器一文查看概念），不然当某个组件使用仿函数就会使用出错，每次写的话，不得好麻烦，好在STL提供了两类来提供继承，分别是一元仿函数，和二元仿函数，先说说一元仿函数，先看定义：
```c++
template <class _Arg, class _Result>
struct unary_function 
{ 
    typedef _Arg argument_type; 
    typedef _Result result_type;
};
```
一看就看的出来，一元就指的是一个参数一个结果，下来再看看二元的：
```c++
template <class _Arg1, class _Arg2, class _Result>
struct binary_function 
{ 
    typedef _Arg1 first_argument_type; 
    typedef _Arg2 second_argument_type; 
    typedef _Result result_type;
};
```
一看就是针对于两个参数的操作符，使用时像下面这样正常继承就可：
```c++
template <class _Tp>
struct plus : public binary_function<_Tp,_Tp,_Tp> 
{ 
    _Tp operator()(const _Tp& __x, const _Tp& __y) const 
    { return __x + __y; }
};
```
## 三、仿函数的使用
下面代码实现两个仿函数，一个是找出较大数，一个是找较小数，并且有两种操作方式:
```c++
#include<iostream>
using namespace std;

template<class T>
struct Big
{ 
    T operator()(const T& t1,const T& t2) 
    { if (t1 > t2) return t1; return t2; }
};

template<class T>
struct Small
{ 
    T operator()(const T& t1, const T& t2)const { if (t1 < t2) return t1; 
    return t2; }
};

int main()
{ 
    //使用类名加括号构建匿名对象 
    cout << Big<int>()(1,2)<< endl; 
    cout << Small<int>()(1,2) << endl; 
    //直接构造对象 Big<int> b1; 
    Small<int> s1; 
    cout << s1(1, 2) << endl; 
    cout << b1(1, 2) << endl; 
    return 0;
}
```
but,都说了主要是个STL算法用的，所以至该举个例子
```c++
sort(iv.begain(), iv.end,greater<int>);
```
这一段就是给排序算法传入了一个两个值之间找到达的比较仿函数。诺，这就是仿函数了。。。。，收工回家。  
> 图文来自博主原来博客chengvincent.com
