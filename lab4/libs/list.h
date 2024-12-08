#ifndef __LIBS_LIST_H__ // 防止重复包含头文件的宏定义
#define __LIBS_LIST_H__ // 定义宏

#ifndef __ASSEMBLER__ // 如果不是汇编器

#include <defs.h> // 包含defs.h头文件

/* *
 * Simple doubly linked list implementation.
 * 简单的双向链表实现。
 *
 * Some of the internal functions ("__xxx") are useful when manipulating
 * whole lists rather than single entries, as sometimes we already know
 * the next/prev entries and we can generate better code by using them
 * directly rather than using the generic single-entry routines.
 * 一些内部函数（"__xxx"）在操作整个列表而不是单个条目时很有用，因为有时我们已经知道下一个/上一个条目，通过直接使用它们而不是使用通用的单条目例程可以生成更好的代码。
 * */

struct list_entry { // 定义链表节点结构体
    struct list_entry *prev, *next; // 指向前一个和后一个节点的指针
};

typedef struct list_entry list_entry_t; // 定义链表节点类型

static inline void list_init(list_entry_t *elm) __attribute__((always_inline)); // 初始化链表节点的函数声明
static inline void list_add(list_entry_t *listelm, list_entry_t *elm) __attribute__((always_inline)); // 添加节点到链表的函数声明
static inline void list_add_before(list_entry_t *listelm, list_entry_t *elm) __attribute__((always_inline)); // 在指定节点前添加节点的函数声明
static inline void list_add_after(list_entry_t *listelm, list_entry_t *elm) __attribute__((always_inline)); // 在指定节点后添加节点的函数声明
static inline void list_del(list_entry_t *listelm) __attribute__((always_inline)); // 删除链表节点的函数声明
static inline void list_del_init(list_entry_t *listelm) __attribute__((always_inline)); // 删除并重新初始化链表节点的函数声明
static inline bool list_empty(list_entry_t *list) __attribute__((always_inline)); // 判断链表是否为空的函数声明
static inline list_entry_t *list_next(list_entry_t *listelm) __attribute__((always_inline)); // 获取下一个节点的函数声明
static inline list_entry_t *list_prev(list_entry_t *listelm) __attribute__((always_inline)); // 获取前一个节点的函数声明

static inline void __list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) __attribute__((always_inline)); // 内部使用的添加节点函数声明
static inline void __list_del(list_entry_t *prev, list_entry_t *next) __attribute__((always_inline)); // 内部使用的删除节点函数声明

/* *
 * list_init - initialize a new entry
 * 初始化一个新的链表节点
 * @elm:        new entry to be initialized
 * 新的链表节点
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm; // 将节点的前后指针都指向自己
}

/* *
 * list_add - add a new entry
 * 添加一个新的链表节点
 * @listelm:    list head to add after
 * 要添加到其后的链表头
 * @elm:        new entry to be added
 * 要添加的新节点
 *
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * 将新节点@elm插入到已经在链表中的节点@listelm之后
 * */
static inline void
list_add(list_entry_t *listelm, list_entry_t *elm) {
    list_add_after(listelm, elm); // 调用list_add_after函数
}

/* *
 * list_add_before - add a new entry
 * 在指定节点前添加一个新的链表节点
 * @listelm:    list head to add before
 * 要添加到其前的链表头
 * @elm:        new entry to be added
 * 要添加的新节点
 *
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * 将新节点@elm插入到已经在链表中的节点@listelm之前
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm); // 调用__list_add函数
}

/* *
 * list_add_after - add a new entry
 * 在指定节点后添加一个新的链表节点
 * @listelm:    list head to add after
 * 要添加到其后的链表头
 * @elm:        new entry to be added
 * 要添加的新节点
 *
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * 将新节点@elm插入到已经在链表中的节点@listelm之后
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next); // 调用__list_add函数
}

/* *
 * list_del - deletes entry from list
 * 从链表中删除节点
 * @listelm:    the element to delete from the list
 * 要从链表中删除的节点
 *
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * 注意：在此之后对@listelm调用list_empty()不会返回true，该节点处于未定义状态。
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next); // 调用__list_del函数
}

/* *
 * list_del_init - deletes entry from list and reinitialize it.
 * 从链表中删除节点并重新初始化
 * @listelm:    the element to delete from the list.
 * 要从链表中删除的节点
 *
 * Note: list_empty() on @listelm returns true after this.
 * 注意：在此之后对@listelm调用list_empty()会返回true。
 * */
static inline void
list_del_init(list_entry_t *listelm) {
    list_del(listelm); // 调用list_del函数
    list_init(listelm); // 调用list_init函数
}

/* *
 * list_empty - tests whether a list is empty
 * 测试链表是否为空
 * @list:       the list to test.
 * 要测试的链表
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list; // 判断链表的下一个节点是否是自己
}

/* *
 * list_next - get the next entry
 * 获取下一个节点
 * @listelm:    the list head
 * 链表头
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next; // 返回下一个节点
}

/* *
 * list_prev - get the previous entry
 * 获取前一个节点
 * @listelm:    the list head
 * 链表头
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev; // 返回前一个节点
}

/* *
 * Insert a new entry between two known consecutive entries.
 * 在两个已知的连续节点之间插入一个新节点
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * 这仅用于我们已经知道前/后节点的内部链表操作！
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm; // 将前一个节点的下一个指针和后一个节点的前一个指针指向新节点
    elm->next = next; // 将新节点的下一个指针指向后一个节点
    elm->prev = prev; // 将新节点的前一个指针指向前一个节点
}

/* *
 * Delete a list entry by making the prev/next entries point to each other.
 * 通过使前/后节点相互指向来删除链表节点
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * 这仅用于我们已经知道前/后节点的内部链表操作！
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next; // 将前一个节点的下一个指针指向后一个节点
    next->prev = prev; // 将后一个节点的前一个指针指向前一个节点
}

#endif /* !__ASSEMBLER__ */ // 结束非汇编器部分

#endif /* !__LIBS_LIST_H__ */ // 结束防止重复包含头文件的宏定义
