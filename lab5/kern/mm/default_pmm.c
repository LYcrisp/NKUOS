#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* 在首次适应算法中，分配器保持一个空闲块列表（称为空闲列表），
    并在收到内存请求时，沿着列表扫描第一个足够大的块来满足请求。
    如果所选块明显大于请求的块，则通常会将其拆分，并将剩余部分作为另一个空闲块添加到列表中。
    请参阅严蔚敏的中文书《数据结构——C语言描述》第196~198页，第8.2节
*/
// LAB2 练习 1: 你的代码
// 你应该重写函数：default_init, default_init_memmap, default_alloc_pages, default_free_pages。

/*
 * FFMA 详细信息
 * (1) 准备：为了实现首次适应内存分配（FFMA），我们应该使用一些列表来管理空闲内存块。
 *              struct free_area_t 用于管理空闲内存块。首先你应该熟悉 list.h 中的 struct list。struct list 是一个简单的双向链表实现。
 *              你应该知道如何使用：list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              另一个巧妙的方法是将一般列表结构转换为特殊结构（例如 struct page）：
 *              你可以找到一些宏：le2page（在 memlayout.h 中），（在未来的实验中：le2vma（在 vmm.h 中），le2proc（在 proc.h 中）等。）
 * (2) default_init: 你可以重用演示 default_init 函数来初始化 free_list 并将 nr_free 设置为 0。
 *              free_list 用于记录空闲内存块。nr_free 是空闲内存块的总数。
 * (3) default_init_memmap: 调用图：kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              此函数用于初始化一个空闲块（参数：addr_base, page_number）。
 *              首先你应该初始化此空闲块中的每个页面（在 memlayout.h 中），包括：
 *                  p->flags 应该设置 PG_property 位（表示此页面有效。在 pmm_init 函数（在 pmm.c 中）中，
 *                  PG_reserved 位已在 p->flags 中设置）
 *                  如果此页面是空闲的并且不是空闲块的第一页，p->property 应该设置为 0。
 *                  如果此页面是空闲的并且是空闲块的第一页，p->property 应该设置为块的总数。
 *                  p->ref 应该为 0，因为现在 p 是空闲的，没有引用。
 *                  我们可以使用 p->page_link 将此页面链接到 free_list，（例如：list_add_before(&free_list, &(p->page_link));）
 *              最后，我们应该总结空闲内存块的数量：nr_free+=n
 * (4) default_alloc_pages: 在空闲列表中搜索找到第一个空闲块（块大小 >=n）并调整空闲块的大小，返回分配块的地址。
 *              (4.1) 所以你应该像这样搜索空闲列表：
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) 在 while 循环中，获取 struct page 并检查 p->property（记录空闲块的数量）>=n？
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) 如果我们找到这个 p，那么这意味着我们找到了一个空闲块（块大小 >=n），并且可以分配前 n 页。
 *                     此页面的一些标志位应设置：PG_reserved =1, PG_property =0
 *                     从 free_list 中取消链接页面
 *                     (4.1.2.1) 如果 (p->property >n)，我们应该重新计算此空闲块的其余部分的数量，
 *                           （例如：le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3) 重新计算 nr_free（所有空闲块的剩余数量）
 *                 (4.1.4) 返回 p
 *               (4.2) 如果我们找不到空闲块（块大小 >=n），则返回 NULL
 * (5) default_free_pages: 将页面重新链接到空闲列表中，可能将小的空闲块合并为大的空闲块。
 *               (5.1) 根据撤回块的基地址，搜索空闲列表，找到正确的位置（从低地址到高地址），并插入页面。（可以使用 list_next, le2page, list_add_before）
 *               (5.2) 重置页面的字段，例如 p->ref, p->flags（PageProperty）
 *               (5.3) 尝试合并低地址或高地址块。注意：应正确更改某些页面的 p->property。
 */

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 初始化 free_list 并将 nr_free 设置为 0
static void
default_init(void) {
     list_init(&free_list);
     nr_free = 0;
}

// 初始化一个空闲块（参数：base, n）
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0); // 确保 n 大于 0
    struct Page *p = base; // 初始化指针 p 指向 base
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
        assert(PageReserved(p)); // 确保页面 p 被保留
        p->flags = p->property = 0; // 将页面 p 的 flags 和 property 置为 0
        set_page_ref(p, 0); // 将页面 p 的引用计数置为 0
    }
    base->property = n; // 将 base 页面的 property 设置为 n
    SetPageProperty(base); // 设置 base 页面的属性
    nr_free += n; // 增加空闲页面的数量
    if (list_empty(&free_list)) { // 如果空闲列表为空
        list_add(&free_list, &(base->page_link)); // 将 base 页面添加到空闲列表中
    } else { // 如果空闲列表不为空
        list_entry_t* le = &free_list; // 初始化指针 le 指向空闲列表
        while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
             struct Page* page = le2page(le, page_link); // 获取 le 对应的页面
             if (base < page) { // 如果 base 页面地址小于当前页面地址
                 list_add_before(le, &(base->page_link)); // 将 base 页面插入到当前页面之前
                 break; // 退出循环
             } else if (list_next(le) == &free_list) { // 如果已经到达空闲列表的末尾
                 list_add(le, &(base->page_link)); // 将 base 页面添加到空闲列表末尾
             }
        }
    }
}

// 分配 n 页内存
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0); // 确保 n 大于 0
    if (n > nr_free) { // 如果 n 大于空闲页面的数量
        return NULL; // 返回 NULL
    }
    struct Page *page = NULL; // 初始化指针 page 为 NULL
    list_entry_t *le = &free_list; // 初始化指针 le 指向空闲列表
    while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
        struct Page *p = le2page(le, page_link); // 获取 le 对应的页面
        if (p->property >= n) { // 如果页面 p 的属性大于或等于 n
             page = p; // 将 page 指向 p
             break; // 退出循环
        }
    }
    if (page != NULL) { // 如果找到了合适的页面
        list_entry_t* prev = list_prev(&(page->page_link)); // 获取 page 的前一个节点
        list_del(&(page->page_link)); // 将 page 从空闲列表中删除
        if (page->property > n) { // 如果页面的属性大于 n
             struct Page *p = page + n; // 计算剩余页面的起始地址
             p->property = page->property - n; // 设置剩余页面的属性
             SetPageProperty(p); // 设置剩余页面的属性标志
             list_add(prev, &(p->page_link)); // 将剩余页面添加到空闲列表中
        }
        nr_free -= n; // 减少空闲页面的数量
        ClearPageProperty(page); // 清除页面的属性标志
    }
    return page; // 返回分配的页面
}

// 释放 n 页内存
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0); // 确保 n 大于 0
    struct Page *p = base; // 初始化指针 p 指向 base
    for (; p != base + n; p ++) { // 遍历从 base 开始的 n 个页面
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页面 p 没有被保留且没有属性
        p->flags = 0; // 将页面 p 的 flags 置为 0
        set_page_ref(p, 0); // 将页面 p 的引用计数置为 0
    }
    base->property = n; // 将 base 页面的 property 设置为 n
    SetPageProperty(base); // 设置 base 页面的属性
    nr_free += n; // 增加空闲页面的数量

    if (list_empty(&free_list)) { // 如果空闲列表为空
        list_add(&free_list, &(base->page_link)); // 将 base 页面添加到空闲列表中
    } else { // 如果空闲列表不为空
        list_entry_t* le = &free_list; // 初始化指针 le 指向空闲列表
        while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
             struct Page* page = le2page(le, page_link); // 获取 le 对应的页面
             if (base < page) { // 如果 base 页面地址小于当前页面地址
                 list_add_before(le, &(base->page_link)); // 将 base 页面插入到当前页面之前
                 break; // 退出循环
             } else if (list_next(le) == &free_list) { // 如果已经到达空闲列表的末尾
                 list_add(le, &(base->page_link)); // 将 base 页面添加到空闲列表末尾
             }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link)); // 获取 base 的前一个节点
    if (le != &free_list) { // 如果前一个节点不是空闲列表头
        p = le2page(le, page_link); // 获取 le 对应的页面
        if (p + p->property == base) { // 如果前一个页面的结束地址等于 base 的起始地址
             p->property += base->property; // 合并两个页面块
             ClearPageProperty(base); // 清除 base 页面的属性标志
             list_del(&(base->page_link)); // 将 base 从空闲列表中删除
             base = p; // 更新 base 指针
        }
    }

    le = list_next(&(base->page_link)); // 获取 base 的下一个节点
    if (le != &free_list) { // 如果下一个节点不是空闲列表头
        p = le2page(le, page_link); // 获取 le 对应的页面
        if (base + base->property == p) { // 如果 base 的结束地址等于下一个页面的起始地址
             base->property += p->property; // 合并两个页面块
             ClearPageProperty(p); // 清除 p 页面的属性标志
             list_del(&(p->page_link)); // 将 p 从空闲列表中删除
        }
    }
}

// 返回空闲页数
static size_t
default_nr_free_pages(void) {
     return nr_free;
}

// 基本检查函数
static void
basic_check(void) {
     struct Page *p0, *p1, *p2;
     p0 = p1 = p2 = NULL;
     assert((p0 = alloc_page()) != NULL);
     assert((p1 = alloc_page()) != NULL);
     assert((p2 = alloc_page()) != NULL);

     assert(p0 != p1 && p0 != p2 && p1 != p2);
     assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

     assert(page2pa(p0) < npage * PGSIZE);
     assert(page2pa(p1) < npage * PGSIZE);
     assert(page2pa(p2) < npage * PGSIZE);

     list_entry_t free_list_store = free_list;
     list_init(&free_list);
     assert(list_empty(&free_list));

     unsigned int nr_free_store = nr_free;
     nr_free = 0;

     assert(alloc_page() == NULL);

     free_page(p0);
     free_page(p1);
     free_page(p2);
     assert(nr_free == 3);

     assert((p0 = alloc_page()) != NULL);
     assert((p1 = alloc_page()) != NULL);
     assert((p2 = alloc_page()) != NULL);

     assert(alloc_page() == NULL);

     free_page(p0);
     assert(!list_empty(&free_list));

     struct Page *p;
     assert((p = alloc_page()) == p0);
     assert(alloc_page() == NULL);

     assert(nr_free == 0);
     free_list = free_list_store;
     nr_free = nr_free_store;

     free_page(p);
     free_page(p1);
     free_page(p2);
}

// LAB2: 下面的代码用于检查首次适应分配算法（你的练习 1）
// 注意：你不应该更改 basic_check, default_check 函数！
static void
default_check(void) {
     int count = 0, total = 0;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p));
          count ++, total += p->property;
     }
     assert(total == nr_free_pages());

     basic_check();

     struct Page *p0 = alloc_pages(5), *p1, *p2;
     assert(p0 != NULL);
     assert(!PageProperty(p0));

     list_entry_t free_list_store = free_list;
     list_init(&free_list);
     assert(list_empty(&free_list));
     assert(alloc_page() == NULL);

     unsigned int nr_free_store = nr_free;
     nr_free = 0;

     free_pages(p0 + 2, 3);
     assert(alloc_pages(4) == NULL);
     assert(PageProperty(p0 + 2) && p0[2].property == 3);
     assert((p1 = alloc_pages(3)) != NULL);
     assert(alloc_page() == NULL);
     assert(p0 + 2 == p1);

     p2 = p0 + 1;
     free_page(p0);
     free_pages(p1, 3);
     assert(PageProperty(p0) && p0->property == 1);
     assert(PageProperty(p1) && p1->property == 3);

     assert((p0 = alloc_page()) == p2 - 1);
     free_page(p0);
     assert((p0 = alloc_pages(2)) == p2 + 1);

     free_pages(p0, 2);
     free_page(p2);

     assert((p0 = alloc_pages(5)) != NULL);
     assert(alloc_page() == NULL);

     assert(nr_free == 0);
     nr_free = nr_free_store;

     free_list = free_list_store;
     free_pages(p0, 5);

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
          struct Page *p = le2page(le, page_link);
          count --, total -= p->property;
     }
     assert(count == 0);
     assert(total == 0);
}

const struct pmm_manager default_pmm_manager = {
     .name = "default_pmm_manager",
     .init = default_init,
     .init_memmap = default_init_memmap,
     .alloc_pages = default_alloc_pages,
     .free_pages = default_free_pages,
     .nr_free_pages = default_nr_free_pages,
     .check = default_check,
};

