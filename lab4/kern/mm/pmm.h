#ifndef __KERN_MM_PMM_H__ // 防止重复包含头文件
#define __KERN_MM_PMM_H__

#include <defs.h> // 包含通用定义
#include <mmu.h> // 包含内存管理单元定义
#include <memlayout.h> // 包含内存布局定义
#include <atomic.h> // 包含原子操作定义
#include <assert.h> // 包含断言定义

/* fork flags used in do_fork*/
#define CLONE_VM            0x00000100  // 如果进程间共享虚拟内存则设置
#define CLONE_THREAD        0x00000200  // 线程组

// pmm_manager 是一个物理内存管理类。一个特殊的 pmm 管理器 - XXX_pmm_manager
// 只需要实现 pmm_manager 类中的方法，然后 XXX_pmm_manager 就可以被 ucore 用来管理总物理内存空间。
struct pmm_manager {
    const char *name;                                 // XXX_pmm_manager 的名称
    void (*init)(void);                               // 初始化内部描述和管理数据结构
                                                      // (空闲块列表，空闲块数量) 的 XXX_pmm_manager 
    void (*init_memmap)(struct Page *base, size_t n); // 根据初始空闲物理内存空间设置描述和管理数据结构
    struct Page *(*alloc_pages)(size_t n);            // 分配 >=n 页，取决于分配算法
    void (*free_pages)(struct Page *base, size_t n);  // 释放 >=n 页，基于 Page 描述符结构的 "base" 地址 (memlayout.h)
    size_t (*nr_free_pages)(void);                    // 返回空闲页的数量
    void (*check)(void);                              // 检查 XXX_pmm_manager 的正确性
};

extern const struct pmm_manager *pmm_manager; // 声明一个外部的 pmm_manager 指针
extern pde_t *boot_pgdir; // 声明一个外部的页目录指针
extern const size_t nbase; // 声明一个外部的基数
extern uintptr_t boot_cr3; // 声明一个外部的 CR3 寄存器值

void pmm_init(void); // 初始化物理内存管理

struct Page *alloc_pages(size_t n); // 分配 n 页
void free_pages(struct Page *base, size_t n); // 释放 n 页
size_t nr_free_pages(void); // 返回空闲页的数量

#define alloc_page() alloc_pages(1) // 分配 1 页
#define free_page(page) free_pages(page, 1) // 释放 1 页

pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create); // 获取页表项
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store); // 获取页
void page_remove(pde_t *pgdir, uintptr_t la); // 移除页
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm); // 插入页

void tlb_invalidate(pde_t *pgdir, uintptr_t la); // 使 TLB 失效
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm); // 分配页目录页

void print_pgdir(void); // 打印页目录

/* *
 * PADDR - 获取内核虚拟地址 (指向 KERNBASE 以上的地址)，
 * 机器的最大 256MB 物理内存被映射并返回相应的物理地址。
 * 如果传递了一个非内核虚拟地址，则会触发 panic。
 * */
#define PADDR(kva)                                                 \
    ({                                                             \
        uintptr_t __m_kva = (uintptr_t)(kva);                      \
        if (__m_kva < KERNBASE) {                                  \
            panic("PADDR called with invalid kva %08lx", __m_kva); \
        }                                                          \
        __m_kva - va_pa_offset;                                    \
    })

/* *
 * KADDR - 获取物理地址并返回相应的内核虚拟地址。
 * 如果传递了无效的物理地址，则会触发 panic。
 * */
#define KADDR(pa)                                                \
    ({                                                           \
        uintptr_t __m_pa = (pa);                                 \
        size_t __m_ppn = PPN(__m_pa);                            \
        if (__m_ppn >= npage) {                                  \
            panic("KADDR called with invalid pa %08lx", __m_pa); \
        }                                                        \
        (void *)(__m_pa + va_pa_offset);                         \
    })

extern struct Page *pages; // 声明一个外部的 Page 指针
extern size_t npage; // 声明一个外部的页数
extern uint_t va_pa_offset; // 声明一个外部的虚拟地址到物理地址的偏移量

static inline ppn_t
page2ppn(struct Page *page) { // 将 Page 转换为页号
    return page - pages + nbase;
}

static inline uintptr_t
page2pa(struct Page *page) { // 将 Page 转换为物理地址
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) { // 将物理地址转换为 Page
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
}

static inline void *
page2kva(struct Page *page) { // 将 Page 转换为内核虚拟地址
    return KADDR(page2pa(page));
}

static inline struct Page *
kva2page(void *kva) { // 将内核虚拟地址转换为 Page
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) { // 将页表项转换为 Page
    if (!(pte & PTE_V)) {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
}

static inline struct Page *
pde2page(pde_t pde) { // 将页目录项转换为 Page
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) { // 获取 Page 的引用计数
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) { // 设置 Page 的引用计数
    page->ref = val;
}

static inline int
page_ref_inc(struct Page *page) { // 增加 Page 的引用计数
    page->ref += 1;
    return page->ref;
}

static inline int
page_ref_dec(struct Page *page) { // 减少 Page 的引用计数
    page->ref -= 1;
    return page->ref;
}

static inline void flush_tlb() { // 刷新 TLB
  asm volatile("sfence.vma");
}

// 构造页表项
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
}

static inline pte_t ptd_create(uintptr_t ppn) { // 构造页目录项
  return pte_create(ppn, PTE_V);
}

extern char bootstack[], bootstacktop[]; // 声明外部的启动栈和启动栈顶

#endif /* !__KERN_MM_PMM_H__ */ // 结束防止重复包含头文件的宏定义
