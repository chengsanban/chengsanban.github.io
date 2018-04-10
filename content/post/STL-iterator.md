---
author: "橙三瓣"
date: 2018-04-06
title: "STL解析(3):迭代器和类型萃取技术"
tags: [
    "C++",
    "C",
    "STL",
]
categories: [
    "编程笔记",
]
---
## 一、迭代器简介
迭代器的实现意义就是让外界不知道容器的具体实现的情况之下，还能遍历容器，做到最好的封装。在算法和容器之间，迭代器扮演者桥梁的角色，算法不需要知道容器的设计方式，只要算法借助迭代器就能遍历容器。  
本文不讲解迭代器的使用方法，重在探究迭代器的实现
## 二、迭代器的简单原理
下面简单实现一个vector迭代器，重在看清其中原理
```C++
#include<iostream>
using namespace std;
//简单的Vector迭代器
template<class T>
class VectorIterator
{
public: 
    //类型重定义 
    typedef T ValueType; 
    typedef T* Pointer; 
    typedef T& Reference; 
    typedef VectorIterator<T> Iterator; 
    //构造 
    VectorIterator(Pointer ptr) :_ptr(ptr) {} 
    //前置++ 
    Iterator operator++() 
    { _ptr++; return VectorIterator<T>(_ptr); } 
    //!=重载 
    bool operator!=(Iterator x) { return _ptr != x._ptr; } 
    //*重载 
    ValueType operator*() { return *_ptr; }
private: 
    Pointer _ptr;
};
//简单的vector
template<class T>
class Vector
{
public: 
    typedef VectorIterator<T> Iterator; 
    typedef T ValueType; 
    typedef T* Pointer; 
    typedef T& Reference; 
    //构造 
    Vector() 
    { 
        for (int i = 0; i < 10; ++i) 
        { _a[i] = i + 1; } 
    } 
    //容器末后第一位置迭代器 
    Iterator End() 
    { return Iterator(&_a[10]); } 
    //容器首迭代器 
    Iterator Began() { return Iterator(&_a[0]); }
private: 
    T _a[10];
};
//用迭代器遍历元素
//其实也就是算法部分
int main()
{ 
    Vector<int> V1; 
    Vector<int>::Iterator t1 = V1.Began(); 
    for (; t1 != V1.End(); ++t1) 
    { cout << *t1 << " "; } 
    return 0;
}
```
从上面简单实现的代码中可以看出，在每个容器的类里用方法把直接的内部变量输出为迭代器，让迭代器去操作，所有的迭代器外部接口都是一样，可是每个容器的迭代器对自己容器的操作却不同，比如list在++操作时，执行x=x->next这种操作，而vector却因为是原生指针，直接++即可，这样只能实现者知道容器的内容，而且针对不同的容器有各自操作提高效率。
## 三、萃取编程方法
看似很简单是吧，看起来也是，问题来了，我传入了一个T模板类型，我想返回他的valueType类型怎么办，简单来说如果我传入一个自定义的类型想返回他的值类型怎么办，好像没办法，但c++利用声明内嵌类型的方法做到了，先看看代码，稍后讲解
```C++
#include<iostream>
using namespace std;
template<class T>
class A
{
public:
    //自定义类型中声明内嵌类型 
    typedef T ValueType; 
    typedef T* Pointer; 
    typedef T& Reference; 
    A() {} 
    A(T a) :_a(a) {} 
    ~A() {}
private: 
    T _a;
};
//类型萃取机
template<class T>
struct traits
{ 
    //自定义类型中声明内嵌类型 
    //typename是用来证明T::ValueType 是一个类型 
    //编译器在未用实际类型代替T前对T一无所知，所以要证明^-^ 
    typedef typename T::ValueType ValueType; 
    typedef typename T::Pointer Pointer; 
    typedef typename T::Reference Reference;
};
//用来证明是否取得A类型中的ValueType类型
//也就是int类型
template<class T>
class B
{
public: 
    //typename是用来证明traits<T>::ValueType 是一个类型 
    //编译器在未用实际类型代替T前对T一无所知，所以要证明^-^ 
    typename traits<T>::ValueType  test() 
    { 
        //试着把这改成字符串， 
        //编译器就会报错，说类型不匹配，因为返回类型已经萃取为int 
        return 1; 
    }
};

int main()
{ 
    A<int> objectA(1); 
    B<A<int>> objectB; 
    cout<<objectB.test(); 
    return 0;
}
```
  那么问题又来了，上面萃取机中的T如果是普通指针类型不是自定义类型那么不久萃取不出来了，好像是这样，因为普通指针类型并不像上面的A类型即自定义类型有ValueType的内嵌声明。不过STL才不会这么笨，它提供了一种叫做特化的东东，看过我网站第一篇空间配置器的想必一定都知道了，要是不知道的，麻烦在我网站上搜一下偏特化，看一下，有了偏特化那么针对原生指针就可以这样。
```C++
//类型萃取机T*特化
template<class T>struct traits<T*>
{ 
    //自定义类型中声明内嵌类型 
    //typename是用来证明T::ValueType 是一个类型 
    //编译器在未用实际类型代替T前对T一无所知，所以要证明^-^ 
    typedef T ValueType; 
    typedef T* Pointer; 
    typedef T& Reference;
};
//当然还有const T*特化
template<class T>
struct traits<const T*>
{ 
    //自定义类型中声明内嵌类型 
    //typename是用来证明T::ValueType 是一个类型 
    //编译器在未用实际类型代替T前对T一无所知，所以要证明^-^ 
    typedef T ValueType; 
    typedef T* Pointer; 
    typedef T& Reference;
};
```
## 四、迭代器相应型别类型
上面我们为了简单只说了ValueType(值类型)、Pointer（值指针类型）、Reference(值引用类型)  
上面说的几种还是很好理解，其实还有两种,一种就叫Difference这种类型就是记录两个迭代器之间距离，因此就可记录容量,最后一种叫iterator_categoty,见名知意，就是迭代器类型。
```C++
template <class Category, class T, class Distance = ptrdiff_t, class Pointer = T*, class Reference = T&>
struct Iterator
{ 
    typedef Category IteratorCategory; // 迭代器类型
    typedef T ValueType; // 迭代器所指对象类型 
    typedef Distance DifferenceType; // 两个迭代器之间的距离 
    typedef Pointer Pointer; // 迭代器所指对象类型的指针
    typedef Reference Reference; // 迭代器所指对象类型的引用
};
```
迭代器种类分为五种：  

- InputIterator：只读类型迭代器
- OutputIterator：只写类型迭代器
- ForwardIterator：前向迭代器，只能单向移动，类似于单链表的迭代器
- BidirectionalIterator：双向迭代器，双向移动，类似于双向链表迭代器
- RandomAccessIterator：随机读写迭代器，可以进行随机读写，vector类型  

他们有相互之间的继承关系，如下代码，想必不用说知道为什么这样继承，能双向移动必定能单向移动，以此类推。
![迭代器](https://chengsanban.github.io/image/STL-iterator/iterator.png)
```C++
struct InputIteratorTag {};//只读
struct OutputIteratorTag {};//只写
struct ForwardIteratorTag : public InputIteratorTag {};
struct BidirectionalIteratorTag : public ForwardIteratorTag {};
struct RandomAccessIteratorTag : public BidirectionalIteratorTag {};
```
  设计类别当然是有原因的，当一个类接收InputIterator时，它肯定也能接受BidirectionalIterator，当有一个函数要将迭代器前移几步BidirectionalIterator直接+n就行，而InputIterator却要一步一步的走，所以说选择好一个迭代器类型是很重要的，他决定了这个迭代器的效率。  
  
> 图文来自博主原来博客chengvincent.com