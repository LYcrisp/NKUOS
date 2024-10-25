### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习0：填写已有实验

本实验依赖实验1。请把你做的实验1的代码填入本实验中代码中有“LAB1”的注释相应部分并按照实验手册进行进一步的修改。具体来说，就是跟着实验手册的教程一步步做，然后完成教程后继续完成完成exercise部分的剩余练习。

#### 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 你的first fit算法是否有进一步的改进空间？

在Lab-2的代码结构中，物理内存分配的流程首先在 `kern_init()` 函数中调用 `pmm_init()` 来进行物理内存管理的初始化和虚拟内存的映射。在此过程中，先后执行了 `init_pmm_manager()` 和 `page_init()` 函数。前者负责确定物理内存管理器 `pmm_manager` 并调用相应的默认初始化函数（例如使用 first-fit 策略），以便初始化管理页面的双向链表和总内存块数量；后者则用于检测物理内存状态，将空闲内存按照规定的页面大小构建页面结构，计算空闲内存的起始地址和可用页面数量，最后调用封装好的 `init_memmap()` 函数进一步初始化管理器。

接下来是对这四个函数的介绍：

1. **内存初始化 (`default_init`, `default_init_memmap`)**  
   系统启动时，操作系统需要初始化物理内存管理系统，以追踪哪些页面可以被分配，哪些页面已经分配出去。

2. **内存分配 (`default_alloc_pages`)**  
   此函数用于从空闲内存列表中分配指定数量的页面。当操作系统收到内存分配请求时，它会遍历空闲链表，寻找第一个符合请求大小的空闲块。如果找到合适的块，系统会更新该块的信息，并返回分配的页面地址。

3. **内存释放 (`default_free_pages`)**  
   该函数负责将已分配的页面重新链接到空闲内存列表中。在释放内存时，系统会检查释放的页面前后是否有相邻的空闲块，如果有，则会合并这些空闲块，以减少内存碎片并提高内存利用效率。

##### 1.`default_init` 函数

`default_init` 是物理内存管理系统初始化的基础函数。它的主要作用是：

1. **初始化空闲链表**  
   函数调用 `list_init(&free_list)` 来初始化一个空的双向链表，`free_list` 用于管理系统中可用的空闲内存块。通过维护这个链表，操作系统能够有效跟踪哪些内存页面是空闲的，哪些是已分配的。

2. **设置空闲页面计数**  
   `nr_free` 被初始化为 0，表示当前没有空闲的内存块。随着内存的分配和释放，这个计数会相应更新，从而帮助操作系统管理可用内存。

通过这个初始化过程，`default_init` 准备了物理内存管理器的基本数据结构。


##### 2. `default_init_memmap` 函数

`default_init_memmap` 函数负责初始化一段物理内存块的状态，主要功能包括：

1. **初始化页面属性**  
   通过循环遍历从 `base` 开始的 `n` 个页面，确保每个页面的状态被正确初始化。使用 `assert(PageReserved(p))` 验证页面是否被保留，并将 `p->flags` 和 `p->property` 设置为 0，同时调用 `set_page_ref(p, 0)` 将引用计数清零。

2. **设置基本页面属性**  
   将 `base` 页面属性设置为 `n`，表示这块内存中总共有 `n` 个页面，并调用 `SetPageProperty(base)` 更新页面状态。

3. **更新空闲页面计数**  
   `nr_free` 被增加 `n`，以反映当前的空闲页面数量。

4. **更新空闲链表**  
   检查 `free_list` 是否为空。如果是，则将 `base` 页面添加到 `free_list` 中。如果不是，则遍历 `free_list`，找到合适的位置将 `base` 页面插入，确保链表保持有序。

通过这些步骤，`default_init_memmap` 函数有效地为指定的内存块准备了状态。


##### 3. `default_alloc_pages` 函数

`default_alloc_pages` 函数负责分配指定数量的物理页面，主要功能包括：

1. **检查可用页面**  
   如果请求的页面数量 `n` 大于当前空闲页面数量 `nr_free`，函数直接返回 `NULL`，表示无法满足请求。

2. **查找合适的空闲页面**  
   函数通过遍历 `free_list`，寻找第一个可用的页面 `p`，其属性 `p->property` 大于或等于 `n`。一旦找到，页面指针 `page` 将指向该页面。

3. **更新链表和页面属性**  
   如果找到了合适的页面，首先调用 `list_del(&(page->page_link))` 将其从 `free_list` 中删除。如果页面的属性大于 `n`，则计算剩余的页面数量，并更新属性 `p->property`，同时调用 `SetPageProperty(p)` 设置其状态，最后将剩余的页面重新插入到 `free_list` 中。

4. **更新空闲页面计数**  
   函数在分配成功后，减少 `nr_free` 的值，以反映当前的空闲页面数量，并调用 `ClearPageProperty(page)` 清除分配页面的状态。

##### 4. `default_free_pages` 函数

`default_free_pages` 函数负责释放指定数量的物理页面，主要功能包括：

1. **页面状态检查与初始化**  
   函数通过遍历要释放的页面，确保这些页面都未被保留且不处于已分配状态，使用 `assert(!PageReserved(p) && !PageProperty(p))` 进行检查。随后，将这些页面的标志位 `flags` 清零，并调用 `set_page_ref(p, 0)` 重置页面引用计数。

2. **更新页面属性**  
   设置 `base` 页面（释放的第一个页面）的属性 `base->property` 为 `n`，并调用 `SetPageProperty(base)` 更新页面状态。接着，增加 `nr_free` 的值，以反映当前空闲页面数量。

3. **将页面加入空闲链表**  
   检查 `free_list` 是否为空。如果为空，直接将 `base` 页面添加到 `free_list` 中；否则，遍历 `free_list`，找到合适的位置将页面插入。若 `base` 小于某个页面，则使用 `list_add_before(le, &(base->page_link))` 插入到链表中；若到达链表末尾，则使用 `list_add(le, &(base->page_link))` 添加到链表末尾。

4. **合并相邻空闲页面**  
   先检查 `base` 页面前面的页面是否可以合并。如果相邻页面 `p` 的结束地址与 `base` 的起始地址相同，则将这两个页面合并，更新 `base` 页面属性并从链表中删除 `base` 页面。  
   然后检查 `base` 页面后面的页面是否可以合并。如果相邻页面的起始地址与 `base` 页面结束地址相同，则合并这两个页面，并删除后面页面的链表条目。

---

- 你的first fit算法是否有进一步的改进空间？

改进方案如下
##### 1. 优化空闲块的查找
**解决方案：使用分级空闲链表**

在分配内存时，可以根据不同的块大小将空闲块分级存储。每个链表对应一个特定的块大小范围，减少查找时间。

###### 实现步骤：
- 定义多个链表，每个链表管理相同大小的页面。
- 在 `default_init` 函数中，初始化这些链表。
- 在 `default_alloc_pages` 中，根据请求的大小查找相应的链表，而不是遍历所有的空闲块。
- 在 `default_free_pages` 中，根据释放的块大小将其插入到合适的链表中。

###### 2. 合并相邻空闲块的策略
**解决方案：增强合并策略**

在 `default_free_pages` 函数中，除了检查相邻的空闲块外，可以引入延迟合并策略，避免频繁的合并操作。

###### 实现步骤：
- 当释放一个页面时，检查相邻的页面是否空闲。
- 将相邻的空闲块的合并标志设置为延迟合并，并在下次分配内存时检查是否需要合并。
- 可以设置分配次数延时，次数设置为n，若n次分配时都不需要使用上一次释放的的界面和其相邻的界面，则进行合并。
- 通过这样做可以减少合并开销。

###### 3. 类二分查找分配的策略
**解决方案：记录上次分配大小位置**

在 `default_alloc_pages` 中，使用类似二分查找的策略减少分配时查找的时间。

###### 实现步骤：
- 设置全局变量，记录上一次分配需要的大小和链表指针，
- 在 `default_alloc_pages` 中对比当前需要分配的大小和上一次分配需要的大小。
- 若当前需要的大小大于上一次分配需要的大小，则从记录的上一次分配位置指针开始向后查找，否则从头查找。
- 当进行释放操作时清空记录的大小和指针。


#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：

- 你的 Best-Fit 算法是否有进一步的改进空间？

`Best-fit` 和 `First-fit` 的调用过程完全相同，唯一不同点则在于分配算法的不一致。

这里的编程部分只有一处与`First-fit`有区别，代码如下：

```c
	struct Page *page = NULL;		//申请的页的指针
    list_entry_t *le = &free_list;	//获取头节点指针
    size_t min_size = nr_free + 1;
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        // TODO -----------------------------------------------------------
    	if (p->property >= n && p->property < min_size) {
            min_size = p->property;
            page = p;
        }
    	// TODO -----------------------------------------------------------
    }
```

以下是完整代码：

##### 1.`best_fit_init_memmap`
```c
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);	
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));

        /*LAB2 EXERCISE 2: YOUR CODE*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        // TODO -----------------------------------------------------------
        p->flags = p->property = 0;   // 将当前页的 flags 和 property 置为 0，表示该页现在是空闲的，不再具有任何属性。
        set_page_ref(p, 0);			 // 当前页引用计数为 0，没有其他对象引用此页。
        // TODO -----------------------------------------------------------
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link); //连表指针转为结构体指针
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
            //TODO ------------------------------------------------------
            if (base < page) {		//找到第一个大于base的页
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
            //TODO ------------------------------------------------------
        }
    }
}

```

##### 2.`best_fit_alloc_pages`
```c
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;		//请求大于空闲，内存不足
    }
    struct Page *page = NULL;		//申请的页的指针
    list_entry_t *le = &free_list;	//获取头节点指针
    size_t min_size = nr_free + 1;
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        // TODO -----------------------------------------------------------
    	if (p->property >= n && p->property < min_size) {
            min_size = p->property;
            page = p;
        }
    	// TODO -----------------------------------------------------------
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

##### 3.`best_fit_free_pages`
```c
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
	// TODO ---------------------------------
    base->property = n;		//页的属性为释放的页数 n
    SetPageProperty(base);	//标记为有效
    nr_free += n;			//更新空闲页的数量
    // TODO ---------------------------------
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {			//如果base不是最后一个节点
        p = le2page(le, page_link);	//获取前一页
         // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        // TODO -----------------------------
        if (p + p->property == base) {		//判断是否连续
            p->property += base->property;	//更新前一个空闲页块的大小
            ClearPageProperty(base);		//设置当前页面为不可用，不再是空闲页块
            list_del(&(base->page_link));	//从链表删除
            base = p;						//指针指向前一个空闲页块
        }
        // TODO -----------------------------
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

```

---
- 你的 Best-Fit 算法是否有进一步的改进空间？
与 First-fit 类似，上述 First-fit 的优化方法都可在此处使用。
此外，如果申请的大小过大时，可以采用First-fit策略，即设置一个临界值N，若申请的大小大于N时采用First-fit可节约一定的搜索时间。
#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。
