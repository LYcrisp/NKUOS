
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

// 虚拟地址对应的物理页数组
struct Page *pages;
// 物理内存的页数
size_t npage = 0;
// 内核映像在VA=KERNBASE和PA=info.base处映射
uint_t va_pa_offset;
// 在RISC-V中，内存从0x80000000开始
const size_t nbase = DRAM_BASE / PGSIZE;

// 内核引导时的页目录的虚拟地址
pde_t *boot_pgdir = NULL;
// 内核引导时的页目录的物理地址
uintptr_t boot_cr3;

// 物理内存管理器
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);

// 初始化物理内存管理器
static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// 初始化物理内存中的空闲页
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// 分配连续的n个物理页
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        local_intr_save(intr_flag); // 关闭中断
        {
            page = pmm_manager->alloc_pages(n); // 分配页
        }
        local_intr_restore(intr_flag); // 恢复中断

        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0); // 交换出去
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}

// 释放连续的n个物理页
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// 获取当前空闲物理页的数量
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

/* 初始化物理内存管理 */
static void page_init(void) {
    extern char kern_entry[];

    va_pa_offset = KERNBASE - 0x80200000; // 计算虚拟地址和物理地址的偏移

    uint_t mem_begin = KERNEL_BEGIN_PADDR;
    uint_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint_t mem_end = PHYSICAL_MEMORY_END;

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);

    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
    // BBL已经将初始的页表放在内核之后的第一个可用页面
    // 因此，需要通过将end添加额外的偏移量来远离它
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));

    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    if (freemem < mem_end) {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
    cprintf("vapaofset is %llu\n",va_pa_offset);
}

// 使能分页机制
static void enable_paging(void) {
    write_csr(satp, 0x8000000000000000 | (boot_cr3 >> RISCV_PGSHIFT));
}

// 建立内核引导时的内存映射
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) {
        pte_t *ptep = get_pte(pgdir, la, 1); // 获取PTE
        assert(ptep != NULL);
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm); // 设置PTE
    }
}

// 分配一个物理页，用于内核引导
static void *boot_alloc_page(void) {
    struct Page *p = alloc_page();
    if (p == NULL) {
        panic("boot_alloc_page failed.\n");
    }
    return page2kva(p); // 返回内核虚拟地址
}

// 物理内存管理的初始化
void pmm_init(void) {
    // 初始化物理内存管理器
    init_pmm_manager();

    // 检测物理内存空间，保留已使用的内存，然后使用pmm->init_memmap创建空闲页列表
    page_init();

    // 使用pmm->check验证pmm中alloc/free函数的正确性
    check_alloc_page();

    // 创建boot_pgdir，一个初始的页目录表
    extern char boot_page_table_sv39[];
    boot_pgdir = (pte_t*)boot_page_table_sv39;
    boot_cr3 = PADDR(boot_pgdir);

    check_pgdir();

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // 检查基本的虚拟内存映射的正确性
    check_boot_pgdir();

    kmalloc_init();
}

// 获取线性地址la对应的PTE的内核虚拟地址，如果不存在则根据create决定是否创建
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE); // 清空新页
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建PDE
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE); // 清空新页
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建PDE
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回PTE地址
}

// 获取线性地址la对应的Page结构
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep_store != NULL) {
        *ptep_store = ptep;
    }
    if (ptep != NULL && *ptep & PTE_V) {
        return pte2page(*ptep);
    }
    return NULL;
}

// 移除线性地址la对应的页映射，并释放Page结构
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    if (*ptep & PTE_V) {  // 检查PTE是否有效
        struct Page *page = pte2page(*ptep);  // 获取对应的Page
        page_ref_dec(page);   // 减少引用计数
        if (page_ref(page) == 0) {  // 如果引用计数为0，释放页面
            free_page(page);
        }
        *ptep = 0;                  // 清除PTE
        tlb_invalidate(pgdir, la);  // 刷新TLB
    }
}

// 移除线性地址la对应的页映射
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep != NULL) {
        page_remove_pte(pgdir, la, ptep);
    }
}

// 建立物理页page与线性地址la的映射关系
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    page_ref_inc(page); // 增加引用计数
    if (*ptep & PTE_V) {
        struct Page *p = pte2page(*ptep);
        if (p == page) {
            page_ref_dec(page); // 如果已经映射，减少多加的引用计数
        } else {
            page_remove_pte(pgdir, la, ptep); // 移除旧的映射
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 设置新的PTE
    tlb_invalidate(pgdir, la);
    return 0;
}

// 刷新TLB中的某个条目
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
}

// 分配一个物理页并建立映射
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page();
    if (page != NULL) {
        if (page_insert(pgdir, page, la, perm) != 0) {
            free_page(page);
            return NULL;
        }
        if (swap_init_ok) {
            swap_map_swappable(check_mm_struct, la, page, 0);
            page->pra_vaddr = la;
            assert(page_ref(page) == 1);
            // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
            // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
            // page->pra_vaddr,page->pra_page_link.prev,
            // page->pra_page_link.next);
        }
    }

    return page;
}

// 检查alloc_page和free_page函数的正确性
static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

// 检查页目录的正确性
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

// 检查内核引导时的页目录
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

// 将权限转换为字符串形式
static const char *perm2str(int perm) {
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
    str[1] = 'r';
    str[2] = (perm & PTE_W) ? 'w' : '-';
    str[3] = '\0';
    return str;
}

// 获取页表项，在[left, right]范围内查找连续的线性地址空间
static int get_pgtable_items(size_t left, size_t right, size_t start,
                             uintptr_t *table, size_t *left_store,
                             size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_V)) {
        start++;
    }
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
            start++;
        }
        if (right_store != NULL) {
            *right_store = start;
        }
        return perm;
    }
    return 0;
}
