package com.zhiyi.module.admin.service;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.admin.dto.SchoolDTO;
import com.zhiyi.module.user.entity.School;
import com.zhiyi.module.user.mapper.SchoolMapper;
import com.zhiyi.module.user.vo.SchoolVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 超管学校管理服务 —— D1
 *
 * GET    /api/admin/schools     列表（含停用）
 * POST   /api/admin/schools     新增
 * PUT    /api/admin/schools/{id} 编辑
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminSchoolService {

    private final SchoolMapper schoolMapper;

    /** 全部学校列表（含停用），供管理员管理 */
    public List<SchoolVO> listAll() {
        return schoolMapper.selectList(Wrappers.<School>lambdaQuery()
                        .orderByAsc(School::getId))
                .stream()
                .map(SchoolVO::from)
                .toList();
    }

    /** 新增学校 */
    @Transactional(rollbackFor = Exception.class)
    public SchoolVO create(SchoolDTO dto) {
        // code 唯一性校验
        School existing = schoolMapper.selectOne(Wrappers.<School>lambdaQuery()
                .eq(School::getCode, dto.getCode()));
        if (existing != null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "学校代码 " + dto.getCode() + " 已存在");
        }

        School school = new School();
        school.setName(dto.getName());
        school.setCode(dto.getCode().toUpperCase());
        school.setEmailDomain(dto.getEmailDomain());
        school.setStatus(dto.getStatus() != null ? dto.getStatus() : "ACTIVE");
        schoolMapper.insert(school);

        log.info("管理员新增学校：{} ({})", school.getName(), school.getCode());
        return SchoolVO.from(school);
    }

    /** 编辑学校 */
    @Transactional(rollbackFor = Exception.class)
    public SchoolVO update(Long id, SchoolDTO dto) {
        School school = schoolMapper.selectById(id);
        if (school == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "学校不存在");
        }

        // code 唯一性校验（排除自身）
        School dup = schoolMapper.selectOne(Wrappers.<School>lambdaQuery()
                .eq(School::getCode, dto.getCode())
                .ne(School::getId, id));
        if (dup != null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "学校代码 " + dto.getCode() + " 已被其他学校使用");
        }

        school.setName(dto.getName());
        school.setCode(dto.getCode().toUpperCase());
        school.setEmailDomain(dto.getEmailDomain());
        if (dto.getStatus() != null) {
            school.setStatus(dto.getStatus());
        }
        schoolMapper.updateById(school);

        log.info("管理员编辑学校：{} ({})", school.getName(), school.getCode());
        return SchoolVO.from(school);
    }

    /** 删除学校 */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        School school = schoolMapper.selectById(id);
        if (school == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "学校不存在");
        }
        schoolMapper.deleteById(id);
        log.info("管理员删除学校：{} ({})", school.getName(), school.getCode());
    }
}
