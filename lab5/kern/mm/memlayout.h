#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* This file contains the definitions for memory management in our OS. */

/* *
 * Virtual memory map:                                          Permissions
 *                                                              kernel/user
 *
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         Empty Memory (*)        |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   Cur. Page Table (Kern, RW)    | RW/-- PTSIZE
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        Invalid Memory (*)       | --/--
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    Remapped Physical Memory     | RW/-- KMEMSIZE
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |        Invalid Memory (*)       | --/--
 *     USERTOP -------------> +---------------------------------+ 0xB0000000
 *                            |           User stack            |
 *                            +---------------------------------+
 *                            |                                 |
 *                            :                                 :
 *                            |         ~~~~~~~~~~~~~~~~        |
 *                            :                                 :
 *                            |                                 |
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *                            |       User Program & Heap       |
 *     UTEXT ---------------> +---------------------------------+ 0x00800000
 *                            |        Invalid Memory (*)       | --/--
 *                            |  - - - - - - - - - - - - - - -  |
 *                            |    User STAB Data (optional)    |
 *     USERBASE, USTAB------> +---------------------------------+ 0x00200000
 *                            |        Invalid Memory (*)       | --/--
 *     0 -------------------> +---------------------------------+ 0x00000000
 * (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped.
 *     "Empty Memory" is normally unmapped, but user programs may map pages
 *     there if desired.
 *
 * */

/* 所有物理内存映射到这个地址 */
#define KERNBASE            0xFFFFFFFFC0200000
#define KMEMSIZE            0x7E00000                  // 最大物理内存大小
#define KERNTOP             (KERNBASE + KMEMSIZE)

#define KERNEL_BEGIN_PADDR 0x80200000
#define KERNEL_BEGIN_VADDR 0xFFFFFFFFC0200000
#define PHYSICAL_MEMORY_END 0x88000000
/* *
 * 虚拟页表。页目录 (Page Directory) 中的 PDX[VPT] 条目包含一个指向页目录本身的指针，
 * 从而将页目录变成一个页表，该页表将包含整个虚拟地址空间的页映射的所有 PTE (页表条目)
 * 映射到从 VPT 开始的 4 兆区域。
 * */

#define KSTACKPAGE          2                           // 内核栈中的页数
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       // 内核栈大小

#define USERTOP             0x80000000
#define USTACKTOP           USERTOP
#define USTACKPAGE          256                         // 用户栈中的页数
#define USTACKSIZE          (USTACKPAGE * PGSIZE)       // 用户栈大小

#define USERBASE            0x00200000
#define UTEXT               0x00800000                  // 用户程序一般从这里开始
#define USTAB               USERBASE                    // 用户 STABS 数据结构的位置

#define USER_ACCESS(start, end)                     \
(USERBASE <= (start) && (start) < (end) && (end) <= USERTOP)

#define KERN_ACCESS(start, end)                     \
(KERNBASE <= (start) && (start) < (end) && (end) <= KERNTOP)

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;
typedef pte_t swap_entry_t; //pte 也可以是一个交换条目

/* *
 * struct Page - 页描述符结构。每个 Page 描述一个物理页。
 * 在 kern/mm/pmm.h 中，你可以找到很多将 Page 转换为其他数据类型的有用函数，
 * 例如物理地址。
 * */
struct Page {
    int ref;                        // 页框的引用计数器
    uint64_t flags;                 // 描述页框状态的标志数组
    unsigned int property;          // 空闲块的数量，用于首次适配内存管理器
    list_entry_t page_link;         // 空闲列表链接
    list_entry_t pra_page_link;     // 用于页面替换算法 (PRA)
    uintptr_t pra_vaddr;            // 用于页面替换算法 (PRA)
};

/* 描述页框状态的标志 */
#define PG_reserved                 0       // 如果这个位=1：该页保留给内核，不能在 alloc/free_pages 中使用；否则，这个位=0
#define PG_property                 1       // 如果这个位=1：该页是一个空闲内存块的头页（包含一些连续地址页），可以在 alloc_pages 中使用；如果这个位=0：如果该页是空闲内存块的头页，那么该页和内存块已被分配。否则，该页不是空闲内存块的头页。

#define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags))
#define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags))
#define PageReserved(page)          test_bit(PG_reserved, &((page)->flags))
#define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))
#define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags))
#define PageProperty(page)          test_bit(PG_property, &((page)->flags))

// 将列表条目转换为页
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)

/* free_area_t - 维护一个双向链表来记录空闲（未使用）页 */
typedef struct {
    list_entry_t free_list;         // 列表头
    unsigned int nr_free;           // 该空闲列表中的空闲页数
} free_area_t;


#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
