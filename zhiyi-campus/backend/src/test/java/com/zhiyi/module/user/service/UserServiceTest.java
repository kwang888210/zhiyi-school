package com.zhiyi.module.user.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;

class UserServiceTest {

    @BeforeAll
    static void initializeMyBatisMetadata() {
        MapperBuilderAssistant assistant = new MapperBuilderAssistant(new MybatisConfiguration(), "test");
        assistant.setCurrentNamespace("com.zhiyi.module.user.mapper.SysUserMapper");
        TableInfoHelper.initTableInfo(assistant, SysUser.class);
    }

    @Test
    void publicProfileSerializesOnlyWhitelistedCardFields() {
        SysUser user = new SysUser();
        user.setId(42L);
        user.setStudentId("20260042");
        user.setNickname("测试同学");
        user.setPhone("13800138000");
        user.setRole("USER");
        user.setStatus("ACTIVE");
        user.setLevel(3);
        user.setExp(350);
        user.setWalletBalance(new BigDecimal("88.00"));

        SysUserMapper userMapper = (SysUserMapper) Proxy.newProxyInstance(
                SysUserMapper.class.getClassLoader(),
                new Class<?>[]{SysUserMapper.class},
                (proxy, method, args) -> {
                    if ("selectOne".equals(method.getName())) {
                        return user;
                    }
                    throw new UnsupportedOperationException(method.getName());
                });
        UserService service = new UserService(userMapper, null);

        JsonNode json = new ObjectMapper().valueToTree(service.getPublicProfile(42L));
        Set<String> fieldNames = new HashSet<>();
        Iterator<String> iterator = json.fieldNames();
        iterator.forEachRemaining(fieldNames::add);

        assertEquals(Set.of("id", "nickname", "level", "levelTitle"), fieldNames);
    }
}
