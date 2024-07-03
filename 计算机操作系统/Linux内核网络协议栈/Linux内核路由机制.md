## 路由简介

内核的路由部分是是网络中重要部分，目前在 Linux 内核中默认的路由查找算法使用的是 Hash 查找，很多的数据结构是 XXX_hash 什么之类 (例如 fn_hash)。Linux 内核从 2.1 开始就支持基于策略的路由，那么什么是基于策略的路由呢？我们一般的最基本的路由转发是考虑 IP 包的目的地址，但是有些时候不仅仅是这些，还有例如 IP 协议，传输端口等之类的考虑因素，所以采用所谓基于策略的路由。

或许这样理解更好，Linux 默认有三种策略路由：本地路由，主路由和默认路由，那么与之对应的就是三张路由表：本地路由表，主路由表和默认路由表。

那么我们需要理解是什么呢？当然是路由怎么转的过程。

## 涉及的数据结构

内核的链表结构主要是用来表示连接关系的

[代码片段 1](https://github.com/torvalds/linux/blob/v5.14/include/linux/types.h#L182-L188)：内核链表一般是双向链表（其实还是循环链表）

```c
struct hlist_head {
	struct hlist_node *first;
};

struct hlist_node {
	struct hlist_node *next, **pprev;
};
```

很多结构之间的链接都是通过这样的链表的

[代码片段 2](https://github.com/torvalds/linux/blob/v5.14/include/linux/kernel.h#L486-L498)：内核采取 container_of 这个宏定义来确定链表字段真正的首地址

```c
/**
 * container_of - cast a member of a structure out to the containing structure
 * @ptr:	the pointer to the member.
 * @type:	the type of the container struct this is embedded in.
 * @member:	the name of the member within the struct.
 *
 */
#define container_of(ptr, type, member) ({				\
	void *__mptr = (void *)(ptr);					\
	BUILD_BUG_ON_MSG(!__same_type(*(ptr), ((type *)0)->member) &&	\
			 !__same_type(*(ptr), void),			\
			 "pointer type mismatch in container_of()");	\
	((type *)(__mptr - offsetof(type, member))); })
```

## 参考资料

- <https://blog.csdn.net/qq_20817327/article/details/106575217>
- <https://blog.csdn.net/shanshanpt/article/details/19918171>