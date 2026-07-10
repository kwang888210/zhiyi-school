package com.zhiyi.module.user.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.user.dto.UpdateProfileDTO;
import com.zhiyi.module.user.entity.ExpLog;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.ExpLogMapper;
import com.zhiyi.module.user.mapper.SysUserMapper;
import com.zhiyi.module.user.support.LevelRule;
import com.zhiyi.module.user.vo.PublicUserCardVO;
import com.zhiyi.module.user.vo.UserVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 模块一：个人信息与经验值记录
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final SysUserMapper userMapper;
    private final ExpLogMapper expLogMapper;

    /** 当前用户信息 */
    public UserVO getProfile(Long userId) {
        SysUser user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        return UserVO.from(user);
    }

    /** 更新昵称/手机号 */
    public UserVO updateProfile(Long userId, UpdateProfileDTO dto) {
        SysUser patch = new SysUser();
        patch.setId(userId);
        if (dto.getNickname() != null && !dto.getNickname().isBlank()) {
            patch.setNickname(dto.getNickname().trim());
        }
        if (dto.getPhone() != null) {
            patch.setPhone(dto.getPhone());
        }
        userMapper.updateById(patch);
        return getProfile(userId);
    }

    /** 经验值变动记录（分页，倒序） */
    public IPage<ExpLog> getExpLogs(Long userId, int page, int size) {
        return expLogMapper.selectPage(new Page<>(page, Math.min(size, 50)),
                Wrappers.<ExpLog>lambdaQuery()
                        .eq(ExpLog::getUserId, userId)
                        .orderByDesc(ExpLog::getId));
    }

    /** 公开的用户名片（昵称+等级，商品详情/聊天头像旁展示用，供 B/C 模块调用） */
    public PublicUserCardVO getPublicProfile(Long userId) {
        SysUser user = userMapper.selectOne(Wrappers.<SysUser>lambdaQuery()
                .select(SysUser::getId, SysUser::getNickname, SysUser::getLevel)
                .eq(SysUser::getId, userId));
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        return new PublicUserCardVO(
                user.getId(), user.getNickname(), user.getLevel(), LevelRule.titleOf(user.getLevel()));
    }
}
