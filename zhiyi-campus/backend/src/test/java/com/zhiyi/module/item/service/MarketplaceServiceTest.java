package com.zhiyi.module.item.service;

import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.conditions.AbstractWrapper;
import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.module.item.entity.Item;
import com.zhiyi.module.item.mapper.CategoryMapper;
import com.zhiyi.module.item.mapper.ItemMapper;
import com.zhiyi.module.social.mapper.ItemFavoriteMapper;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
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

    @BeforeAll
    static void initializeMyBatisMetadata() {
        MapperBuilderAssistant assistant = new MapperBuilderAssistant(new MybatisConfiguration(), "test");
        assistant.setCurrentNamespace("com.zhiyi.module.item.mapper.ItemMapper");
        TableInfoHelper.initTableInfo(assistant, Item.class);
    }

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

    @Test
    @SuppressWarnings({"rawtypes", "unchecked"})
    void filtersMarketplaceListToCurrentUsersSchool() {
        SysUser viewer = new SysUser();
        viewer.setId(7L);
        viewer.setRole("USER");
        viewer.setSchoolId(2L);
        when(userMapper.selectById(7L)).thenReturn(viewer);

        Page<Item> emptyPage = new Page<>(1, 12, 0);
        emptyPage.setRecords(List.of());
        when(itemMapper.selectPage(any(Page.class), any(Wrapper.class))).thenReturn(emptyPage);

        MarketplaceService service = new MarketplaceService(
                itemMapper, categoryMapper, favoriteMapper, userMapper, new ObjectMapper());
        service.listOnSaleItems(null, null, null, null,
                "latest", null, null, 1, 12, 7L);

        ArgumentCaptor<Wrapper<Item>> wrapperCaptor = ArgumentCaptor.forClass(Wrapper.class);
        verify(itemMapper).selectPage(any(Page.class), wrapperCaptor.capture());
        Wrapper<Item> wrapper = wrapperCaptor.getValue();
        assertTrue(wrapper.getSqlSegment().contains("school_id"));
        AbstractWrapper<Item, ?, ?> abstractWrapper = (AbstractWrapper<Item, ?, ?>) wrapper;
        assertTrue(abstractWrapper.getParamNameValuePairs().containsValue(2L));
    }
}
