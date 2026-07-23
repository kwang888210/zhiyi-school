package com.zhiyi.module.item.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.module.item.mapper.CategoryMapper;
import com.zhiyi.module.item.mapper.ItemMapper;
import com.zhiyi.module.social.mapper.ItemFavoriteMapper;
import com.zhiyi.module.user.mapper.SysUserMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MarketplaceServiceTest {

    @Mock
    private ItemMapper itemMapper;
    @Mock
    private CategoryMapper categoryMapper;
    @Mock
    private ItemFavoriteMapper favoriteMapper;
    @Mock
    private SysUserMapper userMapper;

    @Test
    void ranksAiTagsByDistinctOnSaleItemFrequency() {
        when(itemMapper.selectObjs(any())).thenReturn(List.of(
                "[\"iPad\",\"student\",\"iPad\"]",
                "[\"iPad\",\"student\"]",
                "[\"iPad\",\"tablet\"]"
        ));
        MarketplaceService service = new MarketplaceService(
                itemMapper, categoryMapper, favoriteMapper, userMapper, new ObjectMapper());

        var result = service.trendingAiTags(10);

        assertEquals(List.of("iPad", "student", "tablet"),
                result.stream().map(tag -> tag.tag()).toList());
        assertEquals(List.of(3L, 2L, 1L),
                result.stream().map(tag -> tag.count()).toList());
    }
}
