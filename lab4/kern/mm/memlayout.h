#ifndef __KERN_MM_MEMLAYOUT_H__ // 防止重复包含头文件
#define __KERN_MM_MEMLAYOUT_H__ // 定义头文件标识符

/* This file contains the definitions for memory management in our OS. */ // 这个文件包含了操作系统中内存管理的定义

/* * // 虚拟内存映射图
 * Virtual memory map:                                          Permissions // 权限
 *                                                              kernel/user // 内核/用户
 *
 *     4G ------------------> +---------------------------------+ // 4G地址
 *                            |                                 | // 空内存
 *                            |         Empty Memory (*)        | // 空内存
 *                            |                                 | // 空内存
 *                            +---------------------------------+ 0xFB000000 // 当前页表
 *                            |   Cur. Page Table (Kern, RW)    | RW/-- PTSIZE // 当前页表（内核，可读写）
 *     VPT -----------------> +---------------------------------+ 0xFAC00000 // 无效内存
 *                            |        Invalid Memory (*)       | --/-- // 无效内存
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000 // 重新映射的物理内存
 *                            |                                 | // 重新映射的物理内存
 *                            |    Remapped Physical Memory     | RW/-- KMEMSIZE // 重新映射的物理内存（内核，可读写）
 *                            |                                 | // 重新映射的物理内存
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000 // 内核基地址
 *                            |                                 | // 内核基地址
 *                            |                                 | // 内核基地址
 *                            |                                 | // 内核基地址
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ // 内核基地址
 * (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped. // 内核确保“无效内存”永远不会被映射
 *     "Empty Memory" is normally unmapped, but user programs may map pages // “空内存”通常未映射，但用户程序可以根据需要映射页面
 *     there if desired. // 如果需要，可以映射页面
 *
 * */

/* All physical memory mapped at this address */ // 所有物理内存映射到这个地址
#define KERNBASE            0xFFFFFFFFC0200000 // 内核基地址
#define KMEMSIZE            0x7E00000                  // the maximum amount of physical memory // 最大物理内存大小
#define KERNTOP             (KERNBASE + KMEMSIZE) // 内核顶部地址

#define KERNEL_BEGIN_PADDR 0x80200000 // 内核起始物理地址
#define KERNEL_BEGIN_VADDR 0xFFFFFFFFC0200000 // 内核起始虚拟地址
#define PHYSICAL_MEMORY_END 0x88000000 // 物理内存结束地址

#define KSTACKPAGE          2                           // # of pages in kernel stack // 内核栈中的页数
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       // sizeof kernel stack // 内核栈大小

#ifndef __ASSEMBLER__ // 如果不是汇编代码

#include <defs.h> // 包含defs.h头文件
#include <atomic.h> // 包含atomic.h头文件
#include <list.h> // 包含list.h头文件

typedef uintptr_t pte_t; // 页表项类型
typedef uintptr_t pde_t; // 页目录项类型
typedef pte_t swap_entry_t; //the pte can also be a swap entry // 页表项也可以是交换条目

/* * // 页描述符结构体
 * struct Page - Page descriptor structures. Each Page describes one // 页描述符结构体。每个Page描述一个物理页。
 * physical page. In kern/mm/pmm.h, you can find lots of useful functions // 在kern/mm/pmm.h中，你可以找到很多有用的函数
 * that convert Page to other data types, such as physical address. // 将Page转换为其他数据类型，例如物理地址。
 * */
struct Page {
    int ref;                        // page frame's reference counter // 页框的引用计数器
    uint_t flags;                 // array of flags that describe the status of the page frame // 描述页框状态的标志数组
    unsigned int property;          // the num of free block, used in first fit pm manager // 空闲块的数量，用于首次适应内存管理器
    list_entry_t page_link;         // free list link // 空闲列表链接
    list_entry_t pra_page_link;     // used for pra (page replace algorithm) // 用于页面替换算法
    uintptr_t pra_vaddr;            // used for pra (page replace algorithm) // 用于页面替换算法
};

/* Flags describing the status of a page frame */ // 描述页框状态的标志
#define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 // 如果这个位=1：页面保留给内核，不能用于分配/释放页面；否则，这个位=0
#define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page. // 如果这个位=1：页面是一个空闲内存块的头页面（包含一些连续地址页面），可以用于分配页面；如果这个位=0：如果页面是一个空闲内存块的头页面，那么这个页面和内存块被分配。否则，这个页面不是头页面。

#define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags)) // 设置页面为保留状态
#define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags)) // 清除页面的保留状态
#define PageReserved(page)          test_bit(PG_reserved, &((page)->flags)) // 测试页面是否为保留状态
#define SetPageProperty(page)       set_bit(PG_property, &((page)->flags)) // 设置页面为属性状态
#define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags)) // 清除页面的属性状态
#define PageProperty(page)          test_bit(PG_property, &((page)->flags)) // 测试页面是否为属性状态

// convert list entry to page // 将列表条目转换为页面
#define le2page(le, member)                 \
    to_struct((le), struct Page, member) // 将列表条目转换为页面

/* free_area_t - maintains a doubly linked list to record free (unused) pages */ // 维护一个双向链表来记录空闲（未使用）页面
typedef struct {
    list_entry_t free_list;         // the list header // 列表头
    unsigned int nr_free;           // # of free pages in this free list // 这个空闲列表中的空闲页面数量
} free_area_t;

#endif /* !__ASSEMBLER__ */ // 结束条件编译

#endif /* !__KERN_MM_MEMLAYOUT_H__ */ // 结束头文件防止重复包含
