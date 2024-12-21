#include <default_pmm.h>
#include <defs.h>
#include <error.h>
#include <kmalloc.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <sync.h>
#include <vmm.h>
#include <riscv.h>


// virtual address of physical page array
struct Page *pages; // 物理页数组的虚拟地址
// amount of physical memory (in pages)
size_t npage = 0; // 物理内存的页数
// The kernel image is mapped at VA=KERNBASE and PA=info.base
uint_t va_pa_offset; // 内核镜像映射在VA=KERNBASE和PA=info.base
// memory starts at 0x80000000 in RISC-V
const size_t nbase = DRAM_BASE / PGSIZE; // RISC-V的内存从0x80000000开始

// virtual address of boot-time page directory
pde_t *boot_pgdir = NULL; // 引导时页目录的虚拟地址
// physical address of boot-time page directory
uintptr_t boot_cr3; // 引导时页目录的物理地址

// physical memory management
const struct pmm_manager *pmm_manager; // 物理内存管理

static void check_alloc_page(void); // 检查分配页
static void check_pgdir(void); // 检查页目录
static void check_boot_pgdir(void); // 检查引导页目录

// init_pmm_manager - initialize a pmm_manager instance
// 初始化pmm_manager实例
static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager; // 设置默认的物理内存管理器
    cprintf("memory management: %s\n", pmm_manager->name); // 打印内存管理器的名称
    pmm_manager->init(); // 初始化内存管理器
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
// 调用pmm->init_memmap为空闲内存构建Page结构
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n); // 初始化内存映射
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory
// 调用pmm->alloc_pages分配连续的n*PAGESIZE内存
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL; // 初始化页指针为空
    bool intr_flag; // 中断标志

    while (1) {
        local_intr_save(intr_flag); // 保存中断状态
        {
            page = pmm_manager->alloc_pages(n); // 分配页
        }
        local_intr_restore(intr_flag); // 恢复中断状态

        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 如果分配成功或不需要交换，跳出循环

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0); // 调用swap_out进行交换
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page; // 返回分配的页
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
// 调用pmm->free_pages释放连续的n*PAGESIZE内存
void free_pages(struct Page *base, size_t n) {
    bool intr_flag; // 中断标志
    local_intr_save(intr_flag); // 保存中断状态
    {
        pmm_manager->free_pages(base, n); // 释放页
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}

// nr_free_pages - 调用pmm->nr_free_pages获取当前空闲内存的大小（nr*PAGESIZE）
size_t nr_free_pages(void) {
    size_t ret; // 定义返回值变量
    bool intr_flag; // 定义中断标志变量
    local_intr_save(intr_flag); // 保存当前中断状态
    {
        ret = pmm_manager->nr_free_pages(); // 调用pmm_manager的nr_free_pages方法获取空闲页数
    }
    local_intr_restore(intr_flag); // 恢复之前保存的中断状态
    return ret; // 返回空闲页数
}

/* pmm_init - 初始化物理内存管理 */
static void page_init(void) {
    extern char kern_entry[]; // 声明外部符号kern_entry

    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移量

    uint_t mem_begin = KERNEL_BEGIN_PADDR; // 定义内核开始的物理地址
    uint_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR; // 计算物理内存大小
    uint_t mem_end = PHYSICAL_MEMORY_END; // 定义物理内存结束地址

    cprintf("physcial memory map:\n"); // 打印物理内存映射信息
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1); // 打印内存大小和起始结束地址

    uint64_t maxpa = mem_end; // 定义最大物理地址

    if (maxpa > KERNTOP) { // 如果最大物理地址大于内核顶部地址
        maxpa = KERNTOP; // 将最大物理地址设置为内核顶部地址
    }

    extern char end[]; // 声明外部符号end

    npage = maxpa / PGSIZE; // 计算物理页数
    // BBL已经将初始页表放在内核之后的第一个可用页
    // 因此通过在end后添加额外的偏移量来避开它
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 计算物理页数组的虚拟地址

    for (size_t i = 0; i < npage - nbase; i++) { // 遍历所有物理页
        SetPageReserved(pages + i); // 将每个物理页标记为保留
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 计算空闲内存的起始地址

    mem_begin = ROUNDUP(freemem, PGSIZE); // 将空闲内存的起始地址向上取整到页边界
    mem_end = ROUNDDOWN(mem_end, PGSIZE); // 将物理内存的结束地址向下取整到页边界
    if (freemem < mem_end) { // 如果空闲内存的起始地址小于物理内存的结束地址
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE); // 初始化空闲内存的页映射
    }
    cprintf("vapaofset is %llu\n",va_pa_offset); // 打印虚拟地址和物理地址的偏移量
}

// boot_map_segment - 设置并启用分页机制
// 参数
//  la:   需要映射的内存的线性地址（在x86段映射之后）
//  size: 内存大小
//  pa:   该内存的物理地址
//  perm: 该内存的权限
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa)); // 确认线性地址和物理地址的偏移量相同
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE; // 计算需要映射的页数
    la = ROUNDDOWN(la, PGSIZE); // 将线性地址向下取整到页边界
    pa = ROUNDDOWN(pa, PGSIZE); // 将物理地址向下取整到页边界
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) { // 遍历每一页
        pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项指针
        assert(ptep != NULL); // 确认页表项指针不为空
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm); // 设置页表项
    }
}

// boot_alloc_page - 使用pmm->alloc_pages(1)分配一页
// 返回值: 分配的页的内核虚拟地址
// 注意: 此函数用于获取PDT（页目录表）和PT（页表）的内存
static void *boot_alloc_page(void) {
    struct Page *p = alloc_page(); // 分配一页
    if (p == NULL) { // 如果分配失败
        panic("boot_alloc_page failed.\n"); // 打印错误信息并停止
    }
    return page2kva(p); // 返回分配的页的内核虚拟地址
}

// pmm_init - 设置一个pmm来管理物理内存，构建PDT和PT来设置分页机制
//         - 检查pmm和分页机制的正确性，打印PDT和PT
void pmm_init(void) {
    // 我们需要分配/释放物理内存（粒度为4KB或其他大小）。
    // 因此在pmm.h中定义了物理内存管理器（struct pmm_manager）的框架。
    // 首先我们应该基于这个框架初始化一个物理内存管理器（pmm）。
    // 然后pmm可以分配/释放物理内存。
    // 现在有first_fit/best_fit/worst_fit/buddy_system pmm可用。
    init_pmm_manager(); // 初始化物理内存管理器

    // 检测物理内存空间，保留已使用的内存，
    // 然后使用pmm->init_memmap创建空闲页列表
    page_init(); // 初始化页

    // 使用pmm->check验证pmm中alloc/free函数的正确性
    check_alloc_page(); // 检查分配页

    // 创建boot_pgdir，一个初始页目录表（Page Directory Table, PDT）
    extern char boot_page_table_sv39[]; // 声明外部符号boot_page_table_sv39
    boot_pgdir = (pte_t*)boot_page_table_sv39; // 设置boot_pgdir为boot_page_table_sv39
    boot_cr3 = PADDR(boot_pgdir); // 设置boot_cr3为boot_pgdir的物理地址

    check_pgdir(); // 检查页目录

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0); // 确认KERNBASE和KERNTOP是PTSIZE的整数倍

    // 现在基本的虚拟内存映射（见memlayout.h）已经建立。
    // 检查基本虚拟内存映射的正确性。
    check_boot_pgdir(); // 检查引导页目录

    kmalloc_init(); // 初始化内核内存分配器
}

// get_pte - 获取页表项并返回该页表项的内核虚拟地址
//        - 如果页表项所在的页表不存在，则为页表分配一页
// 参数:
//  pgdir:  页目录表的内核虚拟基地址
//  la:     需要映射的线性地址
//  create: 一个逻辑值，决定是否为页表分配一页
// 返回值: 该页表项的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)]; // 获取一级页目录项的地址
    if (!(*pdep1 & PTE_V)) { // 如果一级页目录项无效
        struct Page *page; // 定义一个页指针
        if (!create || (page = alloc_page()) == NULL) { // 如果不需要创建或分配页失败
            return NULL; // 返回NULL
        }
        set_page_ref(page, 1); // 设置页的引用计数为1
        uintptr_t pa = page2pa(page); // 获取页的物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将页的内容清零
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建一级页目录项
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)]; // 获取二级页目录项的地址
    if (!(*pdep0 & PTE_V)) { // 如果二级页目录项无效
        struct Page *page; // 定义一个页指针
        if (!create || (page = alloc_page()) == NULL) { // 如果不需要创建或分配页失败
            return NULL; // 返回NULL
        }
        set_page_ref(page, 1); // 设置页的引用计数为1
        uintptr_t pa = page2pa(page); // 获取页的物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将页的内容清零
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建二级页目录项
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回页表项的地址
}

// get_page - 使用页目录表pgdir获取线性地址la对应的Page结构
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页表项
    if (ptep_store != NULL) { // 如果ptep_store不为空
        *ptep_store = ptep; // 将页表项地址存储到ptep_store中
    }
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
        return pte2page(*ptep); // 返回页表项对应的Page结构
    }
    return NULL; // 返回NULL
}

// page_remove_pte - 释放与线性地址la相关的Page结构
//                - 并清除（使无效）与线性地址la相关的页表项
// 注意: 页表已更改，因此需要使TLB无效
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    if (*ptep & PTE_V) {  //(1) 检查该页表项是否有效
        struct Page *page =
            pte2page(*ptep);  //(2) 找到与页表项对应的页
        page_ref_dec(page);   //(3) 减少页的引用计数
        if (page_ref(page) ==
            0) {  //(4) 如果页的引用计数为0，则释放该页
            free_page(page);
        }
        *ptep = 0;                  //(5) 清除二级页表项
        tlb_invalidate(pgdir, la);  //(6) 刷新TLB
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内

    do {
        pte_t *ptep = get_pte(pgdir, start, 0); // 获取页表项指针
        if (ptep == NULL) { // 如果页表项指针为空
            start = ROUNDDOWN(start + PTSIZE, PTSIZE); // 将起始地址向下取整到页表大小的整数倍
            continue; // 继续下一次循环
        }
        if (*ptep != 0) { // 如果页表项不为空
            page_remove_pte(pgdir, start, ptep); // 移除页表项
        }
        start += PGSIZE; // 增加起始地址，移动到下一页
    } while (start != 0 && start < end); // 循环直到起始地址为0或大于结束地址
}

void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内

    uintptr_t d1start, d0start; // 定义一级页目录和二级页目录的起始地址
    int free_pt, free_pd0; // 定义是否释放页表和页目录的标志
    pde_t *pd0, *pt, pde1, pde0; // 定义页目录和页表指针
    d1start = ROUNDDOWN(start, PDSIZE); // 将起始地址向下取整到页目录大小的整数倍
    d0start = ROUNDDOWN(start, PTSIZE); // 将起始地址向下取整到页表大小的整数倍
    do {
        // 一级页目录项
        pde1 = pgdir[PDX1(d1start)]; // 获取一级页目录项
        // 如果一级页目录项有效，进入二级页目录
        // 尝试释放所有有效的二级页目录项指向的页表
        // 然后尝试释放这个二级页目录并更新一级页目录项
        if (pde1 & PTE_V) { // 如果一级页目录项有效
            pd0 = page2kva(pde2page(pde1)); // 获取二级页目录的虚拟地址
            // 尝试释放所有页表
            free_pd0 = 1; // 设置释放二级页目录的标志
            do {
                pde0 = pd0[PDX0(d0start)]; // 获取二级页目录项
                if (pde0 & PTE_V) { // 如果二级页目录项有效
                    pt = page2kva(pde2page(pde0)); // 获取页表的虚拟地址
                    // 尝试释放页表
                    free_pt = 1; // 设置释放页表的标志
                    for (int i = 0; i < NPTEENTRY; i++) // 遍历页表项
                        if (pt[i] & PTE_V) { // 如果页表项有效
                            free_pt = 0; // 取消释放页表的标志
                            break; // 跳出循环
                        }
                    // 只有当所有页表项都无效时才释放页表
                    if (free_pt) { // 如果可以释放页表
                        free_page(pde2page(pde0)); // 释放页表
                        pd0[PDX0(d0start)] = 0; // 清除二级页目录项
                    }
                } else
                    free_pd0 = 0; // 取消释放二级页目录的标志
                d0start += PTSIZE; // 增加二级页目录的起始地址，移动到下一个页表
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end); // 循环直到二级页目录的起始地址为0或大于一级页目录的结束地址或大于结束地址
            // 只有当所有二级页目录项都无效时才释放二级页目录
            if (free_pd0) { // 如果可以释放二级页目录
                free_page(pde2page(pde1)); // 释放二级页目录
                pgdir[PDX1(d1start)] = 0; // 清除一级页目录项
            }
        }
        d1start += PDSIZE; // 增加一级页目录的起始地址，移动到下一个二级页目录
        d0start = d1start; // 将二级页目录的起始地址设置为一级页目录的起始地址
    } while (d1start != 0 && d1start < end); // 循环直到一级页目录的起始地址为0或大于结束地址
}
/* copy_range - 将一个进程A的内存（start, end）内容复制到另一个进程B
 * @to:    进程B的页目录地址
 * @from:  进程A的页目录地址
 * @share: 标志指示是复制还是共享。我们只使用复制方法，所以它没有被使用。
 *
 * 调用图：copy_mm-->dup_mmap-->copy_range
 */
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0); // 确认起始地址和结束地址是页大小的整数倍
    assert(USER_ACCESS(start, end)); // 确认起始地址和结束地址在用户访问范围内
    // 按页单位复制内容。
    do {
        // 调用get_pte根据起始地址找到进程A的页表项
        pte_t *ptep = get_pte(from, start, 0), *nptep; // 获取进程A的页表项
        if (ptep == NULL) { // 如果页表项为空
            start = ROUNDDOWN(start + PTSIZE, PTSIZE); // 将起始地址向下取整到页表大小的整数倍
            continue; // 继续下一次循环
        }
        // 调用get_pte根据起始地址找到进程B的页表项。如果页表项为空，则分配一个页表
        if (*ptep & PTE_V) { // 如果页表项有效
            if ((nptep = get_pte(to, start, 1)) == NULL) { // 获取进程B的页表项，如果为空则分配一个页表
                return -E_NO_MEM; // 返回内存不足错误
            }
            uint32_t perm = (*ptep & PTE_USER); // 获取页表项的权限
            // 从页表项获取页
            struct Page *page = pte2page(*ptep); // 获取页表项对应的页
            // 为进程B分配一个页
            struct Page *npage = alloc_page(); // 分配一个页
            assert(page != NULL); // 确认页不为空
            assert(npage != NULL); // 确认新页不为空
            int ret = 0; // 定义返回值变量
            /* LAB5:EXERCISE2 你的代码
             * 复制页的内容到新页，建立新页的物理地址与线性地址start的映射
             *
             * 一些有用的宏和定义，你可以在下面的实现中使用它们。
             * 宏或函数：
             *    page2kva(struct Page *page): 返回页管理的内存的内核虚拟地址（见pmm.h）
             *    page_insert: 建立页的物理地址与线性地址la的映射
             *    memcpy: 典型的内存复制函数
             *
             * (1) 找到src_kvaddr：页的内核虚拟地址
             * (2) 找到dst_kvaddr：新页的内核虚拟地址
             * (3) 从src_kvaddr复制内存到dst_kvaddr，大小为PGSIZE
             * (4) 建立新页的物理地址与线性地址start的映射
             */
            uintptr_t* src = page2kva(page); // 获取页的内核虚拟地址
            uintptr_t* dst = page2kva(npage); // 获取新页的内核虚拟地址
            memcpy(dst, src, PGSIZE); // 从src复制内存到dst，大小为PGSIZE
            ret = page_insert(to, npage, start, perm); // 建立新页的物理地址与线性地址start的映射

            assert(ret == 0); // 确认返回值为0
        }
        start += PGSIZE; // 增加起始地址，移动到下一页
    } while (start != 0 && start < end); // 循环直到起始地址为0或大于结束地址
    return 0; // 返回0
}

// page_remove - 释放与线性地址la相关的页并使页表项无效
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页表项
    if (ptep != NULL) { // 如果页表项不为空
        page_remove_pte(pgdir, la, ptep); // 移除页表项
    }
}

// page_insert - 建立一个Page的物理地址与线性地址la的映射
// 参数:
//  pgdir: 页目录表的内核虚拟基地址
//  page:  需要映射的Page
//  la:    需要映射的线性地址
//  perm:  该Page的权限，将设置在相关的页表项中
// 返回值: 总是返回0
// 注意: 页表已更改，因此需要使TLB无效
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项指针，如果不存在则创建
    if (ptep == NULL) { // 如果页表项指针为空
        return -E_NO_MEM; // 返回内存不足错误
    }
    page_ref_inc(page); // 增加页的引用计数
    if (*ptep & PTE_V) { // 如果页表项有效
        struct Page *p = pte2page(*ptep); // 获取页表项对应的页
        if (p == page) { // 如果页表项对应的页与当前页相同
            page_ref_dec(page); // 减少页的引用计数
        } else {
            page_remove_pte(pgdir, la, ptep); // 移除页表项
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 创建页表项
    tlb_invalidate(pgdir, la); // 使TLB无效
    return 0; // 返回0
}

// 使TLB条目无效，但仅当正在编辑的页表是处理器当前使用的页表时
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令使TLB无效
}

// pgdir_alloc_page - 调用alloc_page和page_insert函数
//                  - 分配一个页大小的内存并设置地址映射
//                  - pa<->la与线性地址la和页目录表pgdir
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page(); // 分配一个页
    if (page != NULL) { // 如果页不为空
        if (page_insert(pgdir, page, la, perm) != 0) { // 插入页表项失败
            free_page(page); // 释放页
            return NULL; // 返回NULL
        }
        if (swap_init_ok) { // 如果交换初始化成功
            if (check_mm_struct != NULL) { // 如果check_mm_struct不为空
                swap_map_swappable(check_mm_struct, la, page, 0); // 将页标记为可交换
                page->pra_vaddr = la; // 设置页的虚拟地址
                assert(page_ref(page) == 1); // 确认页的引用计数为1
                // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
                // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
                // page->pra_vaddr,page->pra_page_link.prev,
                // page->pra_page_link.next);
            } else {  // 现在current存在，将来应该修复它
                // swap_map_swappable(current->mm, la, page, 0);
                // page->pra_vaddr=la;
                // assert(page_ref(page) == 1);
                // panic("pgdir_alloc_page: no pages. now current is existed,
                // should fix it in the future\n");
            }
        }
    }

    return page; // 返回分配的页
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

static void check_pgdir(void) {
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert(page_ref(p1) == 1);

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);

    p2 = alloc_page();
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(boot_pgdir[0] & PTE_U);
    assert(page_ref(p2) == 1);

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);

    page_remove(boot_pgdir, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);

    page_remove(boot_pgdir, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
    flush_tlb();

    assert(nr_free_store==nr_free_pages());

    cprintf("check_pgdir() succeeded!\n");
}

static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }


    assert(boot_pgdir[0] == 0);

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 1);
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 2);

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);

    *(char *)(page2kva(p) + 0x100) = '\0';
    assert(strlen((const char *)0x100) == 0);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
    flush_tlb();

    assert(nr_free_store==nr_free_pages());

    cprintf("check_boot_pgdir() succeeded!\n");
}

// perm2str - 使用字符串 'u,r,w,-' 表示权限
static const char *perm2str(int perm) {
    static char str[4]; // 定义一个静态字符数组用于存储权限字符串
    str[0] = (perm & PTE_U) ? 'u' : '-'; // 如果权限包含PTE_U，则设置为'u'，否则设置为'-'
    str[1] = 'r'; // 设置为'r'
    str[2] = (perm & PTE_W) ? 'w' : '-'; // 如果权限包含PTE_W，则设置为'w'，否则设置为'-'
    str[3] = '\0'; // 设置字符串结束符
    return str; // 返回权限字符串
}

// get_pgtable_items - 在PDT或PT的[left, right]范围内，找到连续的线性地址空间
//                  - (left_store*X_SIZE~right_store*X_SIZE) 对于PDT或PT
//                  - 如果是PDT，X_SIZE=PTSIZE=4M；如果是PT，X_SIZE=PGSIZE=4K
// 参数:
//  left:        未使用 ???
//  right:       表的范围的高端
//  start:       表的范围的低端
//  table:       表的起始地址
//  left_store:  表的下一个范围的高端指针
//  right_store: 表的下一个范围的低端指针
// 返回值: 0 - 无效的项范围，perm - 有效的项范围，具有perm权限
static int get_pgtable_items(size_t left, size_t right, size_t start,
                             uintptr_t *table, size_t *left_store,
                             size_t *right_store) {
    if (start >= right) { // 如果起始地址大于等于结束地址
        return 0; // 返回0，表示无效的项范围
    }
    while (start < right && !(table[start] & PTE_V)) { // 当起始地址小于结束地址且表项无效时
        start++; // 增加起始地址
    }
    if (start < right) { // 如果起始地址小于结束地址
        if (left_store != NULL) { // 如果left_store不为空
            *left_store = start; // 将起始地址存储到left_store中
        }
        int perm = (table[start++] & PTE_USER); // 获取表项的权限，并增加起始地址
        while (start < right && (table[start] & PTE_USER) == perm) { // 当起始地址小于结束地址且表项权限相同时
            start++; // 增加起始地址
        }
        if (right_store != NULL) { // 如果right_store不为空
            *right_store = start; // 将起始地址存储到right_store中
        }
        return perm; // 返回权限
    }
    return 0; // 返回0，表示无效的项范围
}
