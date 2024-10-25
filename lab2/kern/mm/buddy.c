#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy.h>

free_area_t free_area;

#define free_list (free_area.free_list)  // 空闲链表
#define nr_free (free_area.nr_free)       // 空闲页数

static size_t total_size;          // 物理区域的总大小
static size_t full_tree_size;      // 完整二叉树的大小
static size_t record_area_size;    // 用于记录节点信息的页大小
static size_t real_tree_size;      // 实际分配的页大小
static size_t *record_area;        // 记录页的头指针
static struct Page *physical_area; // 内存的头指针
static struct Page *allocate_area; // 用于分配的内存头指针

#define TREE_ROOT (1)                           // 树的根节点
#define LEFT_CHILD(a) ((a) << 1)                // 左子节点
#define RIGHT_CHILD(a) (((a) << 1) + 1)         // 右子节点
#define PARENT(a) ((a) >> 1)                    // 父节点
#define NODE_LENGTH(a) (full_tree_size / POWER_ROUND_DOWN(a)) // 节点的长度
#define BUDDY_BLOCK(a, b) (full_tree_size / ((b) - (a)) + (a) / ((b) - (a))) // 根据地址获取节点索引
#define BUDDY_EMPTY(a) (record_area[(a)] == NODE_LENGTH(a)) // 判断节点是否为空

#define NODE_BEGINNING(a) (POWER_REMAINDER(a) * NODE_LENGTH(a)) // 节点的起始地址
#define NODE_ENDDING(a) ((POWER_REMAINDER(a) + 1) * NODE_LENGTH(a)) // 节点的结束地址

#define OR_SHIFT_RIGHT(a, n) ((a) | ((a) >> (n))) // 右移并或操作
#define ALL_BIT_TO_ONE(a) (OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(a, 1), 2), 4), 8), 16)) // 全部位设置为1
#define POWER_REMAINDER(a) ((a) & (ALL_BIT_TO_ONE(a) >> 1)) // 计算幂的余数
#define POWER_ROUND_DOWN(a) (POWER_REMAINDER(a) ? ((a)-POWER_REMAINDER(a)) : (a)) // 向下取整
#define POWER_ROUND_UP(a) (POWER_REMAINDER(a) ? (((a)-POWER_REMAINDER(a)) << 1) : (a)) // 向上取整


static void buddy_init(void)
{
    list_init(&free_list);
    nr_free = 0;
}

#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy.h>

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static size_t total_size;          // 物理区域的总大小
static size_t full_tree_size;      // 完全二叉树的大小
static size_t record_area_size;    // 记录节点信息的页面大小
static size_t real_tree_size;      // 实际分配的页面大小
static size_t *record_area;        // 记录页面的头指针
static struct Page *physical_area; // 物理内存的头指针
static struct Page *allocate_area; // 待分配内存的头指针

// 初始化单个页面
static void initialize_page(struct Page *p) {
    assert(PageReserved(p)); // 确保页面是保留状态
    p->flags = p->property = 0; // 清除标志和属性
}

// 计算完全二叉树的大小
static size_t calculate_full_tree_size(size_t n) {
    if (n < 512) {
        return POWER_ROUND_UP(n - 1); // 小于512时，向上取整
    } else {
        return POWER_ROUND_DOWN(n); // 大于等于512时，向下取整
    }
}

// 计算记录区域的大小
static size_t calculate_record_area_size(size_t full_tree_size, size_t n) {
    size_t record_area_size = full_tree_size * sizeof(size_t) * 2 / PGSIZE; // 根据树的大小计算记录区域
    if (n > full_tree_size + (record_area_size << 1)) { // 判断是否需要扩大树的大小
        full_tree_size <<= 1; // 扩大树的大小
        record_area_size <<= 1; // 同时扩大记录区域的大小
    }
    return record_area_size; // 返回记录区域的大小
}

// 初始化记录区域
static void initialize_record_area(size_t *record_area, size_t real_subtree_size, size_t block) {
    record_area[block] = real_subtree_size; // 将实际子树大小记录在树的根节点
}

// 拆分区块
static void split_block(size_t *record_area, struct Page *allocate_area, size_t *real_subtree_size, 
                        size_t full_subtree_size, size_t *block) {
    struct Page *page = &allocate_area[NODE_BEGINNING(*block)]; // 获取当前节点的页面
    page->property = full_subtree_size; // 设置页面的属性为当前子树的大小
    list_add(&(free_list), &(page->page_link)); // 将页面添加到空闲列表
    set_page_ref(page, 0); // 设置页面引用计数为0
    SetPageProperty(page); // 设置页面的属性标志
    
    record_area[LEFT_CHILD(*block)] = full_subtree_size; // 更新左子节点的记录
    *real_subtree_size -= full_subtree_size; // 减少实际子树的大小
    record_area[RIGHT_CHILD(*block)] = *real_subtree_size; // 更新右子节点的记录
    *block = RIGHT_CHILD(*block); // 移动到右子节点
}

// 完成区块的最终设置
static void finalize_block(size_t *record_area, struct Page *allocate_area, 
                            size_t real_subtree_size, size_t block) {
    struct Page *page = &allocate_area[NODE_BEGINNING(block)]; // 获取当前节点的页面
    page->property = real_subtree_size; // 设置页面的属性为剩余的实际子树大小
    set_page_ref(page, 0); // 设置页面引用计数为0
    SetPageProperty(page); // 设置页面的属性标志
    list_add(&(free_list), &(page->page_link)); // 将页面添加到空闲列表
}

// 初始化内存映射
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0); // 确保传入的页面数大于0
    for (struct Page *p = base; p < base + n; p++) {
        initialize_page(p); // 初始化每个页面
    }
    
    total_size = n; // 记录物理内存的总大小
    full_tree_size = calculate_full_tree_size(n); // 计算完全二叉树的大小
    record_area_size = calculate_record_area_size(full_tree_size, n); // 计算记录区域的大小

    // 确定实际树的大小
    real_tree_size = (full_tree_size < total_size - record_area_size) ? full_tree_size : total_size - record_area_size;

    physical_area = base; // 设置物理区域的起始地址
    record_area = KADDR(page2pa(base)); // 获取记录区域的地址
    allocate_area = base + record_area_size; // 设置待分配区域的起始地址
    memset(record_area, 0, record_area_size * PGSIZE); // 清空记录区域

    nr_free += real_tree_size; // 更新可用页面数量

    size_t block = TREE_ROOT; // 初始化为树的根节点
    size_t real_subtree_size = real_tree_size; // 实际子树的大小
    size_t full_subtree_size = full_tree_size; // 完全子树的大小

    initialize_record_area(record_area, real_subtree_size, block); // 初始化记录区域
    
    while (real_subtree_size > 0 && real_subtree_size < full_subtree_size) {
        full_subtree_size >>= 1; // 将完全子树大小右移一位，减半
        if (real_subtree_size > full_subtree_size) { // 如果实际子树大小大于完全子树大小
            split_block(record_area, allocate_area, &real_subtree_size, full_subtree_size, &block); // 拆分区块
        } else {
            record_area[LEFT_CHILD(block)] = real_subtree_size; // 更新左子节点的记录
            record_area[RIGHT_CHILD(block)] = 0; // 右子节点为空
            block = LEFT_CHILD(block); // 移动到左子节点
        }
    }

    if (real_subtree_size > 0) { // 如果仍有剩余的实际子树大小
        finalize_block(record_area, allocate_area, real_subtree_size, block); // 完成最后一个区块的设置
    }
}


static struct Page *buddy_allocate_pages(size_t n) {
    assert(n > 0); // 确保请求的页面数大于0
    struct Page *page;
    size_t block = TREE_ROOT; // 初始化为树的根节点
    size_t length = POWER_ROUND_UP(n); // 将请求的页面数向上取整到最接近的2的幂

    // 查找适合的空闲块
    while (length <= record_area[block] && length < NODE_LENGTH(block)) {
        size_t left = LEFT_CHILD(block); // 获取左子节点索引
        size_t right = RIGHT_CHILD(block); // 获取右子节点索引

        if (BUDDY_EMPTY(block)) { // 如果当前块是空的
            size_t begin = NODE_BEGINNING(block); // 获取当前节点的起始地址
            size_t end = NODE_ENDDING(block); // 获取当前节点的结束地址
            size_t mid = (begin + end) >> 1; // 计算中间地址

            // 从空闲列表中删除当前块并更新其属性
            list_del(&(allocate_area[begin].page_link));
            allocate_area[begin].property >>= 1; // 将属性右移一位，表示分割
            allocate_area[mid].property = allocate_area[begin].property; // 复制属性到中间节点
            
            // 更新记录区域
            record_area[left] = record_area[block] >> 1; // 更新左子节点的记录
            record_area[right] = record_area[block] >> 1; // 更新右子节点的记录
            
            // 将当前块和中间块加入空闲列表
            list_add(&free_list, &(allocate_area[begin].page_link));
            list_add(&free_list, &(allocate_area[mid].page_link));
            block = left; // 移动到左子节点
        } 
        else if (length & record_area[left]) { // 如果请求长度在左子块内
            block = left; // 移动到左子节点
        } 
        else if (length & record_area[right]) { // 如果请求长度在右子块内
            block = right; // 移动到右子节点
        } 
        else if (length <= record_area[left]) { // 如果请求长度小于等于左子块
            block = left; // 移动到左子节点
        } 
        else if (length <= record_area[right]) { // 如果请求长度小于等于右子块
            block = right; // 移动到右子节点
        }
    }

    // 如果所需长度大于记录中的大小，返回NULL
    if (length > record_area[block]) {
        return NULL; // 找不到合适的块，返回空
    }

    // 获取要分配的页面
    page = &(allocate_area[NODE_BEGINNING(block)]); // 获取要分配的页面
    list_del(&(page->page_link)); // 从空闲列表中删除该页面
    record_area[block] = 0; // 更新记录区域，表示该块已被分配
    nr_free -= length; // 减少空闲页面的数量

    // 更新父节点的记录区域
    while (block != TREE_ROOT) {
        block = PARENT(block); // 移动到父节点
        record_area[block] = record_area[LEFT_CHILD(block)] | record_area[RIGHT_CHILD(block)]; // 更新父节点的记录
    }

    return page; // 返回分配的页面
}


static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0); // 确保释放的页面数大于0
    struct Page *p = base; // 从基地址开始
    size_t length = POWER_ROUND_UP(n); // 将释放的页面数向上取整到最接近的2的幂
    size_t begin = (base - allocate_area); // 计算基地址在分配区域中的偏移
    size_t end = begin + length; // 计算结束偏移
    size_t block = BUDDY_BLOCK(begin, end); // 获取对应的块索引

    // 清理页面的状态并设置引用计数
    for (; p != base + n; p++) {
        assert(!PageReserved(p)); // 确保页面未被保留
        p->flags = 0; // 清除页面标志
        set_page_ref(p, 0); // 设置页面引用计数为0
    }

    // 更新基础页面的属性和空闲列表
    base->property = length; // 设置属性为释放的长度
    list_add(&free_list, &(base->page_link)); // 将页面添加到空闲列表
    nr_free += length; // 增加空闲页面计数
    record_area[block] = length; // 更新记录区域

    // 向上更新父节点的记录区域
    while (block != TREE_ROOT) {
        block = PARENT(block); // 移动到父节点
        size_t left = LEFT_CHILD(block); // 获取左子节点索引
        size_t right = RIGHT_CHILD(block); // 获取右子节点索引

        if (BUDDY_EMPTY(left) && BUDDY_EMPTY(right)) { // 如果左右子节点均为空
            size_t lbegin = NODE_BEGINNING(left); // 获取左子节点的起始地址
            size_t rbegin = NODE_BEGINNING(right); // 获取右子节点的起始地址
            
            // 从空闲列表中删除左右子节点
            list_del(&(allocate_area[lbegin].page_link));
            list_del(&(allocate_area[rbegin].page_link));

            // 更新父节点的记录区域和属性
            record_area[block] = record_area[left] << 1; // 更新父节点的记录
            allocate_area[lbegin].property = record_area[left] << 1; // 更新左子节点的属性
            list_add(&free_list, &(allocate_area[lbegin].page_link)); // 将左子节点重新加入空闲列表
        } else {
            // 如果有一个或两个子节点不为空，则更新父节点的记录区域
            record_area[block] = record_area[LEFT_CHILD(block)] | record_area[RIGHT_CHILD(block)];
        }
    }
}

static size_t
buddy_nr_free_pages(void)
{
    return nr_free;
}

static void alloc_check(void) {
    size_t total_size_store = total_size; // 保存总物理内存大小
    struct Page *p;

    // 标记前1026个页面为保留状态
    for (p = physical_area; p < physical_area + 1026; p++)
        SetPageReserved(p);

    // 初始化伙伴系统
    buddy_init();
    buddy_init_memmap(physical_area, 1026);

    struct Page *p0, *p1, *p2, *p3;
    p0 = p1 = p2 = p3 = NULL; // 初始化指针

    // 分配四个页面，确保分配成功
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    assert((p3 = alloc_page()) != NULL);

    // 确保分配的页面是连续的
    assert(p0 + 1 == p1);
    assert(p1 + 1 == p2);
    assert(p2 + 1 == p3);

    // 确保页面的引用计数为0
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0 && page_ref(p3) == 0);

    // 确保页面的物理地址在有效范围内
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);
    assert(page2pa(p3) < npage * PGSIZE);

    // 遍历空闲列表，确保所有空闲页面都能分配成功
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        p = le2page(le, page_link); // 获取当前页面
        assert(buddy_allocate_pages(p->property) != NULL); // 确保分配成功
    }

    // 确保没有可用页面时分配失败
    assert(alloc_page() == NULL);

    // 释放已分配的页面
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3); // 确保空闲页面计数更新正确

    // 重新分配页面
    assert((p1 = alloc_page()) != NULL); // 重新分配一个页面
    assert((p0 = alloc_pages(2)) != NULL); // 重新分配两个页面
    assert(p0 + 2 == p1); // 确保p0和p1是连续的

    assert(alloc_page() == NULL); // 确保没有可用页面时分配失败

    // 释放页面
    free_pages(p0, 2);
    free_page(p1);
    free_page(p3);

    // 重新分配四个页面
    assert((p = alloc_pages(4)) == p0); // 确保分配的地址正确
    assert(alloc_page() == NULL); // 确保没有可用页面时分配失败

    assert(nr_free == 0); // 确保所有页面都已分配

    // 将所有页面标记为保留状态，重新初始化伙伴系统
    for (p = physical_area; p < physical_area + total_size_store; p++)
        SetPageReserved(p);
    buddy_init();
    buddy_init_memmap(physical_area, total_size_store); // 重新初始化内存映射
}


const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_allocate_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = alloc_check,
};
