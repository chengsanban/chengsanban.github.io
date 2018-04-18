---
author: "橙三瓣"
date: 2018-04-03
title: "STL解析(2):STL空间配置器"
tags: [
    "C++",
    "C",
    "STL",
]
categories: [
    "编程笔记",
]
---
## 一、什么是空间配置器
空间配置器是STL用来为容器分配空间的组件。  
## 二、本文的一点注意事项
本文解析空间配置器事宜SGI的STL为蓝本的，其中通过画图和源码的分析组成本文章，如果仅仅只是想简单了解一下空间配置器就可以看图，但是由于图中的一些术语根据源码而来，并不是很好理解，有必要的话请看一下源码解析，尽量我会把文章内容讲清楚，如果内容有误，欢迎拍砖。  
## 三、SGI_STL空间配置器解析
### 1、总说
首先介绍一下大体框架，SGI_STL（以后简称stl）,在设计之初吧实际的类型构造，内存分配、以及一下大批量内存操作是分开来写的，这样写的好处就是各部分体现自己的作用，construct文件中主要是类型构造和析构，alloc文件主要是内存分配与释放，而最后一个文件主要定义一些大批内存的有关东西。当然上面这些都是SGI自己的思想，其他的stl还有一个分配内存的东西，就是图上左面的东东，由于他只是简单封装底层函数，效率不高，所以SGI才重写了自己的配置器。下面看图。  
![空间配置器结构图](https://chengsanban.github.io/image/STL-allocator/allocator-summary.png)
### 2、construct详解
这个文件主要是利用了一些特化来处理一些构造函数和析构函数，并不是stl空间配置器的主菜，不了解特化的同学请在我网站上找找关于特化的文章。  
![空间配置器代码图](https://chengsanban.github.io/image/STL-allocator/allocator-struct.png)  
stl_construct.h源码：
```C++
template <class _T1, class _T2>
inline void _Construct(_T1* __p, const _T2& __value)
{new ((void*) __p) _T1(__value);}

template <class _T1> 
inline void _Construct(_T1* __p) 
{new ((void*) __p) _T1();}

template <class _Tp>
inline void _Destroy(_Tp* __pointer)
{__pointer->~_Tp();}
 
template <class _ForwardIterator>
void__destroy_aux(_ForwardIterator __first, _ForwardIterator __last, __false_type)
{for ( ; __first != __last; ++__first) destroy(&*__first);}
 
template <class _ForwardIterator>
inline void __destroy_aux(_ForwardIterator, _ForwardIterator, __true_type) 
{}
  
template <class _ForwardIterator, class _Tp>
inline void __destroy(_ForwardIterator __first, _ForwardIterator __last, _Tp*)
{
    typedef typename __type_traits<_Tp>::has_trivial_destructor_Trivial_destructor;
    __destroy_aux(__first, __last, _Trivial_destructor());
}
  
template <class _ForwardIterator>
inline void _Destroy(_ForwardIterator __first, _ForwardIterator __last) 
{__destroy(__first, __last, __VALUE_TYPE(__first));}
  
inline void _Destroy(char*, char*) {}
inline void _Destroy(int*, int*) {}
inline void _Destroy(long*, long*) {}
inline void _Destroy(float*, float*) {}
inline void _Destroy(double*, double*) {}
  
#ifdef __STL_HAS_WCHAR_Tinline 
void _Destroy(wchar_t*, wchar_t*) {}
#endif 
/* __STL_HAS_WCHAR_T */
// --------------------------------------------------
// Old names from the HP STL.
template <class _T1, class _T2>
inline void construct(_T1* __p, const _T2& __value) 
{_Construct(__p, __value);}
  
template <class _T1>
inline void construct(_T1* __p)
{_Construct(__p);}
   
template <class _Tp>
inline void destroy(_Tp* __pointer) 
{_Destroy(__pointer);}
   
template <class _ForwardIterator>
inline void destroy(_ForwardIterator __first, _ForwardIterator __last)
{_Destroy(__first, __last);}
```
### 3、主菜部分，stl的内存分配策略
由于原来薄薄封装底层函数的策略太低效，所以SGI衍化出了自己的内存分配策略，主要先是考虑一下几点  

- 1、向系统的堆索要空间
- 2、内存不足的解决方法
- 3、内存碎片问题
- 4、多线程状态  

鉴于这种衍化，SGI形成了自己两层内存配置器的策略，一级和二级分配器。下来就谈一谈这两种配置器，这儿首先要谈一谈下面这个类，解释在代码注释中。,主要是把分配类型做进一步转化，并传递给深层的配置器处理。
```C++
//用于把成员函数传递给更深层的配置函数处理、
//用于把byte类型转换为sizeof (_Tp)处理
template<class _Tp, class _Alloc>
class simple_alloc 
{
    public: 
    static _Tp* allocate(size_t __n) 
    {
        return 0 == __n ? 0 : (_Tp*) _Alloc::allocate(__n * sizeof (_Tp)); 
    } 
    
    static _Tp* allocate(void) 
    { 
        return (_Tp*) _Alloc::allocate(sizeof (_Tp)); 
    } 
    
    static void deallocate(_Tp* __p, size_t __n) 
    {
        if (0 != __n) _Alloc::deallocate(__p, __n * sizeof (_Tp));     
    } 
    
    static void deallocate(_Tp* __p) 
    {
        _Alloc::deallocate(__p, sizeof (_Tp)); 
    }
};
```
#### 一级分配器介绍
  第一级配置器，当内存分配超过128byte使用，allocate()直接使用malloc()、deallocate()直接使用free()。模拟C++的set_new_hander()处理内存不足，这个句柄主要是一个函数指针，指向一个用户处理内存不足的函数，没设置的话，内存不足会抛出异常
一级配置器处理流程图：
![一级配置器](https://chengsanban.github.io/image/STL-allocator/allocator-rank1.png)

带注释代码解析：
```C++
template <int __inst>
class __malloc_alloc_template 
{
private:
    /***********处理内存不足部分*******************/ 
    static void* _S_oom_malloc(size_t); 
    static void* _S_oom_realloc(void*, size_t);
    
#ifndef __STL_STATIC_TEMPLATE_MEMBER_BUG 
    static void (* __malloc_alloc_oom_handler)();
#endif
    /***********处理内存不足部分*******************/
public:
    //用malloc分配内存，分配不了，就丢给_S_oom_malloc处理 
    static void* allocate(size_t __n)
    { 
        void* __result = malloc(__n); 
        if (0 == __result) __result = _S_oom_malloc(__n); 
        return __result; 
    }
    //直接使用free处理 
    static void deallocate(void* __p, size_t /* __n */) { free(__p); } 
    //用realloc重新分配内存，分配不了，就丢给_S_oom_realloc处理 
    static void* reallocate(void* __p, size_t /* old_sz */, size_t __new_sz) 
    { 
        void* __result = realloc(__p, __new_sz); 
        if (0 == __result) __result = _S_oom_realloc(__p, __new_sz); 
        return __result; 
    } 
    //设置__malloc_alloc_oom_handler内存不足解决方案 
    static void (* __set_malloc_handler(void (*__f)()))() 
    { 
        void (* __old)() = __malloc_alloc_oom_handler; 
        __malloc_alloc_oom_handler = __f; 
        return(__old); 
    }
};

//自行添加内存不足解决方案，默认不做什么
template <int __inst>
void (* __malloc_alloc_template<__inst>::__malloc_alloc_oom_handler)() = 0;

template <int __inst>
void* __malloc_alloc_template<__inst>::_S_oom_malloc(size_t __n)
{ 
    //设置函数指针，当内存不足，调用自己的函数处理程序 
    void (* __my_malloc_handler)(); void* __result; 
    //不断分配释放，再分配释放，分配好了就返回，没分配好继续分配 
    //调用自己的函数处理程序，如果自己没设置内存分配不足解决方案 
    //抛出异常结束 
    for (;;) 
    { 
        __my_malloc_handler = __malloc_alloc_oom_handler; 
        if (0 == __my_malloc_handler) { __THROW_BAD_ALLOC; } 
        (*__my_malloc_handler)();
        __result = malloc(__n); 
        if (__result) return(__result); 
    }
}
//和_S_oom_malloc类似
template <int __inst>
void* __malloc_alloc_template<__inst>::_S_oom_realloc(void* __p, size_t __n)
{ 
    void (* __my_malloc_handler)(); 
    void* __result; 
    for (;;) 
    { 
        __my_malloc_handler = __malloc_alloc_oom_handler; 
        if (0 == __my_malloc_handler) { __THROW_BAD_ALLOC; } 
        (*__my_malloc_handler)(); 
        __result = realloc(__p, __n); 
        if (__result) return(__result); 
    }
}
//将inst的参数指定为0
typedef __malloc_alloc_template<0> malloc_alloc;
```
#### 二级空间配置器介绍
第二级配置器比较复杂  
  
- 1、维护16个自由链表，负责十六种小型区块的配置能力、内存池是由malloc而来，内存不足调用一级配置器配置请求内存。
- 2、需求大于128byte的内存块就直接调用一级分配单元。

- 3、二级空间配置器，释放的时候，如果大于128byte就交给一级空间配置器释放，如果小于128byte就交给自由链表回收。
  由于要解决内存碎片问题，结果就会带来一些解决方法，自然会造成额外开销，分配的小块内存越少，浪费就显的越大，当小于128bytes，SGI就用内存池进行管理（memory pool），每次从内存池中拿到内存，制成自由链表，自由链表不但分配而且回收内存，当不用小块内存，自由链表就进行回收，为了方便SGI划定了自己的分配方式，以8递进，把128分为16个区间（8，16，24….128），每个区间都有对应的自由链表负责分配相应大小的内存块，所以自由链表一共有16个，当客户端申请内存时，链表会以8的倍数给予空间，所以这会造成内存内碎片问题，不过并没有两全之策（外碎片指因分配大块内存造成的空间和空间之间浪费，而内碎片指因为字节对齐而产生的浪费）
内存碎片图解：
![一级配置器](https://chengsanban.github.io/image/STL-allocator/alloctor-debris.png)

二级空间配置器默认名叫 __default_alloc_template，定义如下:
```C++
template <bool threads, int inst>
class __default_alloc_template {...};
```
这部分定义了二级分配器的自由链表的分配间隔等定义
```C++
enum {_ALIGN = 8}; //分配间隔
enum {_MAX_BYTES = 128}; //最大分配内存呢
enum {_NFREELISTS = 16}; // _MAX_BYTES/_ALIGN：自由链表个数
```
自由链表的定义，这样的设计可以使得，链表既可以指向另一个_Obj,也可以指向一个内存块，节省开销
```C++
union _Obj 
{ 
    union _Obj* _M_free_list_link; 
    char _M_client_data[1]; /* The client sees this. */ 
};
```
二级空间配置流程图
![一级配置器](https://chengsanban.github.io/image/STL-allocator/allocator-rank2.png)

正常申请自由链表够用时的注释代码：
```C++
template <bool threads, int inst>
class __default_alloc_template 
{
private: 
    enum {_ALIGN = 8}; 
    //分配间隔 
    enum {_MAX_BYTES = 128}; 
    //最大分配内存呢 
    enum {_NFREELISTS = 16}; 
    // _MAX_BYTES/_ALIGN：自由链表个数 
    //提升函数，把要申请的内存块大小提升至8的整数倍 
    static size_t _S_round_up(size_t __bytes)  
    { return (((__bytes) + (size_t) _ALIGN-1) & ~((size_t) _ALIGN - 1)); }
    //自由链表节点的定义 
    __PRIVATE: union _Obj 
    { 
        union _Obj* _M_free_list_link; 
        char _M_client_data[1]; 
        /* The client sees this. */ 
    };  
    /****************根据函数计算使用几号自由链表***************************/
private:
# if defined(__SUNPRO_CC) || defined(__GNUC__) || defined(__HP_aCC) 
    static _Obj* __STL_VOLATILE _S_free_list[];  
    // Specifying a size results in duplicate def for 4.1
# else 
    static _Obj* __STL_VOLATILE _S_free_list[_NFREELISTS]; 
# endif 
    static size_t _S_freelist_index(size_t __bytes) 
    { return (((__bytes) + (size_t)_ALIGN-1)/(size_t)_ALIGN - 1); } 
    /****************根据函数计算使用几号自由链表***************************/  
    // 返回一个大小为__n的区块，并加入相应自由链表 
    static void* _S_refill(size_t __n); 
    // 配置一大块空间可容纳nobjs个大小为size的块 
    // 如果没有那么大，可能会返回更小的 
    static char* _S_chunk_alloc(size_t __size, int& __nobjs); 
    // Chunk allocation state. 
    static char* _S_start_free;
    //内存池的开始 
    static char* _S_end_free;
    //内存池的结束 
    static size_t _S_heap_size; 
    //allocate()先是看是否大于128bytes，大于调用一级配置器，小于查看是否自由链表是否有可用块，如果没有 调用refill函数重新填充自由链表 
    /* __n must be > 0 */ 
    static void* allocate(size_t __n) 
    { 
        void* __ret = 0; 
        //大于调用一级空间配置器 
        if (__n > (size_t) _MAX_BYTES) 
        { 
            __ret = malloc_alloc::allocate(__n); 
        } 
        else 
        { 
            //计算并寻找可以用的自由链表 
            _Obj* __STL_VOLATILE* __my_free_list = _S_free_list + _S_freelist_index(__n); 
            _Obj* __RESTRICT __result = *__my_free_list; 
            //没有可用就用_S_refill重新填充链表 
            if (__result == 0) 
                __ret = _S_refill(_S_round_up(__n)); 
            else 
            { 
                //有的话返回结果调整链表 
                *__my_free_list = __result -> _M_free_list_link; __ret = __result; 
            } 
        } return __ret; 
    };  
    //deallocate()大于128byte调用一级空间配置器释放，小于的话回收进自由链表 
    //__p不可以是0 
    static void deallocate(void* __p, size_t __n) 
    { 
        //大于128调用一级空间配置器释放 
        if (__n > (size_t) _MAX_BYTES) 
            malloc_alloc::deallocate(__p, __n); 
        else 
        { 
                //小于的话寻找区块进行回收 
                _Obj* __STL_VOLATILE* __my_free_list = _S_free_list + _S_freelist_index(__n); 
                _Obj* __q = (_Obj*)__p; __q -> _M_free_list_link = *__my_free_list; *__my_free_list = __q; 
        } 
    } 
    static void* reallocate(void* __p, size_t __old_sz, size_t __new_sz);
} ;
```
自由链表分配内存操作图(回收内存亦然)：
![一级配置器](https://chengsanban.github.io/image/STL-allocator/allocator-list.png)

内存池部分  
上面提到如果自由链表没有地方可以分配了，就要refill来填充，由chunk_alloc()（稍后讲到）申请，默认取得20个新的区块，当然如上所说如果内存池不够的话，就会返回小于这个数目,而chunk_alloc()就是在内存池中申请，内存池就是二级配置器丛堆里申请一块空间，用指针指向首位，就像水池一样，用它来给自由链表填充。
带注释内存池代码
```C++
template <bool __threads, int __inst>
void* __default_alloc_template<__threads, __inst>::_S_refill(size_t __n)
{ 
    //用_S_chunk_alloc申请空间， 
    //__nobjs是传引用，所以_S_chunk_alloc可以改变他的值 
    int __nobjs = 20; 
    char* __chunk = _S_chunk_alloc(__n, __nobjs); 
    _Obj* __STL_VOLATILE* __my_free_list; _Obj* __result; _Obj* __current_obj; 
    _Obj* __next_obj; 
    int __i; 
    //如果只剩一个块，就直接返回本块给调用者 
    if (1 == __nobjs) return(__chunk); 
    //不然的话，调整free_list，加入新节点 
    __my_free_list = _S_free_list + _S_freelist_index(__n); 
    //第零块也就是__chunk开头直接给调用者，其他依次连接在
    freelist上 __result = (_Obj*)__chunk; 
    *__my_free_list = __next_obj = (_Obj*)(__chunk + __n); 
    for (__i = 1; ; __i++) 
    { 
        __current_obj = __next_obj; 
        __next_obj = (_Obj*)((char*)__next_obj + __n); 
        if (__nobjs - 1 == __i) 
        { 
            __current_obj -> _M_free_list_link = 0; break; 
        }
        else 
        { 
            __current_obj -> _M_free_list_link = __next_obj; 
        } 
    } 
    return(__result);
} 
//BOSS来了,下面就是大名鼎鼎的内存池了，他就是一直为自由链表服务的东东 
__default_alloc_template<__threads, __inst>::_S_chunk_alloc(size_t __size,  int& __nobjs)
{ 
    char* __result; 
    //计算要申请的总量 
    size_t __total_bytes = __size * __nobjs; 
    //内存池剩余空间 
    size_t __bytes_left = _S_end_free - _S_start_free; 
    //如果申请量大于总量的话，从内存池中拿出返回 
    if (__bytes_left >= __total_bytes) 
    { 
        __result = _S_start_free; 
        _S_start_free += __total_bytes; 
        return(__result); 
    } 
    else if (__bytes_left >= __size) 
    { 
        //虽然不够，但是至少够一个，那就把剩下的全部返回 
        //并修改__nobjs值 
        __nobjs = (int)(__bytes_left/__size); 
        __total_bytes = __size * __nobjs; 
        __result = _S_start_free; 
        _S_start_free += __total_bytes; 
        return(__result); 
    } 
    else 
    { 
        //连一个都给不了了，真是可怜。。。。 
        //那就把剩下的区块找能够挂载的自由链表挂上去 
        size_t __bytes_to_get =  2 * __total_bytes + _S_round_up(_S_heap_size >> 4); 
        // Try to make use of the left-over piece. 
        if (__bytes_left > 0) 
        { 
            _Obj* __STL_VOLATILE* __my_free_list = _S_free_list + _S_freelist_index(__bytes_left); 
            ((_Obj*)_S_start_free) -> _M_free_list_link = *__my_free_list; 
            *__my_free_list = (_Obj*)_S_start_free; 
        } 
        //没有分配了，只好从堆heap空间中再给内存池注水（开辟内存） 
        _S_start_free = (char*)malloc(__bytes_to_get); 
        if (0 == _S_start_free) 
        { 
            //堆内存都没有了malloc失败 
            size_t __i; 
            _Obj* __STL_VOLATILE* __my_free_list; 
            _Obj* __p;  
            //在自由链表中找一找看有没有比当前请求块大的还没用的块，把自由 
            //链表中较大的块分给自由链表中的小块使用 
            for (__i = __size; __i <= (size_t) _MAX_BYTES; __i += (size_t) _ALIGN) 
            { 
                __my_free_list = _S_free_list + _S_freelist_index(__i); 
                __p = *__my_free_list; 
                if (0 != __p) 
                { 
                    *__my_free_list = __p -> _M_free_list_link; 
                    _S_start_free = (char*)__p; 
                    _S_end_free = _S_start_free + __i; 
                    return(_S_chunk_alloc(__size, __nobjs)); 
                    //返回重新制定好，符合当前块大小块的数量 
                    //注意要把剩余的内存榨干（有点狠，不过下下之策嘛^-^） 
                } 
            }  
            //真的山穷水尽，只好调用一级配置器，因为一级配置器有处理内存耗空的 
            //c++句柄，当然要是你没有设置，只能是抛异常了。 
            _S_end_free = 0; 
            // In case of exception. 
            _S_start_free = (char*)malloc_alloc::allocate(__bytes_to_get); 
            // This should either throw an 
            // exception or remedy the situation. Thus we assume it // succeeded. 
        }  //堆申请正常，正常返回 
        _S_heap_size += __bytes_to_get; 
        _S_end_free = _S_start_free + __bytes_to_get; 
        return(_S_chunk_alloc(__size, __nobjs)); 
    }
}
```

### 4、uninitialized.h解析  
这些函数用来，当实现一个容器的时候，分配完内存呢，在分配好的内存之上构造元素。成功的话构造出元素，失败什么都不做，析构掉原来构造的。  
- 1、uninitialized_copy  这个函数参数依次是，输入端起始位置、输入端结束位置、输出端起始位置
```C++
//进入初始化之后先进入__uninitialized_copy判断是否是POD(Plain Old Data)类型,
//即是否为简单类型，或者说不需要构造函数的
template <class _InputIter, class _ForwardIter>
inline _ForwardIter uninitialized_copy(_InputIter __first, _InputIter __last, _ForwardIter __result)
{ return __uninitialized_copy(__first, __last, __result, __VALUE_TYPE(__result));}

//判断完毕通过类型萃取和特化，如果是POD类型，交给相应部分处理，提高填充速度
//非POD就通过构造函数构造
template <class _InputIter, class _ForwardIter, class _Tp>
inline _ForwardIter __uninitialized_copy(_InputIter __first, _InputIter __last, _ForwardIter __result, _Tp*)
{ typedef typename __type_traits<_Tp>::is_POD_type _Is_POD; return __uninitialized_copy_aux(__first, __last, __result, _Is_POD());}

//当然针对char*和wchar_t*提供了特化版本 ，因为他们可以用memmove，这样更高效
inline char* uninitialized_copy(const char* __first, const char* __last, char* __result) 
{ 
    memmove(__result, __first, __last - __first); 
    return __result + (__last - __first);
}

inline wchar_t*  uninitialized_copy(const wchar_t* __first, const wchar_t* __last, wchar_t* __result)
{ 
    memmove(__result, __first, sizeof(wchar_t) * (__last - __first)); 
    return __result + (__last - __first);
}
```  

- 2、uninitialized_fill  

这个函数参数依次是，输出端起始处，输出端结束处，__x为初值  

```C++
//进入初始化之后先进入__uninitialized_fill判断是否是POD(Plain Old Data)类型,
//即是否为简单类型，或者说不需要构造函数的template 
<class _ForwardIter, class _Tp>
inline void uninitialized_fill(_ForwardIter __first, _ForwardIter __last,  const _Tp& __x)
{ __uninitialized_fill(__first, __last, __x, __VALUE_TYPE(__first));}

//判断完毕通过类型萃取和特化，如果是POD类型，交给相应部分处理，提高填充速度
//非POD就通过构造函数构造
template <class _ForwardIter, class _Tp, class _Tp1>
inline void __uninitialized_fill(_ForwardIter __first,  _ForwardIter __last, const _Tp& __x, _Tp1*)
{ 
    typedef typename __type_traits<_Tp1>::is_POD_type _Is_POD; 
    __uninitialized_fill_aux(__first, __last, __x, _Is_POD()); 
}
```  

- 3、uninitialized_fill_n
这个函数参数依次是，要初始化地点的开始的迭代器，要初始化大小，初始化的值
```C++
//进入初始化之后先进入__uninitialized_fill_n判断是否是POD(Plain Old Data)类型,
//即是否为简单类型，或者说不需要构造函数的
template <class _ForwardIter, class _Size, class _Tp>
inline _ForwardIter  uninitialized_fill_n(_ForwardIter __first, _Size __n, const _Tp& __x)
{ return __uninitialized_fill_n(__first, __n, __x, __VALUE_TYPE(__first));}

//判断完毕通过类型萃取和特化，如果是POD类型，交给相应部分处理，提高填充速度
//非POD就通过构造函数构造
template <class _ForwardIter, class _Size, class _Tp, class _Tp1>
inline _ForwardIter  __uninitialized_fill_n(_ForwardIter __first, _Size __n, const _Tp& __x, _Tp1*)
{ 
    typedef typename __type_traits<_Tp1>::is_POD_type _Is_POD; 
    return __uninitialized_fill_n_aux(__first, __n, __x, _Is_POD());
}
```
当然就有人问了，这么的话，这些函数有什么区别呀！参数呀，各位。。。。。。。。。
## 四、小结
stl是C++程序的一份瑰宝，它代表了编程中最精妙的技法和最哲思的考虑，经常看大师的源码，就算不能增加智商也能潜移默化收到影响，希望大家最后技术越来越好，NO_BUG。
   
> 图文来自博主原来博客chengvincent.com