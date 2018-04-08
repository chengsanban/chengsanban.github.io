---
author: "橙三瓣"
date: 2018-04-07
title: "STL解析(4):STL序列式容器"
tags: [
    "C++",
    "C",
    "STL",
]
categories: [
    "编程笔记",
]
---
## 一、容器的分类
序列式容器：元素可以有序，但不一定有序的容器  
关联式容器：元素内有自己的对应关系，例如set的key-value对    
![容器总览](https://chengsanban.github.io/image/STL-container/STL-allContainer.png)
## 二、各种容器简述
### vector
#### 底层结构：  
申请的一段内存空间，利用start，finish(目前使用的空间尾)，end_of_storage(申请空间的尾)  
![vector](https://chengsanban.github.io/image/STL-container/STL-vector.png)

#### 容器特点  
- 类似于array数组的容器。支持随机读取。连续空间
- 有自动增容部分，相比于数组，更加便捷
- 两倍增容方式，使用realloc增容，要是空间后有空间最好，直接申请增容就好，要是没有空间，就要另外开辟，然后数据复制过去，释放原空间，返回现有空间。
- 方法介绍  
![vector函数](https://chengsanban.github.io/image/STL-container/STL-vectorFunction.png)
### list
#### 底层结构：  
双向循环链表  
![list](https://chengsanban.github.io/image/STL-container/STL-list.png)

#### 容器特点：  
- 更加节省空间，对空间把握精确
- 不支持随机读取，
- 双向循环方式可以使得一个指针便能遍历链表，方便快捷
- 方法介绍  
![list函数](https://chengsanban.github.io/image/STL-container/STL-listFunction.png)
### deque
#### 底层结构：  
双端队列，支持从两边插入，删除  
![deque](https://chengsanban.github.io/image/STL-container/STL-deque.png)

#### 容器特点：  
- 假连续，看起来是一个首尾开放的vector其实不是。vector为了保持连续，当前空间尾不支持继续添加元素时，也不能增容时，会令外开辟空间，如上面图,但是deque并不会出现这种情况，因为它是假连续。看图
- 由于及假连续问题，所以容器结构比较复杂，执行效率比较低
- 系统维持一个map指针数组，指向各个分别的块，用复杂流程维系表面看起来像一个连续块
- 方法介绍  
![deque函数](https://chengsanban.github.io/image/STL-container/STL-dequeFunction.png)
### stack  
#### 底层结构：  
deque封闭一端即可
#### 容器特点：  
- 配接器，由于低层有现有容器简单封装（改其接口而使之成为另一种风貌，称之配接器）
- 先进后出，所以并没有迭代器，不能遍历。有其他方法。
- 方法介绍  
![stack函数](https://chengsanban.github.io/image/STL-container/STL-stackFunction.png)
### queue
#### 底层结构：
双端队列deque封闭一端入口，另一端出口
#### 容器特点：  
- 配接器，由于低层有现有容器简单封装，（改其接口而使之成为另一种风貌，称之配接器）
- 先进先出，所以并没有迭代器，不能遍历。有其他方法。
- 方法介绍  
![queue函数](https://chengsanban.github.io/image/STL-container/STL-queueFunction.png)
### heap
#### 底层结构：
vector+heap（算法）所以在情理上来说他并不算是一个容器，是vector的算法表现  
#### 容器特点：  
- 堆的原理是通过堆算法使vector中的元素表述为一种完全二叉树的结构，类似于按层把树放在vector中。
- 堆算法不仅可以让堆顶元素最小或最大，还能进行堆排序
- 堆的具体介绍详见这篇文章 点击跳转
- 方法介绍  
![heap函数](https://chengsanban.github.io/image/STL-container/STL-heapFunction.png)
### priority_queue
#### 底层结构：  
底部就是堆的封装
#### 容器特点：  
- 由于堆有加入元素从最后加入，从堆顶出元素的特点，且堆顶元素必为最大或最小，并且底部是一个vector诸多便捷，所以正好做一个队列使用，队列事件的优先级权值做堆的节点，最大优先级的事件就会出现在堆顶。
- 具体实现看堆
- 方法介绍  
![Pqueue函数](https://chengsanban.github.io/image/STL-container/STL-PqueueFunction.png)  
### slist
#### 底层结构：  
双向链表，list是双向循环链表  
#### 容器特点：  
- list迭代器是双向迭代器，而slist是前向迭代器，迭代器的具体介绍详见这篇文章 点击跳转  

> 图文来自博主原来博客chengvincent.com
