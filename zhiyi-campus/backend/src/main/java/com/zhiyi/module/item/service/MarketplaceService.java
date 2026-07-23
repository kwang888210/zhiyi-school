package com.zhiyi.module.item.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.item.entity.Category;
import com.zhiyi.module.item.entity.Item;
import com.zhiyi.module.item.mapper.CategoryMapper;
import com.zhiyi.module.item.mapper.ItemMapper;
import com.zhiyi.module.item.vo.AiTagTrendVO;
import com.zhiyi.module.item.vo.FavoriteToggleVO;
import com.zhiyi.module.item.vo.ItemCardVO;
import com.zhiyi.module.social.entity.ItemFavorite;
import com.zhiyi.module.social.mapper.ItemFavoriteMapper;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import com.zhiyi.module.user.support.LevelRule;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 模块三：商品大厅、搜索筛选、收藏与排行榜。
 */
@Service
@RequiredArgsConstructor
public class MarketplaceService {

    private static final int MAX_PAGE_SIZE = 50;

    private final ItemMapper itemMapper;
    private final CategoryMapper categoryMapper;
    private final ItemFavoriteMapper favoriteMapper;
    private final SysUserMapper userMapper;
    private final ObjectMapper objectMapper;

    public List<Category> listCategories() {
        return categoryMapper.selectList(new LambdaQueryWrapper<Category>()
                .orderByAsc(Category::getSortOrder)
                .orderByAsc(Category::getId));
    }

    public IPage<ItemCardVO> listOnSaleItems(String keyword,
                                            Long categoryId,
                                            BigDecimal minPrice,
                                            BigDecimal maxPrice,
                                            String sort,
                                            String type,
                                            int page,
                                            int size,
                                            Long currentUserId) {
        Page<Item> itemPage = itemMapper.selectPage(
                new Page<>(Math.max(page, 1), normalizeSize(size)),
                buildOnSaleWrapper(keyword, categoryId, minPrice, maxPrice, sort, type)
        );

        Page<ItemCardVO> result = new Page<>(itemPage.getCurrent(), itemPage.getSize(), itemPage.getTotal());
        result.setRecords(toItemCards(itemPage.getRecords(), currentUserId));
        return result;
    }

    public ItemCardVO getDetail(Long itemId, Long currentUserId) {
        Item item = itemMapper.selectById(itemId);
        if (item == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "商品不存在");
        }
        itemMapper.update(null, new LambdaUpdateWrapper<Item>()
                .eq(Item::getId, itemId)
                .setSql("view_count = view_count + 1")
                .set(Item::getUpdatedAt, LocalDateTime.now()));
        item.setViewCount((item.getViewCount() == null ? 0 : item.getViewCount()) + 1);
        return toItemCards(List.of(item), currentUserId).get(0);
    }

    public ItemCardVO getSnapshot(Long itemId, Long currentUserId) {
        Item item = itemMapper.selectById(itemId);
        if (item == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "商品不存在");
        }
        return toItemCards(List.of(item), currentUserId).get(0);
    }

    public ItemCardVO getOwnItem(Long userId, Long itemId) {
        Item item = requireOwnItem(userId, itemId);
        return toItemCards(List.of(item), userId).get(0);
    }

    @Transactional
    public FavoriteToggleVO toggleFavorite(Long userId, Long itemId) {
        Item item = itemMapper.selectById(itemId);
        if (item == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "商品不存在");
        }
        if (!"ON_SALE".equals(item.getStatus())) {
            throw new BusinessException(ResultCode.ITEM_NOT_ON_SALE);
        }
        if (Objects.equals(item.getPublisherId(), userId)) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "不能收藏自己发布的商品");
        }

        ItemFavorite existing = favoriteMapper.selectOne(new LambdaQueryWrapper<ItemFavorite>()
                .eq(ItemFavorite::getUserId, userId)
                .eq(ItemFavorite::getItemId, itemId)
                .last("LIMIT 1"));
        boolean favorite;
        if (existing != null) {
            favoriteMapper.deleteById(existing.getId());
            favorite = false;
        } else {
            ItemFavorite record = new ItemFavorite();
            record.setUserId(userId);
            record.setItemId(itemId);
            try {
                favoriteMapper.insert(record);
            } catch (DuplicateKeyException ignored) {
                // 并发重复点击时以“已收藏”状态返回。
            }
            favorite = true;
        }
        return new FavoriteToggleVO(itemId, favorite, favoriteCount(itemId));
    }

    public IPage<ItemCardVO> listMyFavorites(Long userId, int page, int size) {
        Page<ItemFavorite> favPage = favoriteMapper.selectPage(
                new Page<>(Math.max(page, 1), normalizeSize(size)),
                new LambdaQueryWrapper<ItemFavorite>()
                        .eq(ItemFavorite::getUserId, userId)
                        .orderByDesc(ItemFavorite::getCreatedAt));
        List<Long> itemIds = favPage.getRecords().stream()
                .map(ItemFavorite::getItemId)
                .toList();

        List<Item> items = itemIds.isEmpty() ? List.of() : itemMapper.selectBatchIds(itemIds);
        Map<Long, Item> itemById = items.stream().collect(Collectors.toMap(Item::getId, Function.identity()));
        List<Item> ordered = itemIds.stream()
                .map(itemById::get)
                .filter(Objects::nonNull)
                .toList();

        Page<ItemCardVO> result = new Page<>(favPage.getCurrent(), favPage.getSize(), favPage.getTotal());
        result.setRecords(toItemCards(ordered, userId));
        return result;
    }

    public IPage<ItemCardVO> listMyItems(Long userId, String status, int page, int size) {
        LambdaQueryWrapper<Item> wrapper = new LambdaQueryWrapper<Item>()
                .eq(Item::getPublisherId, userId)
                .orderByDesc(Item::getCreatedAt);
        if (StringUtils.hasText(status)) {
            wrapper.eq(Item::getStatus, status.trim());
        }

        Page<Item> itemPage = itemMapper.selectPage(
                new Page<>(Math.max(page, 1), normalizeSize(size)),
                wrapper);
        Page<ItemCardVO> result = new Page<>(itemPage.getCurrent(), itemPage.getSize(), itemPage.getTotal());
        result.setRecords(toItemCards(itemPage.getRecords(), userId));
        return result;
    }

    @Transactional
    public void offShelf(Long userId, Long itemId) {
        Item item = requireOwnItem(userId, itemId);
        if (!"ON_SALE".equals(item.getStatus())) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "只有在售商品可以下架");
        }
        updateStatus(itemId, "OFF_SHELF");
    }

    @Transactional
    public void deleteOwnItem(Long userId, Long itemId) {
        Item item = requireOwnItem(userId, itemId);
        if ("PENDING".equals(item.getStatus())) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "交易中的商品不能删除");
        }
        itemMapper.deleteById(itemId);
    }

    public List<ItemCardVO> ranking(int limit, Long currentUserId) {
        int safeLimit = Math.max(1, Math.min(limit, 20));
        List<Map<String, Object>> rows = favoriteMapper.selectMaps(new QueryWrapper<ItemFavorite>()
                .select("item_id", "COUNT(*) AS favorite_count")
                .groupBy("item_id")
                .orderByDesc("favorite_count")
                .last("LIMIT " + safeLimit * 3));

        Map<Long, Long> counts = new LinkedHashMap<>();
        for (Map<String, Object> row : rows) {
            counts.put(toLong(row.get("item_id")), toLong(row.get("favorite_count")));
        }

        List<Long> rankedIds = new ArrayList<>(counts.keySet());
        Map<Long, Item> itemMap = rankedIds.isEmpty()
                ? Map.of()
                : itemMapper.selectBatchIds(rankedIds).stream()
                .filter(item -> "ON_SALE".equals(item.getStatus()))
                .collect(Collectors.toMap(Item::getId, Function.identity()));

        List<Item> items = rankedIds.stream()
                .map(itemMap::get)
                .filter(Objects::nonNull)
                .limit(safeLimit)
                .collect(Collectors.toCollection(ArrayList::new));

        if (items.size() < safeLimit) {
            LambdaQueryWrapper<Item> fillerWrapper = new LambdaQueryWrapper<Item>()
                    .eq(Item::getStatus, "ON_SALE")
                    .orderByDesc(Item::getCreatedAt)
                    .last("LIMIT " + (safeLimit - items.size()));
            if (!rankedIds.isEmpty()) {
                fillerWrapper.notIn(Item::getId, rankedIds);
            }
            items.addAll(itemMapper.selectList(fillerWrapper));
        }

        List<ItemCardVO> cards = toItemCards(items, currentUserId);
        for (ItemCardVO card : cards) {
            card.setFavoriteCount(counts.getOrDefault(card.getId(), 0L));
        }
        return cards;
    }

    public List<AiTagTrendVO> trendingAiTags(int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 10));
        List<Object> rawTagValues = itemMapper.selectObjs(new QueryWrapper<Item>()
                .select("ai_tags")
                .eq("status", "ON_SALE")
                .isNotNull("ai_tags"));

        Map<String, Long> frequencies = new HashMap<>();
        for (Object rawTagValue : rawTagValues) {
            Set<String> itemTags = parseJsonArray(String.valueOf(rawTagValue)).stream()
                    .map(String::trim)
                    .filter(StringUtils::hasText)
                    .filter(tag -> tag.length() <= 20)
                    .collect(Collectors.toSet());
            itemTags.forEach(tag -> frequencies.merge(tag, 1L, Long::sum));
        }

        return frequencies.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed()
                        .thenComparing(Map.Entry::getKey, String.CASE_INSENSITIVE_ORDER))
                .limit(safeLimit)
                .map(entry -> new AiTagTrendVO(entry.getKey(), entry.getValue()))
                .toList();
    }

    private LambdaQueryWrapper<Item> buildOnSaleWrapper(String keyword,
                                                       Long categoryId,
                                                       BigDecimal minPrice,
                                                       BigDecimal maxPrice,
                                                       String sort,
                                                       String type) {
        LambdaQueryWrapper<Item> wrapper = new LambdaQueryWrapper<Item>()
                .eq(Item::getStatus, "ON_SALE");
        if (StringUtils.hasText(keyword)) {
            String kw = keyword.trim();
            wrapper.and(w -> w.like(Item::getTitle, kw)
                    .or().like(Item::getAiTags, kw)
                    .or().like(Item::getDescription, kw));
        }
        if (categoryId != null) {
            wrapper.eq(Item::getCategoryId, categoryId);
        }
        if (minPrice != null) {
            wrapper.ge(Item::getPrice, minPrice);
        }
        if (maxPrice != null) {
            wrapper.le(Item::getPrice, maxPrice);
        }
        if (StringUtils.hasText(type)) {
            wrapper.eq(Item::getType, type.trim().toUpperCase());
        }
        applySort(wrapper, sort);
        return wrapper;
    }

    private void applySort(LambdaQueryWrapper<Item> wrapper, String sort) {
        String normalized = StringUtils.hasText(sort) ? sort.trim() : "random";
        switch (normalized) {
            case "priceAsc" -> wrapper.orderByAsc(Item::getPrice).orderByDesc(Item::getCreatedAt);
            case "priceDesc" -> wrapper.orderByDesc(Item::getPrice).orderByDesc(Item::getCreatedAt);
            case "latest" -> wrapper.orderByDesc(Item::getCreatedAt);
            case "views" -> wrapper.orderByDesc(Item::getViewCount).orderByDesc(Item::getCreatedAt);
            case "random" -> wrapper.last("ORDER BY RAND()");
            default -> wrapper.orderByDesc(Item::getCreatedAt);
        }
    }

    private List<ItemCardVO> toItemCards(List<Item> items, Long currentUserId) {
        if (items == null || items.isEmpty()) {
            return List.of();
        }
        Set<Long> categoryIds = items.stream().map(Item::getCategoryId).filter(Objects::nonNull).collect(Collectors.toSet());
        Set<Long> publisherIds = items.stream().map(Item::getPublisherId).filter(Objects::nonNull).collect(Collectors.toSet());
        Set<Long> itemIds = items.stream().map(Item::getId).collect(Collectors.toCollection(HashSet::new));

        Map<Long, Category> categories = selectCategoryMap(categoryIds);
        Map<Long, SysUser> users = selectUserMap(publisherIds);
        Map<Long, Long> favoriteCounts = favoriteCounts(itemIds);
        Set<Long> myFavorites = currentUserId == null ? Collections.emptySet() : favoriteItemIds(currentUserId, itemIds);

        return items.stream().map(item -> {
            Category category = categories.get(item.getCategoryId());
            SysUser publisher = users.get(item.getPublisherId());
            ItemCardVO vo = new ItemCardVO();
            vo.setId(item.getId());
            vo.setPublisherId(item.getPublisherId());
            if (publisher != null) {
                vo.setPublisherNickname(publisher.getNickname());
                vo.setPublisherLevel(publisher.getLevel());
                vo.setPublisherLevelTitle(LevelRule.titleOf(publisher.getLevel()));
            }
            vo.setType(item.getType());
            vo.setTitle(item.getTitle());
            vo.setDescription(item.getDescription());
            vo.setCategoryId(item.getCategoryId());
            vo.setCategoryName(category == null ? null : category.getName());
            vo.setPrice(item.getPrice());
            List<String> images = parseJsonArray(item.getImages());
            vo.setImages(images);
            vo.setCoverImage(images.isEmpty() ? "" : images.get(0));
            vo.setAiTags(parseJsonArray(item.getAiTags()));
            vo.setTradeLocation(item.getTradeLocation());
            vo.setStatus(item.getStatus());
            vo.setViewCount(item.getViewCount());
            vo.setFavoriteCount(favoriteCounts.getOrDefault(item.getId(), 0L));
            vo.setFavoriteByCurrentUser(myFavorites.contains(item.getId()));
            vo.setCreatedAt(item.getCreatedAt());
            vo.setUpdatedAt(item.getUpdatedAt());
            return vo;
        }).toList();
    }

    private Map<Long, Category> selectCategoryMap(Set<Long> ids) {
        if (ids.isEmpty()) return Map.of();
        return categoryMapper.selectBatchIds(ids).stream()
                .collect(Collectors.toMap(Category::getId, Function.identity()));
    }

    private Map<Long, SysUser> selectUserMap(Set<Long> ids) {
        if (ids.isEmpty()) return Map.of();
        return userMapper.selectBatchIds(ids).stream()
                .collect(Collectors.toMap(SysUser::getId, Function.identity()));
    }

    private Map<Long, Long> favoriteCounts(Set<Long> itemIds) {
        if (itemIds.isEmpty()) return Map.of();
        List<Map<String, Object>> rows = favoriteMapper.selectMaps(new QueryWrapper<ItemFavorite>()
                .select("item_id", "COUNT(*) AS favorite_count")
                .in("item_id", itemIds)
                .groupBy("item_id"));
        Map<Long, Long> result = new HashMap<>();
        for (Map<String, Object> row : rows) {
            result.put(toLong(row.get("item_id")), toLong(row.get("favorite_count")));
        }
        return result;
    }

    private Long favoriteCount(Long itemId) {
        return favoriteMapper.selectCount(new LambdaQueryWrapper<ItemFavorite>()
                .eq(ItemFavorite::getItemId, itemId));
    }

    private Set<Long> favoriteItemIds(Long userId, Set<Long> itemIds) {
        if (itemIds.isEmpty()) return Set.of();
        return favoriteMapper.selectList(new LambdaQueryWrapper<ItemFavorite>()
                        .eq(ItemFavorite::getUserId, userId)
                        .in(ItemFavorite::getItemId, itemIds))
                .stream()
                .map(ItemFavorite::getItemId)
                .collect(Collectors.toSet());
    }

    private List<String> parseJsonArray(String raw) {
        if (!StringUtils.hasText(raw)) {
            return List.of();
        }
        try {
            List<String> values = objectMapper.readValue(raw, new TypeReference<>() {});
            return values == null ? List.of() : values;
        } catch (Exception ignored) {
            return List.of(raw);
        }
    }

    private Item requireOwnItem(Long userId, Long itemId) {
        Item item = itemMapper.selectById(itemId);
        if (item == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "商品不存在");
        }
        if (!Objects.equals(item.getPublisherId(), userId)) {
            throw new BusinessException(ResultCode.FORBIDDEN, "只能操作自己发布的商品");
        }
        return item;
    }

    private void updateStatus(Long itemId, String status) {
        Item item = new Item();
        item.setId(itemId);
        item.setStatus(status);
        itemMapper.updateById(item);
    }

    private int normalizeSize(int size) {
        return Math.max(1, Math.min(size, MAX_PAGE_SIZE));
    }

    private Long toLong(Object value) {
        if (value instanceof Number n) return n.longValue();
        if (value == null) return 0L;
        return Long.parseLong(String.valueOf(value));
    }
}
