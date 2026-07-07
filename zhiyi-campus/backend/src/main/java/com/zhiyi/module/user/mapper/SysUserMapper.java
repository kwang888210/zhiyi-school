package com.zhiyi.module.user.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhiyi.module.user.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface SysUserMapper extends BaseMapper<SysUser> {
    // MyBatis-Plus 自动提供 insert / delete / update / selectById / selectList 等
    // 复杂查询（如联合查询）可在此添加方法，并在 mapper/SysUserMapper.xml 中写 SQL
}
