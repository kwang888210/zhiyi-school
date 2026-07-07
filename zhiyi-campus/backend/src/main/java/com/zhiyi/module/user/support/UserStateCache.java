package com.zhiyi.module.user.support;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;

/**
 * 用户鉴权状态本地缓存（Caffeine）
 *
 * 高并发设计：
 * - 每个已登录请求都需要校验「是否被封禁 / Token 是否被强制失效」，
 *   若直查 DB，10000 并发下 sys_user 表将成为热点。
 * - 这里用 Caffeine 缓存状态快照（默认 60s TTL），DB 压力降为 ~1次/用户/分钟；
 * - 封禁 / 解封 / 重置密码等写操作后主动 invalidate，本机立即生效。
 * - 集群部署时可将本缓存替换为 Redis（接口不变）。
 */
@Component
public class UserStateCache {

    private final SysUserMapper userMapper;
    private final LoadingCache<Long, Optional<UserAuthState>> cache;

    public UserStateCache(SysUserMapper userMapper,
                          @Value("${zhiyi.auth.user-state-cache-seconds:60}") long ttlSeconds) {
        this.userMapper = userMapper;
        this.cache = Caffeine.newBuilder()
                .maximumSize(100_000)
                .expireAfterWrite(Duration.ofSeconds(ttlSeconds))
                .build(this::loadFromDb);
    }

    private Optional<UserAuthState> loadFromDb(Long userId) {
        SysUser u = userMapper.selectOne(Wrappers.<SysUser>lambdaQuery()
                .select(SysUser::getId, SysUser::getRole, SysUser::getStatus,
                        SysUser::getBanUntilTime, SysUser::getTokenInvalidBefore)
                .eq(SysUser::getId, userId));
        if (u == null) {
            return Optional.empty();
        }
        return Optional.of(new UserAuthState(
                u.getId(), u.getRole(), u.getStatus(), u.getBanUntilTime(), u.getTokenInvalidBefore()));
    }

    /** 获取用户状态快照；用户不存在返回 null */
    public UserAuthState get(Long userId) {
        return cache.get(userId).orElse(null);
    }

    /** 状态变更（封禁/解封/改密）后调用，保证本机立即生效 */
    public void invalidate(Long userId) {
        cache.invalidate(userId);
    }
}
